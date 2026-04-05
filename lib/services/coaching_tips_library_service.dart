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
        .collection('coaching_tips_library')
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
        .collection('coaching_tips_library')
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
        .collection('coaching_tips_library')
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
            final tipDoc = await _firestore.collection('coaching_tips_library').doc(tipId).get();
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
        .collection('coaching_tips_library')
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
        .collection('coaching_tips_library')
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
      Query query = _firestore.collection('coaching_tips_library');

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
          .collection('coaching_tips_library')
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
      await _firestore.collection('coaching_tips_library').doc(tipId).update({
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
      await _firestore.collection('coaching_tips_library').doc(tipId).update({
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
      final snapshot = await _firestore.collection('coaching_tips_library').get();
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
      final snapshot = await _firestore.collection('coaching_tips_library').get();
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

  // =================================================================
  // SEED DEFAULT TIPS (one-time, if collection is empty)
  // =================================================================

  /// Seeds the coaching_tips_library collection with curated tips if empty.
  Future<void> seedIfEmpty() async {
    try {
      final snapshot = await _firestore
          .collection('coaching_tips_library')
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) return; // Already seeded

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final tip in _defaultTips) {
        final docRef = _firestore.collection('coaching_tips_library').doc();
        batch.set(docRef, {
          ...tip,
          'effectiveness': null,
          'usageCount': 0,
          'createdAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();
      print('Coaching tips library seeded with ${_defaultTips.length} tips.');
    } catch (e) {
      print('Error seeding tips library: $e');
    }
  }

  static final List<Map<String, dynamic>> _defaultTips = [
    // ── Budgeting ────────────────────────────────────────────
    {
      'category': 'budgeting',
      'trigger': 'over_budget',
      'tip': 'Try the 50/30/20 rule: 50% needs, 30% wants, 20% savings. It simplifies budgeting without feeling restrictive.',
      'longForm': 'The 50/30/20 rule is one of the most popular budgeting frameworks because it\'s simple and flexible. Allocate 50% of your after-tax income to needs (rent, groceries, utilities), 30% to wants (dining out, entertainment, hobbies), and 20% to savings and debt repayment. Start by tracking where your money goes for one month, then gradually adjust your spending to fit these ratios.',
      'tags': ['budgeting', 'framework', 'beginner'],
    },
    {
      'category': 'budgeting',
      'trigger': 'over_budget',
      'tip': 'When you overshoot a budget category, don\'t panic. Shift funds from a flexible category rather than abandoning the budget entirely.',
      'longForm': 'Budget overruns are normal — they don\'t mean you\'ve failed. The key is to treat your budget as a living document. If you overspend on groceries, reduce your entertainment budget for the rest of the month. This "roll with the punches" approach keeps you in control without the guilt spiral that makes people quit budgeting altogether.',
      'tags': ['budgeting', 'recovery', 'mindset'],
    },
    {
      'category': 'budgeting',
      'trigger': 'new_budget',
      'tip': 'Set budget limits 10% below what you actually spend today. Small, realistic cuts stick better than drastic ones.',
      'tags': ['budgeting', 'beginner', 'strategy'],
    },
    {
      'category': 'budgeting',
      'trigger': 'consistent_tracking',
      'tip': 'Review your budget every Sunday for 5 minutes. A weekly check-in prevents month-end surprises.',
      'tags': ['budgeting', 'habit', 'review'],
    },
    {
      'category': 'budgeting',
      'trigger': 'over_budget',
      'tip': 'Automate your savings first, then budget what\'s left. You can\'t spend what you\'ve already moved.',
      'longForm': 'Pay-yourself-first is the most effective savings strategy. Set up an automatic transfer to your savings account on payday — even if it\'s just 5%. Your brain adapts to the lower available balance within a month, and your savings grow on autopilot. Increase the percentage by 1% every quarter and you won\'t even notice.',
      'tags': ['budgeting', 'savings', 'automation'],
    },
    // ── Saving ───────────────────────────────────────────────
    {
      'category': 'savings',
      'trigger': 'low_savings',
      'tip': 'Start an emergency fund with just \$500. That covers most unexpected car or medical bills and breaks the debt cycle.',
      'longForm': 'A full 3-6 month emergency fund sounds overwhelming, but \$500 covers 80% of real emergencies (car repair, urgent dental, appliance failure). Start there. Once you hit \$500, aim for \$1,000. Then build up to one month of expenses. Each milestone is a win that builds momentum.',
      'tags': ['savings', 'emergency fund', 'beginner'],
    },
    {
      'category': 'savings',
      'trigger': 'consistent_saving',
      'tip': 'Keep your emergency fund in a high-yield savings account — it earns 4-5% while staying accessible.',
      'tags': ['savings', 'optimization', 'interest'],
    },
    {
      'category': 'savings',
      'trigger': 'windfall',
      'tip': 'Got unexpected money? Use the 50/50 rule: save half, enjoy half. You deserve a reward AND financial security.',
      'tags': ['savings', 'windfall', 'balance'],
    },
    {
      'category': 'savings',
      'trigger': 'low_savings',
      'tip': 'Round up every purchase to the nearest dollar and save the difference. It adds up to \$30-50/month without effort.',
      'tags': ['savings', 'micro-saving', 'automation'],
    },
    {
      'category': 'savings',
      'trigger': 'goal_setting',
      'tip': 'Give every savings goal a name and a deadline. "Bali Trip — Dec 2026" is more motivating than "Savings Account #2".',
      'tags': ['savings', 'goals', 'motivation'],
    },
    // ── Spending ─────────────────────────────────────────────
    {
      'category': 'spending',
      'trigger': 'high_spending',
      'tip': 'Wait 24 hours before any purchase over \$50. If you still want it tomorrow, it\'s probably worth it.',
      'longForm': 'The 24-hour rule is a simple but powerful tool against impulse buying. When you see something you want, add it to a wish list and walk away. Most impulse urges fade within a day. If you still want it after 24 hours, buy it guilt-free — it\'s a considered purchase, not an impulse. For purchases over \$200, extend the wait to a week.',
      'tags': ['spending', 'impulse', 'discipline'],
    },
    {
      'category': 'spending',
      'trigger': 'impulse_spending',
      'tip': 'Unsubscribe from marketing emails and remove saved credit cards from online stores. Make impulse buying harder.',
      'tags': ['spending', 'impulse', 'prevention'],
    },
    {
      'category': 'spending',
      'trigger': 'subscription_creep',
      'tip': 'Audit your subscriptions quarterly. The average person has 12 subscriptions and forgets about 3 of them.',
      'longForm': 'Subscription creep is real — free trials convert, prices increase, and unused services linger. Set a calendar reminder every 3 months to review all recurring charges. Cancel anything you haven\'t used in the past 30 days. Most services let you re-subscribe easily if you actually miss them.',
      'tags': ['spending', 'subscriptions', 'audit'],
    },
    {
      'category': 'spending',
      'trigger': 'dining_out',
      'tip': 'Eating out costs 3-5x more than cooking. Try meal prepping Sundays — it saves money AND weeknight stress.',
      'tags': ['spending', 'food', 'meal prep'],
    },
    {
      'category': 'spending',
      'trigger': 'high_spending',
      'tip': 'Track your cost-per-use for big purchases. A \$200 jacket worn 100 times costs \$2/wear — that\'s a great deal.',
      'tags': ['spending', 'value', 'perspective'],
    },
    // ── Debt ─────────────────────────────────────────────────
    {
      'category': 'debt',
      'trigger': 'has_debt',
      'tip': 'Pay minimum on everything, then throw all extra money at your smallest debt. The snowball method builds momentum.',
      'longForm': 'The debt snowball method (pay off smallest balances first) works because of psychology, not math. Each paid-off debt gives you a dopamine hit and frees up a minimum payment to roll into the next debt. The avalanche method (highest interest first) saves more in interest, but the snowball method has higher completion rates. Choose whichever keeps you motivated.',
      'tags': ['debt', 'snowball', 'strategy'],
    },
    {
      'category': 'debt',
      'trigger': 'high_interest',
      'tip': 'Call your credit card company and ask for a lower rate. It works 70% of the time and takes 5 minutes.',
      'tags': ['debt', 'credit card', 'negotiation'],
    },
    {
      'category': 'debt',
      'trigger': 'has_debt',
      'tip': 'Never pay just the minimum on credit cards. Even \$20 extra per month can save you years of payments and hundreds in interest.',
      'tags': ['debt', 'credit card', 'minimum payment'],
    },
    {
      'category': 'debt',
      'trigger': 'debt_free',
      'tip': 'Just paid off a debt? Redirect that payment into savings instead of spending more. Your lifestyle doesn\'t need to inflate.',
      'tags': ['debt', 'lifestyle inflation', 'savings'],
    },
    // ── Emotional / Stress ───────────────────────────────────
    {
      'category': 'stress',
      'trigger': 'high_stress',
      'tip': 'Feeling anxious about money? Write down your 3 biggest financial worries. Naming them makes them manageable.',
      'longForm': 'Financial anxiety lives in vagueness — "I\'m bad with money" is overwhelming, but "I\'m \$200 over budget on food this month" is solvable. Write down your top 3 money worries, then rate each from 1-10 on urgency. Tackle the highest one first with one small action today. Progress dissolves anxiety.',
      'tags': ['stress', 'anxiety', 'mindset'],
    },
    {
      'category': 'stress',
      'trigger': 'impulse_spending',
      'tip': 'Stress-shopping? Try a 10-minute walk instead. The urge usually passes, and you get endorphins for free.',
      'tags': ['stress', 'impulse', 'coping'],
    },
    {
      'category': 'stress',
      'trigger': 'comparison',
      'tip': 'Stop comparing your chapter 1 to someone else\'s chapter 20. Everyone\'s financial journey starts somewhere different.',
      'tags': ['stress', 'comparison', 'mindset'],
    },
    {
      'category': 'stress',
      'trigger': 'financial_setback',
      'tip': 'Had a financial setback? It\'s a detour, not a dead end. Reassess, adjust your plan, and keep moving forward.',
      'tags': ['stress', 'setback', 'resilience'],
    },
    // ── Smart Shopping ───────────────────────────────────────
    {
      'category': 'shopping',
      'trigger': 'grocery_shopping',
      'tip': 'Always shop with a list. Grocery shoppers without a list spend 40% more on average.',
      'tags': ['shopping', 'groceries', 'planning'],
    },
    {
      'category': 'shopping',
      'trigger': 'price_comparison',
      'tip': 'Compare unit prices, not package prices. The bigger package isn\'t always the better deal.',
      'tags': ['shopping', 'comparison', 'unit price'],
    },
    {
      'category': 'shopping',
      'trigger': 'sale_alert',
      'tip': 'A sale isn\'t savings if you wouldn\'t have bought it at full price. Discounts on things you don\'t need cost you money.',
      'tags': ['shopping', 'sales', 'mindset'],
    },
    {
      'category': 'shopping',
      'trigger': 'online_shopping',
      'tip': 'Use browser extensions like Honey or RetailMeNot to auto-apply coupon codes. Free money in seconds.',
      'tags': ['shopping', 'coupons', 'online'],
    },
    // ── Income & Growth ──────────────────────────────────────
    {
      'category': 'income',
      'trigger': 'salary_received',
      'tip': 'Negotiate your salary at every new job. Even \$5K more compounds to \$500K+ over your career.',
      'longForm': 'Salary negotiation is the highest-ROI financial skill you can learn. Research shows that people who negotiate their starting salary earn \$1M+ more over a 45-year career compared to those who don\'t. Use sites like Glassdoor, Levels.fyi, and Payscale to research market rates. Practice your pitch with a friend. The worst they can say is no.',
      'tags': ['income', 'negotiation', 'career'],
    },
    {
      'category': 'income',
      'trigger': 'side_income',
      'tip': 'Even \$200/month in side income can fund your emergency fund in 3 months or pay off a credit card in a year.',
      'tags': ['income', 'side hustle', 'motivation'],
    },
    {
      'category': 'income',
      'trigger': 'raise_received',
      'tip': 'Got a raise? Save at least half of the increase before your lifestyle adjusts. Future you will be grateful.',
      'tags': ['income', 'raise', 'lifestyle inflation'],
    },
    // ── Investing Basics ─────────────────────────────────────
    {
      'category': 'investing',
      'trigger': 'ready_to_invest',
      'tip': 'Start investing with index funds. They outperform 90% of actively managed funds over 20 years — and they\'re cheaper.',
      'longForm': 'Index funds track a market index (like S&P 500) and give you instant diversification across hundreds of companies. They have low fees (0.03-0.20% vs 1-2% for active funds), require zero stock-picking skill, and historically return ~10% annually over the long term. Warren Buffett recommends them for most investors. Start with a total market index fund.',
      'tags': ['investing', 'index funds', 'beginner'],
    },
    {
      'category': 'investing',
      'trigger': 'market_dip',
      'tip': 'Market dropped? Don\'t panic-sell. Time in the market beats timing the market — every single time historically.',
      'tags': ['investing', 'market', 'patience'],
    },
    {
      'category': 'investing',
      'trigger': 'retirement',
      'tip': 'If your employer matches 401(k) contributions, contribute at least enough to get the full match. It\'s a 100% return on your money.',
      'tags': ['investing', 'retirement', '401k'],
    },
    {
      'category': 'investing',
      'trigger': 'compound_interest',
      'tip': 'Investing \$200/month starting at age 25 gives you \$600K+ by 65. Starting at 35 gives you \$250K. Time is your biggest asset.',
      'tags': ['investing', 'compound interest', 'time'],
    },
    // ── Habits & Mindset ─────────────────────────────────────
    {
      'category': 'habits',
      'trigger': 'consistent_tracking',
      'tip': 'You\'re building a great tracking habit! Consistency is the #1 predictor of financial success — keep going.',
      'tags': ['habits', 'encouragement', 'tracking'],
    },
    {
      'category': 'habits',
      'trigger': 'first_week',
      'tip': 'Financial fitness is like physical fitness — small daily actions beat occasional big efforts. Log every transaction.',
      'tags': ['habits', 'consistency', 'beginner'],
    },
    {
      'category': 'habits',
      'trigger': 'milestone',
      'tip': 'Celebrate financial milestones! Paid off a card? Hit a savings goal? Reward yourself with something small — you earned it.',
      'tags': ['habits', 'celebration', 'motivation'],
    },
    {
      'category': 'habits',
      'trigger': 'net_worth',
      'tip': 'Track your net worth monthly. Watching it grow — even slowly — is the most motivating financial habit you can build.',
      'tags': ['habits', 'net worth', 'tracking'],
    },
  ];
}
