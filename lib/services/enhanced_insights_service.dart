// =============================================================================
// TIER 2 FEATURE - DISABLED FOR V1.0 LAUNCH
// =============================================================================
// This service is part of V2.0 Enhanced Insights features.
// Feature Flag: FeaturesConfig.enableEnhancedInsights = false
// 
// To re-enable for V2.0:
// 1. Set FeaturesConfig.enableEnhancedInsights = true in features_config.dart
// 2. Uncomment the code below
// 3. Test thoroughly
// =============================================================================

/* COMMENTED OUT FOR V1.0 - UNCOMMENT FOR V2.0

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart' as models;
import '../models/user_pattern.dart';
import '../models/insight.dart';
import 'pattern_learner_service.dart';

/// Enhanced Insights Service
///
/// Week 6: Enhanced Insights - Insight Generation
/// Generates actionable insights from detected patterns.
///
/// Features:
/// - Weekly insights generation (Cloud Function: Sunday 8 PM)
/// - Achievement celebrations
/// - Trend observations
/// - Actionable recommendations
/// - Anomaly alerts
/// - Priority-based ordering
///
/// Uses Pattern Learner data + Analyst Agent for insight generation
class EnhancedInsightsService {
  static final EnhancedInsightsService _instance = EnhancedInsightsService._internal();
  factory EnhancedInsightsService() => _instance;
  EnhancedInsightsService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _patternLearner = PatternLearnerService();

  /// Generate weekly insights for a user
  ///
  /// This should be called weekly by a Cloud Function (Sunday 8 PM),
  /// but can also be triggered manually.
  Future<List<Insight>> generateWeeklyInsights(String userId) async {
    print('[EnhancedInsights] Generating weekly insights for user: $userId');

    // Get user's pattern data
    final pattern = await _patternLearner.getPattern(userId);
    if (pattern == null) {
      print('[EnhancedInsights] No pattern data found, analyzing first...');
      await _patternLearner.analyzePatterns(userId);
      // Try again after analysis
      final newPattern = await _patternLearner.getPattern(userId);
      if (newPattern == null) {
        return [];
      }
      return await _generateInsights(userId, newPattern);
    }

    return await _generateInsights(userId, pattern);
  }

  /// Generate insights from pattern data
  Future<List<Insight>> _generateInsights(
    String userId,
    UserPattern pattern,
  ) async {
    final insights = <Insight>[];

    // Get last week's transactions for comparison
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final transactions = await _getTransactions(userId, sevenDaysAgo);

    // Achievement insights
    insights.addAll(await _generateAchievementInsights(userId, pattern, transactions));

    // Budget adherence insights
    insights.addAll(_generateBudgetInsights(userId, pattern));

    // Spending trend insights
    insights.addAll(_generateTrendInsights(userId, pattern, transactions));

    // Recommendation insights
    insights.addAll(_generateRecommendationInsights(userId, pattern));

    // Anomaly insights (high severity only)
    insights.addAll(_generateAnomalyInsights(userId, pattern));

    // Emotional spending insights
    insights.addAll(_generateEmotionalInsights(userId, pattern));

    // Save insights to Firestore
    for (final insight in insights) {
      await _saveInsight(insight);
    }

    print('[EnhancedInsights] Generated ${insights.length} insights');
    return insights;
  }

  /// Generate achievement insights (positive reinforcement)
  Future<List<Insight>> _generateAchievementInsights(
    String userId,
    UserPattern pattern,
    List<models.Transaction> weekTransactions,
  ) async {
    final insights = <Insight>[];

    // Achievement: Good budget adherence
    if (pattern.budgetTrends.isGoodAdherence) {
      insights.add(Insight(
        id: '', // Firestore will generate
        userId: userId,
        type: InsightType.achievement,
        priority: InsightPriority.high,
        title: 'Great Budget Adherence!',
        message: 'You\'re at ${pattern.budgetTrends.adherenceRate.toStringAsFixed(0)}% budget adherence. Keep up the excellent work! 🎉',
        data: {'adherenceRate': pattern.budgetTrends.adherenceRate},
        status: InsightStatus.active,
        generatedAt: DateTime.now(),
        generatedBy: 'analyst_agent',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ));
    }

    // Achievement: Low spending week
    final weeklySpending = weekTransactions
        .where((t) => t.type == models.TransactionType.expense)
        .fold<double>(0, (total, t) => total + t.amount);

    final avgWeeklySpend = pattern.budgetTrends.avgMonthlySpend / 4.0;

    if (weeklySpending < avgWeeklySpend * 0.8 && weeklySpending > 0) {
      final savings = avgWeeklySpend - weeklySpending;
      insights.add(Insight(
        id: '',
        userId: userId,
        type: InsightType.achievement,
        priority: InsightPriority.medium,
        title: 'Low Spending Week!',
        message: 'You spent \$${weeklySpending.toStringAsFixed(2)} this week - \$${savings.toStringAsFixed(2)} less than your average. Awesome restraint! 💪',
        data: {'weeklySpending': weeklySpending, 'savings': savings},
        status: InsightStatus.active,
        generatedAt: DateTime.now(),
        generatedBy: 'analyst_agent',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ));
    }

    // Achievement: Decreasing trend in a category
    for (final entry in pattern.spendingPatterns.entries) {
      if (entry.value.trend == SpendingTrend.decreasing) {
        insights.add(Insight(
          id: '',
          userId: userId,
          type: InsightType.achievement,
          priority: InsightPriority.low,
          title: '${entry.key} Spending Decreasing',
          message: 'Your ${entry.key} spending is trending down. You\'re doing great! 📉',
          data: {'category': entry.key},
          category: entry.key,
          status: InsightStatus.active,
          generatedAt: DateTime.now(),
          generatedBy: 'analyst_agent',
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        ));
        break; // Only show one category achievement
      }
    }

    return insights;
  }

  /// Generate budget adherence insights
  List<Insight> _generateBudgetInsights(
    String userId,
    UserPattern pattern,
  ) {
    final insights = <Insight>[];

    // Alert: Poor budget adherence
    if (pattern.budgetTrends.isPoorAdherence) {
      insights.add(Insight(
        id: '',
        userId: userId,
        type: InsightType.alert,
        priority: InsightPriority.high,
        title: 'Budget Alert',
        message: 'You\'re at ${pattern.budgetTrends.adherenceRate.toStringAsFixed(0)}% budget adherence. Let\'s review your spending together.',
        data: {'adherenceRate': pattern.budgetTrends.adherenceRate},
        action: InsightAction(
          label: 'View Budget',
          type: InsightActionType.navigate,
          target: '/budget',
        ),
        status: InsightStatus.active,
        generatedAt: DateTime.now(),
        generatedBy: 'analyst_agent',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ));
    }

    // Alert: Overspending categories
    if (pattern.budgetTrends.overSpendCategories.isNotEmpty) {
      final categories = pattern.budgetTrends.overSpendCategories.take(3).join(', ');
      insights.add(Insight(
        id: '',
        userId: userId,
        type: InsightType.alert,
        priority: InsightPriority.medium,
        title: 'Overspending Alert',
        message: 'You\'re over budget in: $categories. Consider reducing spending in these areas.',
        data: {'categories': pattern.budgetTrends.overSpendCategories},
        action: InsightAction(
          label: 'View Transactions',
          type: InsightActionType.navigate,
          target: '/transactions',
        ),
        status: InsightStatus.active,
        generatedAt: DateTime.now(),
        generatedBy: 'analyst_agent',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ));
    }

    return insights;
  }

  /// Generate spending trend insights
  List<Insight> _generateTrendInsights(
    String userId,
    UserPattern pattern,
    List<models.Transaction> weekTransactions,
  ) {
    final insights = <Insight>[];

    // Trend: Increasing spending in a category
    for (final entry in pattern.spendingPatterns.entries) {
      if (entry.value.trend == SpendingTrend.increasing) {
        insights.add(Insight(
          id: '',
          userId: userId,
          type: InsightType.trend,
          priority: InsightPriority.medium,
          title: '${entry.key} Spending Up',
          message: 'Your ${entry.key} spending is increasing (avg \$${entry.value.avgAmount.toStringAsFixed(2)} per transaction). Keep an eye on this category.',
          data: {
            'category': entry.key,
            'avgAmount': entry.value.avgAmount,
            'frequency': entry.value.frequency,
          },
          category: entry.key,
          status: InsightStatus.active,
          generatedAt: DateTime.now(),
          generatedBy: 'analyst_agent',
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        ));
        break; // Only show one trend insight
      }
    }

    // Trend: High frequency in a category
    for (final entry in pattern.spendingPatterns.entries) {
      if (entry.value.frequency > 20) {
        // More than 20 times per month
        insights.add(Insight(
          id: '',
          userId: userId,
          type: InsightType.trend,
          priority: InsightPriority.low,
          title: 'Frequent ${entry.key} Purchases',
          message: 'You\'re making ${entry.value.frequency.toStringAsFixed(0)} ${entry.key} purchases per month. Consider bulk buying or subscriptions to save.',
          data: {
            'category': entry.key,
            'frequency': entry.value.frequency,
          },
          category: entry.key,
          status: InsightStatus.active,
          generatedAt: DateTime.now(),
          generatedBy: 'analyst_agent',
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        ));
        break; // Only show one frequency insight
      }
    }

    return insights;
  }

  /// Generate recommendation insights
  List<Insight> _generateRecommendationInsights(
    String userId,
    UserPattern pattern,
  ) {
    final insights = <Insight>[];

    // Recommendation: Coffee savings
    final coffeePattern = pattern.spendingPatterns['Coffee'];
    if (coffeePattern != null && coffeePattern.avgAmount > 4.0) {
      final monthlySpend = coffeePattern.avgAmount * coffeePattern.frequency;
      final savings = monthlySpend * 0.5; // 50% savings potential

      insights.add(Insight(
        id: '',
        userId: userId,
        type: InsightType.recommendation,
        priority: InsightPriority.medium,
        title: 'Coffee Savings Opportunity',
        message: 'You\'re spending \$${monthlySpend.toStringAsFixed(2)}/month on coffee. Brewing at home 2-3 days/week could save \$${savings.toStringAsFixed(2)}/month.',
        data: {
          'category': 'Coffee',
          'monthlySpend': monthlySpend,
          'potentialSavings': savings,
        },
        category: 'Coffee',
        status: InsightStatus.active,
        generatedAt: DateTime.now(),
        generatedBy: 'analyst_agent',
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      ));
    }

    // Recommendation: Dining savings
    final diningPattern = pattern.spendingPatterns['Dining'];
    if (diningPattern != null && diningPattern.frequency > 12) {
      // More than 3x/week
      final monthlySpend = diningPattern.avgAmount * diningPattern.frequency;
      final savings = monthlySpend * 0.3; // 30% savings potential

      insights.add(Insight(
        id: '',
        userId: userId,
        type: InsightType.recommendation,
        priority: InsightPriority.medium,
        title: 'Dining Savings Opportunity',
        message: 'You\'re dining out ${diningPattern.frequency.toStringAsFixed(0)} times/month. Meal prepping could save \$${savings.toStringAsFixed(2)}/month.',
        data: {
          'category': 'Dining',
          'monthlySpend': monthlySpend,
          'frequency': diningPattern.frequency,
          'potentialSavings': savings,
        },
        category: 'Dining',
        status: InsightStatus.active,
        generatedAt: DateTime.now(),
        generatedBy: 'analyst_agent',
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      ));
    }

    return insights;
  }

  /// Generate anomaly insights (high severity only)
  List<Insight> _generateAnomalyInsights(
    String userId,
    UserPattern pattern,
  ) {
    final insights = <Insight>[];

    // Only alert on high-severity anomalies
    final highPriorityAnomalies = pattern.highPriorityAnomalies;

    for (final anomaly in highPriorityAnomalies.take(2)) {
      // Max 2 anomaly insights
      String title;
      String message;

      switch (anomaly.type) {
        case 'large_purchase':
          title = 'Unusual Large Purchase';
          message = 'We detected an unusually large transaction. Was this intentional?';
          break;
        case 'unusual_time':
          title = 'Late Night Purchase';
          message = 'You made a purchase between 3-6 AM. Everything okay?';
          break;
        case 'unusual_merchant':
          title = 'New High-Value Merchant';
          message = 'First time purchase at this merchant with high amount. Please verify.';
          break;
        default:
          title = 'Unusual Activity';
          message = 'We detected unusual spending activity. Please review.';
      }

      insights.add(Insight(
        id: '',
        userId: userId,
        type: InsightType.anomaly,
        priority: InsightPriority.high,
        title: title,
        message: message,
        data: {
          'transactionId': anomaly.transactionId,
          'anomalyType': anomaly.type,
          'severity': anomaly.severity,
        },
        action: InsightAction(
          label: 'View Transaction',
          type: InsightActionType.navigate,
          target: '/transactions/${anomaly.transactionId}',
        ),
        status: InsightStatus.active,
        generatedAt: DateTime.now(),
        generatedBy: 'analyst_agent',
        expiresAt: DateTime.now().add(const Duration(days: 3)),
      ));
    }

    return insights;
  }

  /// Generate emotional spending insights
  List<Insight> _generateEmotionalInsights(
    String userId,
    UserPattern pattern,
  ) {
    final insights = <Insight>[];

    if (pattern.emotionalPatterns == null) return insights;

    final emotional = pattern.emotionalPatterns!;

    // Stress spending alert
    if (emotional.stressSpendingTriggers.isNotEmpty) {
      final trigger = emotional.primaryTrigger ?? 'stress';
      insights.add(Insight(
        id: '',
        userId: userId,
        type: InsightType.alert,
        priority: InsightPriority.high,
        title: 'Stress Spending Detected',
        message: 'We noticed patterns suggesting stress spending ($trigger). You\'re averaging \$${emotional.avgStressSpend.toStringAsFixed(2)} during these periods. Take a breath! 💙',
        data: {
          'triggers': emotional.stressSpendingTriggers,
          'avgSpend': emotional.avgStressSpend,
        },
        action: InsightAction(
          label: 'View Tips',
          type: InsightActionType.navigate,
          target: '/coaching',
        ),
        status: InsightStatus.active,
        generatedAt: DateTime.now(),
        generatedBy: 'analyst_agent',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ));
    }

    // Impulse category alert
    if (emotional.impulseCategories.isNotEmpty) {
      final categories = emotional.impulseCategories.take(2).join(' & ');
      insights.add(Insight(
        id: '',
        userId: userId,
        type: InsightType.recommendation,
        priority: InsightPriority.medium,
        title: 'Impulse Spending Patterns',
        message: 'You tend to make impulse purchases in: $categories. Try the 24-hour rule before buying.',
        data: {'impulseCategories': emotional.impulseCategories},
        status: InsightStatus.active,
        generatedAt: DateTime.now(),
        generatedBy: 'analyst_agent',
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      ));
    }

    return insights;
  }

  /// Get transactions for analysis
  Future<List<models.Transaction>> _getTransactions(
    String userId,
    DateTime since,
  ) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => models.Transaction.fromFirestore(doc))
        .toList();
  }

  /// Save insight to Firestore
  Future<void> _saveInsight(Insight insight) async {
    await _firestore.collection('insights').add(insight.toFirestore());
  }

  /// Get active insights for a user
  Future<List<Insight>> getActiveInsights(String userId) async {
    final snapshot = await _firestore
        .collection('insights')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('priority', descending: false)
        .orderBy('generatedAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => Insight.fromFirestore(doc))
        .where((insight) => !insight.isExpired)
        .toList();
  }

  /// Get all insights (including dismissed/expired) for a user
  Stream<List<Insight>> getInsightsStream(String userId) {
    return _firestore
        .collection('insights')
        .where('user_id', isEqualTo: userId)
        .orderBy('generatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Insight.fromFirestore(doc)).toList());
  }

  /// Dismiss an insight
  Future<void> dismissInsight(String insightId) async {
    await _firestore
        .collection('insights')
        .doc(insightId)
        .update({'status': InsightStatus.dismissed.name});
  }
}

*/ // END OF TIER 2 DISABLED CODE - Enhanced Insights Service
