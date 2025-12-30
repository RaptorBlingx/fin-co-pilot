import 'package:cloud_firestore/cloud_firestore.dart';
import 'coaching_tips_seed_data.dart';

/// Service to seed the Firestore coaching_tips collection with 100+ pre-written tips
///
/// Usage:
/// ```dart
/// final seeder = CoachingTipsSeedingService();
/// await seeder.seedCoachingTips();
/// ```
///
/// This should be called once during app initialization or from an admin panel.
/// Tips are organized by:
/// - Budgeting (20 tips)
/// - Impulse Control (20 tips)
/// - Savings (20 tips)
/// - Debt Management (20 tips)
/// - Stress/Emotional Spending (20 tips)
class CoachingTipsSeedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed all coaching tips into Firestore
  ///
  /// Returns the number of tips successfully seeded
  Future<int> seedCoachingTips({bool clearExisting = false}) async {
    print('🌱 CoachingTipsSeedingService: Starting seeding process...');

    try {
      // Optionally clear existing tips
      if (clearExisting) {
        print('🌱 Clearing existing coaching tips...');
        await _clearExistingTips();
      }

      // Get all tips from seed data
      final allTips = CoachingTipsSeedData.getAllTips();
      print('🌱 Found ${allTips.length} tips to seed');

      // Seed in batches of 500 (Firestore batch limit)
      int successCount = 0;
      const batchSize = 500;

      for (var i = 0; i < allTips.length; i += batchSize) {
        final batch = _firestore.batch();
        final endIndex = (i + batchSize < allTips.length) ? i + batchSize : allTips.length;
        final batchTips = allTips.sublist(i, endIndex);

        print('🌱 Processing batch ${(i / batchSize).floor() + 1}: tips $i to ${endIndex - 1}');

        for (final tipData in batchTips) {
          // Create document with auto-generated ID
          final docRef = _firestore.collection('coaching_tips').doc();

          // Prepare tip data with metadata
          final data = {
            ...tipData,
            'usageCount': 0,
            'effectiveness': null,
            'createdAt': FieldValue.serverTimestamp(),
          };

          batch.set(docRef, data);
          successCount++;
        }

        // Commit batch
        await batch.commit();
        print('🌱 Batch committed successfully');
      }

      print('🌱 ✅ Seeding complete! ${successCount} tips added to Firestore');
      return successCount;
    } catch (e) {
      print('🌱 ❌ Error seeding coaching tips: $e');
      rethrow;
    }
  }

  /// Clear all existing coaching tips from Firestore
  Future<void> _clearExistingTips() async {
    try {
      final snapshot = await _firestore.collection('coaching_tips').get();
      print('🌱 Found ${snapshot.docs.length} existing tips to clear');

      if (snapshot.docs.isEmpty) {
        print('🌱 No existing tips to clear');
        return;
      }

      // Delete in batches
      const batchSize = 500;
      for (var i = 0; i < snapshot.docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final endIndex = (i + batchSize < snapshot.docs.length)
            ? i + batchSize
            : snapshot.docs.length;
        final batchDocs = snapshot.docs.sublist(i, endIndex);

        for (final doc in batchDocs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      print('🌱 ✅ Cleared all existing tips');
    } catch (e) {
      print('🌱 ❌ Error clearing existing tips: $e');
      rethrow;
    }
  }

  /// Seed only tips for a specific category
  Future<int> seedTipsForCategory(String category) async {
    print('🌱 Seeding tips for category: $category');

    try {
      final allTips = CoachingTipsSeedData.getAllTips();
      final categoryTips = allTips.where((tip) => tip['category'] == category).toList();

      print('🌱 Found ${categoryTips.length} tips for category: $category');

      final batch = _firestore.batch();
      for (final tipData in categoryTips) {
        final docRef = _firestore.collection('coaching_tips').doc();
        final data = {
          ...tipData,
          'usageCount': 0,
          'effectiveness': null,
          'createdAt': FieldValue.serverTimestamp(),
        };
        batch.set(docRef, data);
      }

      await batch.commit();
      print('🌱 ✅ Seeded ${categoryTips.length} tips for category: $category');
      return categoryTips.length;
    } catch (e) {
      print('🌱 ❌ Error seeding category tips: $e');
      rethrow;
    }
  }

  /// Check if coaching tips have been seeded
  Future<bool> areTipsSeeded() async {
    try {
      final snapshot = await _firestore
          .collection('coaching_tips')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('🌱 Error checking if tips are seeded: $e');
      return false;
    }
  }

  /// Get count of seeded tips
  Future<int> getTipsCount() async {
    try {
      final snapshot = await _firestore.collection('coaching_tips').get();
      return snapshot.docs.length;
    } catch (e) {
      print('🌱 Error getting tips count: $e');
      return 0;
    }
  }

  /// Get breakdown of tips by category
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
      print('🌱 Error getting category breakdown: $e');
      return {};
    }
  }

  /// Re-seed tips if count is below expected (data integrity check)
  Future<void> ensureTipsSeeded({int expectedCount = 100}) async {
    try {
      final currentCount = await getTipsCount();
      print('🌱 Current tips count: $currentCount (expected: $expectedCount)');

      if (currentCount < expectedCount) {
        print('🌱 Tips count below expected. Re-seeding...');
        await seedCoachingTips(clearExisting: true);
      } else {
        print('🌱 ✅ Tips already seeded (count: $currentCount)');
      }
    } catch (e) {
      print('🌱 ❌ Error ensuring tips seeded: $e');
      rethrow;
    }
  }
}
