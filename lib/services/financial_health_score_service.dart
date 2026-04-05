import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/financial_health_score.dart';
import '../models/transaction.dart' as models;
import '../models/budget.dart';

/// Financial Health Score Calculation Service
///
/// Week 3 Killer Feature #3: Financial Health Score (0-100)
/// - Budget adherence: 0-25 points
/// - Savings rate: 0-25 points
/// - Debt management: 0-25 points
/// - Spending stability: 0-25 points
///
/// Target: Weekly recalculation, <1 sec calculation time
class FinancialHealthScoreService {
  static final FinancialHealthScoreService _instance =
      FinancialHealthScoreService._internal();
  factory FinancialHealthScoreService() => _instance;
  FinancialHealthScoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate and save financial health score for a user
  Future<FinancialHealthScore> calculateScore(String userId) async {
    try {
      // Get previous score for trend analysis
      final previousScore = await _getPreviousScore(userId);

      // Get last 30 days of data
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Fetch user data
      final transactions = await _getTransactions(userId, thirtyDaysAgo, now);
      final budgets = await _getBudgets(userId);
      final income = _calculateIncome(transactions);
      final expenses = _calculateExpenses(transactions);

      // Calculate 4 components (25 points each)
      final budgetAdherence = _calculateBudgetAdherence(
        transactions,
        budgets,
      );
      final savingsRate = _calculateSavingsRate(income, expenses);
      final debtManagement = _calculateDebtManagement(transactions);
      final spendingStability = _calculateSpendingStability(transactions);

      // Create breakdown
      final breakdown = ScoreBreakdown(
        budgetAdherence: budgetAdherence,
        savingsRate: savingsRate,
        debtManagement: debtManagement,
        spendingStability: spendingStability,
      );

      // Calculate total score
      final totalScore = breakdown.total;

      // Generate factors and recommendations
      final factors = _generateFactors(
        breakdown: breakdown,
        income: income,
        expenses: expenses,
        transactions: transactions,
        budgets: budgets,
      );

      // Determine trend
      final trend = _determineTrend(totalScore, previousScore);

      // Create score object
      final healthScore = FinancialHealthScore(
        id: '', // Will be set by Firestore
        userId: userId,
        calculatedAt: now,
        score: totalScore,
        breakdown: breakdown,
        factors: factors,
        trend: trend,
        previousScore: previousScore,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection('financial_health_scores')
          .add(healthScore.toFirestore());

      return FinancialHealthScore(
        id: docRef.id,
        userId: userId,
        calculatedAt: now,
        score: totalScore,
        breakdown: breakdown,
        factors: factors,
        trend: trend,
        previousScore: previousScore,
      );
    } catch (e) {
      print('Error calculating financial health score: $e');
      rethrow;
    }
  }

  /// Get user's latest financial health score
  Future<FinancialHealthScore?> getLatestScore(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('financial_health_scores')
          .where('user_id', isEqualTo: userId)
          .orderBy('calculatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return FinancialHealthScore.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error getting latest score: $e');
      return null;
    }
  }

  /// Get score history for a user
  Future<List<FinancialHealthScore>> getScoreHistory(
    String userId, {
    int limit = 12, // Last 12 weeks by default
  }) async {
    try {
      final snapshot = await _firestore
          .collection('financial_health_scores')
          .where('user_id', isEqualTo: userId)
          .orderBy('calculatedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FinancialHealthScore.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting score history: $e');
      return [];
    }
  }

  // ===== PRIVATE HELPER METHODS =====

  /// Get previous score
  Future<int?> _getPreviousScore(String userId) async {
    final latest = await getLatestScore(userId);
    return latest?.score;
  }

  /// Get transactions for date range
  Future<List<models.Transaction>> _getTransactions(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('transaction_date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('transaction_date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs
        .map((doc) => models.Transaction.fromFirestore(doc))
        .toList();
  }

  /// Get active budgets (with fallback if composite index missing)
  Future<List<Budget>> _getBudgets(String userId) async {
    try {
      // Try the ideal query first (requires composite index)
      final snapshot = await _firestore
          .collection('budgets')
          .where('user_id', isEqualTo: userId)
          .get();

      final now = DateTime.now();
      // Filter in memory to avoid multi-inequality index requirement
      return snapshot.docs
          .map((doc) => Budget.fromFirestore(doc))
          .where((budget) {
            return !budget.period.start.isAfter(now) && !budget.period.end.isBefore(now);
          })
          .toList();
    } catch (e) {
      print('Warning: Could not fetch budgets for health score: $e');
      return []; // Return empty — neutral budget score (15/25)
    }
  }

  /// Calculate total income
  double _calculateIncome(List<models.Transaction> transactions) {
    return transactions
        .where((t) => t.type == models.TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Calculate total expenses
  double _calculateExpenses(List<models.Transaction> transactions) {
    return transactions
        .where((t) => t.type == models.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Calculate budget adherence score (0-25)
  int _calculateBudgetAdherence(
    List<models.Transaction> transactions,
    List<Budget> budgets,
  ) {
    if (budgets.isEmpty) {
      // No budgets set - neutral score
      return 15;
    }

    // Calculate spending by category
    final spendingByCategory = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type == models.TransactionType.expense) {
        spendingByCategory[transaction.category] =
            (spendingByCategory[transaction.category] ?? 0.0) +
                transaction.amount;
      }
    }

    // Calculate adherence percentage for each budget
    final adherenceRates = <double>[];

    for (final budget in budgets) {
      // Check if this budget has per-category allocations
      if (budget.categories != null && budget.categories!.isNotEmpty) {
        // Per-category budget
        for (final entry in budget.categories!.entries) {
          final category = entry.key;
          final categoryBudget = entry.value;
          final spent = spendingByCategory[category] ?? 0.0;
          final budgeted = categoryBudget.budgeted;

          if (budgeted == 0) continue;

          final adherenceRate = 1.0 - (spent / budgeted).clamp(0.0, 2.0);
          adherenceRates.add(adherenceRate);
        }
      } else {
        // Overall budget
        final totalSpent = spendingByCategory.values.fold(0.0, (a, b) => a + b);
        final budgetAmount = budget.amount;

        if (budgetAmount == 0) continue;

        final adherenceRate = 1.0 - (totalSpent / budgetAmount).clamp(0.0, 2.0);
        adherenceRates.add(adherenceRate);
      }
    }

    if (adherenceRates.isEmpty) return 15;

    // Average adherence across all budgets
    final avgAdherence =
        adherenceRates.reduce((a, b) => a + b) / adherenceRates.length;

    // Convert to 0-25 scale
    return (avgAdherence * 25).round().clamp(0, 25);
  }

  /// Calculate savings rate score (0-25)
  int _calculateSavingsRate(double income, double expenses) {
    if (income == 0) {
      // No income data - neutral score
      return 15;
    }

    // Calculate savings rate
    final savingsRate = (income - expenses) / income;

    // Score based on savings rate thresholds
    // 20%+ = 25 points (excellent)
    // 15-20% = 20 points (good)
    // 10-15% = 15 points (fair)
    // 5-10% = 10 points (needs improvement)
    // <5% = 5 points (concerning)
    // Negative = 0 points (critical)

    if (savingsRate >= 0.20) return 25;
    if (savingsRate >= 0.15) return 20;
    if (savingsRate >= 0.10) return 15;
    if (savingsRate >= 0.05) return 10;
    if (savingsRate >= 0.0) return 5;
    return 0;
  }

  /// Calculate debt management score (0-25)
  int _calculateDebtManagement(List<models.Transaction> transactions) {
    // Count debt-related transactions
    final debtPayments = transactions.where((t) {
      final desc = (t.description ?? '').toLowerCase();
      return desc.contains('loan') ||
          desc.contains('debt') ||
          desc.contains('credit card payment') ||
          desc.contains('mortgage');
    }).toList();

    if (debtPayments.isEmpty) {
      // No debt payments detected - assume good (20 points)
      return 20;
    }

    // Calculate debt payment ratio
    final totalExpenses = transactions
        .where((t) => t.type == models.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    if (totalExpenses == 0) return 15;

    final totalDebtPayments =
        debtPayments.fold(0.0, (sum, t) => sum + t.amount);
    final debtRatio = totalDebtPayments / totalExpenses;

    // Score based on debt payment ratio
    // <20% = 25 points (excellent)
    // 20-30% = 20 points (good)
    // 30-40% = 15 points (fair)
    // 40-50% = 10 points (concerning)
    // >50% = 5 points (critical)

    if (debtRatio < 0.20) return 25;
    if (debtRatio < 0.30) return 20;
    if (debtRatio < 0.40) return 15;
    if (debtRatio < 0.50) return 10;
    return 5;
  }

  /// Calculate spending stability score (0-25)
  int _calculateSpendingStability(List<models.Transaction> transactions) {
    if (transactions.length < 7) {
      // Not enough data - neutral score
      return 15;
    }

    // Group expenses by day
    final expensesByDay = <int, double>{};
    for (final transaction in transactions) {
      if (transaction.type == models.TransactionType.expense) {
        final daysSinceEpoch = transaction.date.millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;
        expensesByDay[daysSinceEpoch] =
            (expensesByDay[daysSinceEpoch] ?? 0.0) + transaction.amount;
      }
    }

    if (expensesByDay.length < 7) return 15;

    // Calculate daily expense values
    final dailyExpenses = expensesByDay.values.toList();

    // Calculate mean
    final mean = dailyExpenses.reduce((a, b) => a + b) / dailyExpenses.length;

    // Calculate standard deviation
    final variance = dailyExpenses
            .map((x) => pow(x - mean, 2))
            .reduce((a, b) => a + b) /
        dailyExpenses.length;
    final stdDev = sqrt(variance);

    // Calculate coefficient of variation (CV)
    final cv = mean > 0 ? stdDev / mean : 0.0;

    // Score based on coefficient of variation
    // <0.3 = 25 points (very stable)
    // 0.3-0.5 = 20 points (stable)
    // 0.5-0.8 = 15 points (moderate)
    // 0.8-1.2 = 10 points (variable)
    // >1.2 = 5 points (very variable)

    if (cv < 0.3) return 25;
    if (cv < 0.5) return 20;
    if (cv < 0.8) return 15;
    if (cv < 1.2) return 10;
    return 5;
  }

  /// Generate factors and recommendations
  ScoreFactors _generateFactors({
    required ScoreBreakdown breakdown,
    required double income,
    required double expenses,
    required List<models.Transaction> transactions,
    required List<Budget> budgets,
  }) {
    final positives = <String>[];
    final negatives = <String>[];
    final recommendations = <String>[];

    // Analyze budget adherence
    if (breakdown.budgetAdherence >= 20) {
      positives.add('Excellent budget adherence');
    } else if (breakdown.budgetAdherence < 10) {
      negatives.add('Struggling with budget limits');
      recommendations.add('Review and adjust your budgets to be more realistic');
    }

    // Analyze savings rate
    final savingsRate = income > 0 ? (income - expenses) / income : 0.0;
    if (savingsRate >= 0.20) {
      positives.add('Strong savings habit (${(savingsRate * 100).toStringAsFixed(0)}% saved)');
    } else if (savingsRate < 0.05) {
      negatives.add('Low savings rate (${(savingsRate * 100).toStringAsFixed(0)}%)');
      recommendations.add('Try to save at least 10% of your income each month');
    }

    // Analyze spending stability
    if (breakdown.spendingStability >= 20) {
      positives.add('Consistent and predictable spending');
    } else if (breakdown.spendingStability < 10) {
      negatives.add('Irregular spending patterns');
      recommendations.add('Create a weekly spending plan to smooth out expenses');
    }

    // Analyze debt management
    if (breakdown.debtManagement >= 20) {
      positives.add('Healthy debt-to-income ratio');
    } else if (breakdown.debtManagement < 10) {
      negatives.add('High debt payment burden');
      recommendations.add('Consider debt consolidation or payment plan adjustments');
    }

    // General recommendations based on total score
    if (breakdown.total < 50) {
      recommendations.add('Focus on building one positive habit at a time');
      recommendations.add('Start with tracking all expenses for 2 weeks');
    } else if (breakdown.total < 70) {
      recommendations.add('You\'re making progress! Keep up the momentum');
    } else if (breakdown.total >= 80) {
      positives.add('Outstanding financial discipline!');
    }

    // Ensure we always have at least one item in each category
    if (positives.isEmpty) {
      positives.add('You\'re taking steps to improve your financial health');
    }
    if (recommendations.isEmpty) {
      recommendations.add('Keep tracking your expenses and reviewing your progress');
    }

    return ScoreFactors(
      positives: positives,
      negatives: negatives,
      recommendations: recommendations,
    );
  }

  /// Determine score trend
  ScoreTrend _determineTrend(int currentScore, int? previousScore) {
    if (previousScore == null) {
      return ScoreTrend.stable; // First score
    }

    final change = currentScore - previousScore;

    if (change >= 5) return ScoreTrend.improving;
    if (change <= -5) return ScoreTrend.declining;
    return ScoreTrend.stable;
  }
}
