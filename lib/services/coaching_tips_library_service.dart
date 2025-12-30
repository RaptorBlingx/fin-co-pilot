import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coaching_tip.dart';

/// Service for managing the coaching tips library (Week 9 Feature)
///
/// Provides:
/// - Browse 100+ pre-written tips by category/trigger
/// - Context-aware tip selection based on user behavior
/// - Bookmark tips for later reference
/// - Rate tip effectiveness (0-5 stars)
/// - Track usage statistics
class CoachingTipsLibraryService {
  static final CoachingTipsLibraryService _instance = CoachingTipsLibraryService._internal();
  factory CoachingTipsLibraryService() => _instance;
  CoachingTipsLibraryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =================================================================
  // BROWSING & RETRIEVAL
  // =================================================================

  /// Get all coaching tips from the library
  Stream<List<CoachingTip>> getAllTips() {
    return _firestore
        .collection('coaching_tips')
        .orderBy('category')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoachingTip.fromFirestore(doc))
            .toList());
  }

  /// Get tips by category
  Stream<List<CoachingTip>> getTipsByCategory(String category) {
    return _firestore
        .collection('coaching_tips')
        .where('category', isEqualTo: category)
        .orderBy('usageCount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoachingTip.fromFirestore(doc))
            .toList());
  }

  /// Get tips by trigger
  Stream<List<CoachingTip>> getTipsByTrigger(String trigger) {
    return _firestore
        .collection('coaching_tips')
        .where('trigger', isEqualTo: trigger)
        .orderBy('effectiveness', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoachingTip.fromFirestore(doc))
            .toList());
  }

  /// Get user's bookmarked tips
  Stream<List<CoachingTip>> getBookmarkedTips(String userId) {
    return _firestore
        .collection('user_coaching_tips')
        .doc(userId)
        .collection('bookmarks')
        .orderBy('bookmarkedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final tipIds = snapshot.docs.map((doc) => doc.id).toList();
          if (tipIds.isEmpty) return <CoachingTip>[];

          final tips = <CoachingTip>[];
          for (final tipId in tipIds) {
            final tipDoc = await _firestore.collection('coaching_tips').doc(tipId).get();
            if (tipDoc.exists) {
              tips.add(CoachingTip.fromFirestore(tipDoc));
            }
          }
          return tips;
        });
  }

  /// Get highly-rated tips (effectiveness >= 4.0)
  Stream<List<CoachingTip>> getHighlyRatedTips() {
    return _firestore
        .collection('coaching_tips')
        .where('effectiveness', isGreaterThanOrEqualTo: 4.0)
        .orderBy('effectiveness', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoachingTip.fromFirestore(doc))
            .toList());
  }

  /// Get popular tips (high usage count)
  Stream<List<CoachingTip>> getPopularTips({int limit = 20}) {
    return _firestore
        .collection('coaching_tips')
        .orderBy('usageCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoachingTip.fromFirestore(doc))
            .toList());
  }

  // =================================================================
  // CONTEXT-AWARE SELECTION
  // =================================================================

  /// Get context-aware tip for user based on spending patterns
  Future<CoachingTip?> getContextualTip({
    required String userId,
    String? category,
    String? trigger,
  }) async {
    try {
      // Build query based on context
      Query query = _firestore.collection('coaching_tips');

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      if (trigger != null) {
        query = query.where('trigger', isEqualTo: trigger);
      }

      // Prefer highly-rated tips
      query = query
          .orderBy('effectiveness', descending: true)
          .limit(5);

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return null;

      // Get tips that user hasn't seen recently
      final recentlySeenIds = await _getRecentlySeenTipIds(userId);
      final unseenTips = snapshot.docs
          .where((doc) => !recentlySeenIds.contains(doc.id))
          .toList();

      if (unseenTips.isEmpty) {
        // All tips seen recently, return the highest-rated
        return CoachingTip.fromFirestore(snapshot.docs.first);
      }

      // Return first unseen tip
      final tip = CoachingTip.fromFirestore(unseenTips.first);

      // Track that user saw this tip
      await _markTipAsSeen(userId, tip.id);
      await _incrementUsageCount(tip.id);

      return tip;
    } catch (e) {
      print('Error getting contextual tip: $e');
      return null;
    }
  }

  /// Get random tip from category (for daily coaching)
  Future<CoachingTip?> getRandomTipFromCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('coaching_tips')
          .where('category', isEqualTo: category)
          .get();

      if (snapshot.docs.isEmpty) return null;

      // Simple random selection (for better randomness, use shuffle in code)
      final randomIndex = DateTime.now().millisecond % snapshot.docs.length;
      return CoachingTip.fromFirestore(snapshot.docs[randomIndex]);
    } catch (e) {
      print('Error getting random tip: $e');
      return null;
    }
  }

  // =================================================================
  // BOOKMARKING
  // =================================================================

  /// Bookmark a tip for later reference
  Future<void> bookmarkTip(String userId, String tipId) async {
    try {
      await _firestore
          .collection('user_coaching_tips')
          .doc(userId)
          .collection('bookmarks')
          .doc(tipId)
          .set({
        'bookmarkedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Tip bookmarked: $tipId');
    } catch (e) {
      print('Error bookmarking tip: $e');
      rethrow;
    }
  }

  /// Remove bookmark from a tip
  Future<void> unbookmarkTip(String userId, String tipId) async {
    try {
      await _firestore
          .collection('user_coaching_tips')
          .doc(userId)
          .collection('bookmarks')
          .doc(tipId)
          .delete();
      print('✅ Tip unbookmarked: $tipId');
    } catch (e) {
      print('Error unbookmarking tip: $e');
      rethrow;
    }
  }

  /// Check if a tip is bookmarked
  Future<bool> isTipBookmarked(String userId, String tipId) async {
    try {
      final doc = await _firestore
          .collection('user_coaching_tips')
          .doc(userId)
          .collection('bookmarks')
          .doc(tipId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking bookmark status: $e');
      return false;
    }
  }

  /// Get bookmark status stream for a tip
  Stream<bool> isBookmarkedStream(String userId, String tipId) {
    return _firestore
        .collection('user_coaching_tips')
        .doc(userId)
        .collection('bookmarks')
        .doc(tipId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // =================================================================
  // RATING & EFFECTIVENESS
  // =================================================================

  /// Rate a tip's effectiveness (0-5 stars)
  Future<void> rateTip(String userId, String tipId, double rating) async {
    assert(rating >= 0 && rating <= 5, 'Rating must be between 0 and 5');

    try {
      // Store user's rating
      await _firestore
          .collection('user_coaching_tips')
          .doc(userId)
          .collection('ratings')
          .doc(tipId)
          .set({
        'rating': rating,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      // Update tip's overall effectiveness (average rating)
      await _updateTipEffectiveness(tipId);

      print('✅ Tip rated: $tipId with $rating stars');
    } catch (e) {
      print('Error rating tip: $e');
      rethrow;
    }
  }

  /// Get user's rating for a tip
  Future<double?> getUserRating(String userId, String tipId) async {
    try {
      final doc = await _firestore
          .collection('user_coaching_tips')
          .doc(userId)
          .collection('ratings')
          .doc(tipId)
          .get();

      if (!doc.exists) return null;
      return (doc.data()?['rating'] as num?)?.toDouble();
    } catch (e) {
      print('Error getting user rating: $e');
      return null;
    }
  }

  /// Update tip's overall effectiveness based on all user ratings
  Future<void> _updateTipEffectiveness(String tipId) async {
    try {
      // Get all ratings for this tip
      final ratingsSnapshot = await _firestore
          .collectionGroup('ratings')
          .where(FieldPath.documentId, isEqualTo: tipId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      // Calculate average rating
      double totalRating = 0;
      for (final doc in ratingsSnapshot.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }
      final averageRating = totalRating / ratingsSnapshot.docs.length;

      // Update tip's effectiveness
      await _firestore.collection('coaching_tips').doc(tipId).update({
        'effectiveness': averageRating,
      });
    } catch (e) {
      print('Error updating tip effectiveness: $e');
    }
  }

  // =================================================================
  // USAGE TRACKING
  // =================================================================

  /// Increment usage count when a tip is shown
  Future<void> _incrementUsageCount(String tipId) async {
    try {
      await _firestore.collection('coaching_tips').doc(tipId).update({
        'usageCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing usage count: $e');
    }
  }

  /// Mark tip as seen by user
  Future<void> _markTipAsSeen(String userId, String tipId) async {
    try {
      await _firestore
          .collection('user_coaching_tips')
          .doc(userId)
          .collection('seen')
          .doc(tipId)
          .set({
        'seenAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking tip as seen: $e');
    }
  }

  /// Get recently seen tip IDs (last 7 days)
  Future<List<String>> _getRecentlySeenTipIds(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection('user_coaching_tips')
          .doc(userId)
          .collection('seen')
          .where('seenAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting recently seen tips: $e');
      return [];
    }
  }

  // =================================================================
  // STATISTICS
  // =================================================================

  /// Get tips breakdown by category
  Future<Map<String, int>> getTipsCategoryBreakdown() async {
    try {
      final snapshot = await _firestore.collection('coaching_tips').get();
      final breakdown = <String, int>{};

      for (final doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null) {
          breakdown[category] = (breakdown[category] ?? 0) + 1;
        }
      }

      return breakdown;
    } catch (e) {
      print('Error getting category breakdown: $e');
      return {};
    }
  }

  /// Get total tips count
  Future<int> getTotalTipsCount() async {
    try {
      final snapshot = await _firestore.collection('coaching_tips').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting total tips count: $e');
      return 0;
    }
  }

  /// Get user's engagement stats
  Future<Map<String, dynamic>> getUserEngagementStats(String userId) async {
    try {
      final bookmarksSnapshot = await _firestore
          .collection('user_coaching_tips')
          .doc(userId)
          .collection('bookmarks')
          .get();

      final ratingsSnapshot = await _firestore
          .collection('user_coaching_tips')
          .doc(userId)
          .collection('ratings')
          .get();

      final seenSnapshot = await _firestore
          .collection('user_coaching_tips')
          .doc(userId)
          .collection('seen')
          .get();

      return {
        'bookmarkedCount': bookmarksSnapshot.docs.length,
        'ratedCount': ratingsSnapshot.docs.length,
        'seenCount': seenSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting user engagement stats: $e');
      return {
        'bookmarkedCount': 0,
        'ratedCount': 0,
        'seenCount': 0,
      };
    }
  }
}
