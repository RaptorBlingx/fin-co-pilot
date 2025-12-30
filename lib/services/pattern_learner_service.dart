// =============================================================================
// TIER 2 FEATURE - DISABLED FOR V1.0 LAUNCH
// =============================================================================
// This service is part of V2.0 Pattern Learning features.
// Feature Flag: FeaturesConfig.enablePatternLearning = false
// 
// To re-enable for V2.0:
// 1. Set FeaturesConfig.enablePatternLearning = true in features_config.dart
// 2. Uncomment the code below
// 3. Test thoroughly
// =============================================================================

/* COMMENTED OUT FOR V1.0 - UNCOMMENT FOR V2.0

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart' as models;
import '../models/user_pattern.dart';
import 'dart:math' as math;

/// Pattern Learner Service
///
/// Week 6: Enhanced Insights - Pattern Detection
/// Analyzes user transaction history to identify spending patterns, trends, and anomalies.
///
/// Features:
/// - Category-based spending analysis
/// - Peak days/times detection
/// - Stress spending trigger identification
/// - Budget adherence tracking
/// - Anomaly detection
/// - Runs weekly (Cloud Function: Sunday 8 PM)
///
/// Uses Analyst Agent for deep pattern analysis
class PatternLearnerService {
  static final PatternLearnerService _instance = PatternLearnerService._internal();
  factory PatternLearnerService() => _instance;
  PatternLearnerService._internal();

  final _firestore = FirebaseFirestore.instance;

  /// Analyze patterns for a user
  ///
  /// This should be called weekly by a Cloud Function, but can also
  /// be triggered manually for testing/debugging.
  Future<UserPattern> analyzePatterns(String userId) async {
    print('[PatternLearner] Analyzing patterns for user: $userId');

    // Get last 90 days of transactions for comprehensive analysis
    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
    final transactions = await _getTransactions(userId, ninetyDaysAgo);

    if (transactions.isEmpty) {
      print('[PatternLearner] No transactions found, creating empty pattern');
      return _createEmptyPattern(userId);
    }

    print('[PatternLearner] Found ${transactions.length} transactions');

    // Analyze spending patterns by category
    final spendingPatterns = await _analyzeSpendingPatterns(transactions);

    // Analyze budget trends
    final budgetTrends = await _analyzeBudgetTrends(userId, transactions);

    // Detect emotional patterns (stress spending)
    final emotionalPatterns = _detectEmotionalPatterns(transactions);

    // Detect anomalies
    final anomalies = _detectAnomalies(transactions);

    final pattern = UserPattern(
      userId: userId,
      updatedAt: DateTime.now(),
      spendingPatterns: spendingPatterns,
      budgetTrends: budgetTrends,
      emotionalPatterns: emotionalPatterns,
      anomalies: anomalies,
    );

    // Save to Firestore
    await _savePattern(pattern);

    print('[PatternLearner] Pattern analysis complete');
    return pattern;
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

    return snapshot.docs.map((doc) => models.Transaction.fromFirestore(doc)).toList();
  }

  /// Analyze spending patterns by category
  Future<Map<String, CategorySpendingPattern>> _analyzeSpendingPatterns(
    List<models.Transaction> transactions,
  ) async {
    final patterns = <String, CategorySpendingPattern>{};

    // Group transactions by category
    final byCategory = <String, List<models.Transaction>>{};
    for (final txn in transactions) {
      if (txn.type == models.TransactionType.expense) {
        byCategory.putIfAbsent(txn.category, () => []).add(txn);
      }
    }

    // Analyze each category
    for (final entry in byCategory.entries) {
      final category = entry.key;
      final categoryTxns = entry.value;

      if (categoryTxns.isEmpty) continue;

      // Calculate average amount
      final avgAmount = categoryTxns.fold<double>(
        0,
        (total, txn) => total + txn.amount,
      ) / categoryTxns.length;

      // Calculate frequency (txns per month)
      final daysSpan = DateTime.now().difference(categoryTxns.last.date).inDays;
      final frequency = daysSpan > 0
          ? (categoryTxns.length / (daysSpan / 30.0))
          : categoryTxns.length.toDouble();

      // Find common merchants
      final merchantCounts = <String, int>{};
      for (final txn in categoryTxns) {
        if (txn.merchant != null) {
          merchantCounts[txn.merchant!] = (merchantCounts[txn.merchant!] ?? 0) + 1;
        }
      }
      final commonMerchants = merchantCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      final topMerchants = commonMerchants
          .take(5)
          .map((e) => e.key)
          .toList();

      // Detect peak days
      final dayOfWeekCounts = List.filled(7, 0);
      for (final txn in categoryTxns) {
        dayOfWeekCounts[txn.date.weekday % 7]++;
      }
      final peakDays = <int>[];
      final maxDayCount = dayOfWeekCounts.reduce(math.max);
      for (var i = 0; i < 7; i++) {
        if (dayOfWeekCounts[i] >= maxDayCount * 0.7) {
          peakDays.add(i);
        }
      }

      // Detect peak times
      final hourCounts = List.filled(24, 0);
      for (final txn in categoryTxns) {
        hourCounts[txn.date.hour]++;
      }
      final peakTimes = <int>[];
      final maxHourCount = hourCounts.reduce(math.max);
      for (var i = 0; i < 24; i++) {
        if (hourCounts[i] >= maxHourCount * 0.7) {
          peakTimes.add(i);
        }
      }

      // Detect trend (comparing first half vs second half)
      final midpoint = categoryTxns.length ~/ 2;
      final firstHalf = categoryTxns.sublist(0, midpoint);
      final secondHalf = categoryTxns.sublist(midpoint);

      final firstHalfAvg = firstHalf.isNotEmpty
          ? firstHalf.fold<double>(0, (total, txn) => total + txn.amount) /
              firstHalf.length
          : 0.0;
      final secondHalfAvg = secondHalf.isNotEmpty
          ? secondHalf.fold<double>(0, (total, txn) => total + txn.amount) /
              secondHalf.length
          : 0.0;

      SpendingTrend trend;
      if (secondHalfAvg > firstHalfAvg * 1.15) {
        trend = SpendingTrend.increasing;
      } else if (secondHalfAvg < firstHalfAvg * 0.85) {
        trend = SpendingTrend.decreasing;
      } else {
        trend = SpendingTrend.stable;
      }

      patterns[category] = CategorySpendingPattern(
        avgAmount: avgAmount,
        frequency: frequency,
        commonMerchants: topMerchants,
        peakDays: peakDays,
        peakTimes: peakTimes,
        trend: trend,
      );
    }

    return patterns;
  }

  /// Analyze budget adherence trends
  Future<BudgetTrends> _analyzeBudgetTrends(
    String userId,
    List<models.Transaction> transactions,
  ) async {
    // Get user's budgets
    final budgetsSnapshot = await _firestore
        .collection('budgets')
        .where('user_id', isEqualTo: userId)
        .get();

    // Calculate average monthly spending
    final expenseTxns = transactions.where((t) => t.type == models.TransactionType.expense).toList();
    final totalSpent = expenseTxns.fold<double>(0, (total, txn) => total + txn.amount);
    final daysSpan = transactions.isNotEmpty
        ? DateTime.now().difference(transactions.last.date).inDays
        : 30;
    final avgMonthlySpend = daysSpan > 0 ? (totalSpent / (daysSpan / 30.0)) : totalSpent;

    // Calculate adherence rate
    double adherenceRate = 100.0; // Default if no budgets
    final overSpendCategories = <String>[];

    if (budgetsSnapshot.docs.isNotEmpty) {
      final budget = budgetsSnapshot.docs.first.data();
      final budgetAmount = budget['amount'] as double;

      // Get current month spending
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final currentMonthTxns = expenseTxns
          .where((t) => t.date.isAfter(startOfMonth))
          .toList();
      final currentMonthSpent = currentMonthTxns.fold<double>(
        0,
        (total, txn) => total + txn.amount,
      );

      adherenceRate = budgetAmount > 0
          ? ((budgetAmount - currentMonthSpent) / budgetAmount * 100).clamp(0, 100)
          : 100.0;

      // Find overspend categories
      final categories = budget['categories'] as Map<String, dynamic>?;
      if (categories != null) {
        final categorySpending = <String, double>{};
        for (final txn in currentMonthTxns) {
          categorySpending[txn.category] =
              (categorySpending[txn.category] ?? 0) + txn.amount;
        }

        for (final entry in categories.entries) {
          final category = entry.key;
          final categoryData = entry.value as Map<String, dynamic>;
          final budgeted = (categoryData['budgeted'] as num).toDouble();
          final spent = categorySpending[category] ?? 0.0;

          if (spent > budgeted) {
            overSpendCategories.add(category);
          }
        }
      }
    }

    // Estimate income (from income transactions)
    final incomeTxns = transactions.where((t) => t.type == models.TransactionType.income).toList();
    final monthlyIncomeEstimate = incomeTxns.isNotEmpty
        ? incomeTxns.fold<double>(0, (total, txn) => total + txn.amount) /
            (daysSpan / 30.0)
        : null;

    return BudgetTrends(
      adherenceRate: adherenceRate,
      overSpendCategories: overSpendCategories,
      avgMonthlySpend: avgMonthlySpend,
      monthlyIncomeEstimate: monthlyIncomeEstimate,
    );
  }

  /// Detect emotional spending patterns
  ///
  /// Looks for patterns that suggest stress spending:
  /// - Multiple small purchases in short timeframes
  /// - Spending spikes at unusual times (late night, early morning)
  /// - Frequent shopping/entertainment during work hours
  EmotionalPatterns? _detectEmotionalPatterns(
    List<models.Transaction> transactions,
  ) {
    final stressTriggers = <String>{};
    final impulseCategories = <String>{};
    var totalStressSpend = 0.0;
    var stressEventCount = 0;

    // Look for late-night spending (11 PM - 3 AM)
    final lateNightTxns = transactions
        .where((t) => t.date.hour >= 23 || t.date.hour <= 3)
        .toList();

    if (lateNightTxns.length >= 5) {
      stressTriggers.add('late_night');
      totalStressSpend += lateNightTxns.fold<double>(0, (total, t) => total + t.amount);
      stressEventCount++;
    }

    // Look for rapid-fire purchases (3+ purchases within 1 hour)
    transactions.sort((a, b) => a.date.compareTo(b.date));
    for (var i = 0; i < transactions.length - 2; i++) {
      final t1 = transactions[i];
      final t2 = transactions[i + 1];
      final t3 = transactions[i + 2];

      if (t3.date.difference(t1.date).inHours <= 1) {
        stressTriggers.add('rapid_purchases');
        impulseCategories.add(t1.category);
        impulseCategories.add(t2.category);
        impulseCategories.add(t3.category);
        totalStressSpend += t1.amount + t2.amount + t3.amount;
        stressEventCount++;
      }
    }

    // Look for high-frequency shopping/entertainment
    final shoppingTxns = transactions
        .where((t) => t.category == 'Shopping' || t.category == 'Entertainment')
        .toList();

    if (shoppingTxns.length >= 10) {
      // Calculate average time between purchases
      if (shoppingTxns.length >= 2) {
        final totalDays = shoppingTxns.first.date
            .difference(shoppingTxns.last.date)
            .inDays;
        final avgDaysBetween = totalDays / shoppingTxns.length;

        // If shopping more than twice per week on average
        if (avgDaysBetween < 3.5) {
          stressTriggers.add('frequent_shopping');
          impulseCategories.add('Shopping');
          totalStressSpend += shoppingTxns.fold<double>(0, (total, t) => total + t.amount);
          stressEventCount++;
        }
      }
    }

    if (stressTriggers.isEmpty) {
      return null;
    }

    final avgStressSpend = stressEventCount > 0
        ? totalStressSpend / stressEventCount
        : 0.0;

    return EmotionalPatterns(
      stressSpendingTriggers: stressTriggers.toList(),
      impulseCategories: impulseCategories.toList(),
      avgStressSpend: avgStressSpend,
    );
  }

  /// Detect spending anomalies
  ///
  /// Identifies transactions that deviate significantly from user's normal patterns:
  /// - Large purchases (>2x category average)
  /// - Unusual timing (3-6 AM)
  /// - New merchants with high amounts
  List<SpendingAnomaly> _detectAnomalies(
    List<models.Transaction> transactions,
  ) {
    final anomalies = <SpendingAnomaly>[];

    // Calculate category averages
    final categoryAverages = <String, double>{};
    final byCategory = <String, List<models.Transaction>>{};

    for (final txn in transactions) {
      if (txn.type == models.TransactionType.expense) {
        byCategory.putIfAbsent(txn.category, () => []).add(txn);
      }
    }

    for (final entry in byCategory.entries) {
      final avg = entry.value.fold<double>(0, (total, t) => total + t.amount) /
          entry.value.length;
      categoryAverages[entry.key] = avg;
    }

    // Check recent transactions (last 30 days) for anomalies
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentTxns = transactions
        .where((t) => t.date.isAfter(thirtyDaysAgo))
        .toList();

    for (final txn in recentTxns) {
      if (txn.type != models.TransactionType.expense) continue;

      final categoryAvg = categoryAverages[txn.category] ?? 0.0;

      // Large purchase anomaly (>2x category average)
      if (categoryAvg > 0 && txn.amount > categoryAvg * 2) {
        final severity = (txn.amount / categoryAvg - 2).clamp(0, 1);
        anomalies.add(SpendingAnomaly(
          transactionId: txn.id,
          type: 'large_purchase',
          severity: math.min(0.5 + severity * 0.5, 1.0),
          detectedAt: DateTime.now(),
        ));
      }

      // Unusual time anomaly (3-6 AM)
      if (txn.date.hour >= 3 && txn.date.hour < 6) {
        anomalies.add(SpendingAnomaly(
          transactionId: txn.id,
          type: 'unusual_time',
          severity: 0.6,
          detectedAt: DateTime.now(),
        ));
      }

      // High amount + new merchant anomaly
      if (txn.merchant != null && txn.amount > 100) {
        final merchantTxns = transactions
            .where((t) => t.merchant == txn.merchant)
            .toList();

        // If this is one of the first 2 transactions with this merchant
        if (merchantTxns.length <= 2) {
          final severity = math.min(txn.amount / 500, 1.0);
          anomalies.add(SpendingAnomaly(
            transactionId: txn.id,
            type: 'unusual_merchant',
            severity: severity * 0.7,
            detectedAt: DateTime.now(),
          ));
        }
      }
    }

    // Sort by severity and return top 10
    anomalies.sort((a, b) => b.severity.compareTo(a.severity));
    return anomalies.take(10).toList();
  }

  /// Save pattern to Firestore
  Future<void> _savePattern(UserPattern pattern) async {
    await _firestore
        .collection('user_patterns')
        .doc(pattern.userId)
        .set(pattern.toFirestore());
  }

  /// Get existing pattern for a user
  Future<UserPattern?> getPattern(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_patterns')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserPattern.fromFirestore(doc);
    } catch (e) {
      print('Error getting pattern: $e');
      return null;
    }
  }

  /// Create empty pattern for new users
  UserPattern _createEmptyPattern(String userId) {
    return UserPattern(
      userId: userId,
      updatedAt: DateTime.now(),
      spendingPatterns: {},
      budgetTrends: BudgetTrends(
        adherenceRate: 100.0,
        overSpendCategories: [],
        avgMonthlySpend: 0.0,
      ),
      emotionalPatterns: null,
      anomalies: [],
    );
  }
}

*/ // END OF TIER 2 DISABLED CODE - Pattern Learner Service
