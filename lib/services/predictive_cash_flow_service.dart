import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart' as models;

/// Predictive Cash Flow Service
///
/// Week 5 Killer Feature #5: Prevent overdrafts
/// - Calculate daily burn rate from last 30 days
/// - Project balance to $0
/// - Factor in recurring expenses
/// - Factor in expected income
/// - 85%+ accuracy target
/// - 7-day minimum lookahead
class PredictiveCashFlowService {
  static final PredictiveCashFlowService _instance =
      PredictiveCashFlowService._internal();
  factory PredictiveCashFlowService() => _instance;
  PredictiveCashFlowService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get predicted cash flow for a user
  Future<CashFlowPrediction> predictCashFlow(
    String userId, {
    double? currentBalance,
    int daysToProject = 30,
  }) async {
    try {
      // Get last 30 days of transactions
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final transactions = await _getTransactions(userId, thirtyDaysAgo);

      // Get current balance (from user profile or parameter)
      final balance = currentBalance ?? await _getCurrentBalance(userId);

      // Calculate daily burn rate
      final dailyBurnRate = _calculateDailyBurnRate(transactions);

      // Detect recurring expenses
      final recurringExpenses = await _detectRecurringExpenses(userId, transactions);

      // Detect expected income
      final expectedIncome = await _detectExpectedIncome(userId, transactions);

      // Project daily balances
      final dailyProjections = _projectDailyBalances(
        currentBalance: balance,
        dailyBurnRate: dailyBurnRate,
        recurringExpenses: recurringExpenses,
        expectedIncome: expectedIncome,
        daysToProject: daysToProject,
      );

      // Calculate days until $0
      final daysUntilZero = _calculateDaysUntilZero(dailyProjections);

      // Determine status
      final status = _determineStatus(daysUntilZero, balance);

      // Get projected end balance
      final projectedEndBalance = dailyProjections.isNotEmpty
          ? dailyProjections.last.balance
          : balance;

      return CashFlowPrediction(
        currentBalance: balance,
        dailyBurnRate: dailyBurnRate,
        daysUntilZero: daysUntilZero,
        projectedEndBalance: projectedEndBalance,
        status: status,
        dailyProjections: dailyProjections,
        recurringExpenses: recurringExpenses,
        expectedIncome: expectedIncome,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error predicting cash flow: $e');
      rethrow;
    }
  }

  /// Check if user can afford a purchase
  Future<AffordabilityCheck> canAfford({
    required String userId,
    required double amount,
    String? itemName,
  }) async {
    try {
      // Get current cash flow prediction
      final prediction = await predictCashFlow(userId);

      // Calculate new balance after purchase
      final balanceAfterPurchase = prediction.currentBalance - amount;

      // Recalculate days until zero with new balance
      final newProjections = _projectDailyBalances(
        currentBalance: balanceAfterPurchase,
        dailyBurnRate: prediction.dailyBurnRate,
        recurringExpenses: prediction.recurringExpenses,
        expectedIncome: prediction.expectedIncome,
        daysToProject: 30,
      );

      final newDaysUntilZero = _calculateDaysUntilZero(newProjections);

      // Calculate impact
      final daysLost = (prediction.daysUntilZero ?? 30) - (newDaysUntilZero ?? 0);

      // Determine if affordable
      final isAffordable = _isAffordable(
        balanceAfterPurchase: balanceAfterPurchase,
        newDaysUntilZero: newDaysUntilZero,
        daysLost: daysLost,
      );

      // Generate recommendations
      final recommendations = _generateAffordabilityRecommendations(
        amount: amount,
        itemName: itemName,
        isAffordable: isAffordable,
        balanceAfterPurchase: balanceAfterPurchase,
        daysUntilZero: newDaysUntilZero,
        dailyBurnRate: prediction.dailyBurnRate,
        nextIncome: prediction.expectedIncome.isNotEmpty
            ? prediction.expectedIncome.first
            : null,
      );

      return AffordabilityCheck(
        amount: amount,
        itemName: itemName,
        currentBalance: prediction.currentBalance,
        balanceAfterPurchase: balanceAfterPurchase,
        isAffordable: isAffordable,
        daysUntilZero: newDaysUntilZero,
        daysLost: daysLost,
        recommendations: recommendations,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error checking affordability: $e');
      rethrow;
    }
  }

  // ===== PRIVATE HELPER METHODS =====

  /// Get transactions for the last N days
  Future<List<models.Transaction>> _getTransactions(
    String userId,
    DateTime since,
  ) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => models.Transaction.fromFirestore(doc))
        .toList();
  }

  /// Get current balance from user profile
  Future<double> _getCurrentBalance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0.0;

      final data = userDoc.data() as Map<String, dynamic>;
      return (data['currentBalance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('Error getting current balance: $e');
      return 0.0;
    }
  }

  /// Calculate daily burn rate (average daily spending)
  double _calculateDailyBurnRate(List<models.Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;

    final expenses = transactions.where(
      (t) => t.type == models.TransactionType.expense,
    );

    if (expenses.isEmpty) return 0.0;

    final totalExpenses = expenses.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    // Calculate days span
    final firstDate = transactions.first.date;
    final lastDate = transactions.last.date;
    final daySpan = max(1, lastDate.difference(firstDate).inDays);

    return totalExpenses / daySpan;
  }

  /// Detect recurring expenses (subscriptions, bills)
  Future<List<RecurringExpense>> _detectRecurringExpenses(
    String userId,
    List<models.Transaction> transactions,
  ) async {
    final recurringExpenses = <RecurringExpense>[];

    // Group transactions by merchant
    final merchantGroups = <String, List<models.Transaction>>{};
    for (final transaction in transactions) {
      if (transaction.type == models.TransactionType.expense &&
          transaction.merchant != null) {
        final merchant = transaction.merchant!;
        merchantGroups.putIfAbsent(merchant, () => []).add(transaction);
      }
    }

    // Detect recurring patterns
    for (final entry in merchantGroups.entries) {
      final merchant = entry.key;
      final merchantTransactions = entry.value;

      if (merchantTransactions.length < 2) continue;

      // Sort by date
      merchantTransactions.sort((a, b) => a.date.compareTo(b.date));

      // Calculate average interval between transactions
      final intervals = <int>[];
      for (int i = 1; i < merchantTransactions.length; i++) {
        final interval = merchantTransactions[i]
            .date
            .difference(merchantTransactions[i - 1].date)
            .inDays;
        intervals.add(interval);
      }

      if (intervals.isEmpty) continue;

      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

      // Check if interval is consistent (within 20% variance)
      final variance = _calculateVariance(intervals);
      final isRecurring = variance < (avgInterval * 0.2);

      if (isRecurring && avgInterval >= 7) {
        // Calculate average amount
        final avgAmount = merchantTransactions.fold<double>(
              0.0,
              (sum, t) => sum + t.amount,
            ) /
            merchantTransactions.length;

        // Calculate next due date
        final lastDate = merchantTransactions.last.date;
        final nextDueDate = lastDate.add(Duration(days: avgInterval.round()));

        recurringExpenses.add(RecurringExpense(
          merchant: merchant,
          amount: avgAmount,
          intervalDays: avgInterval.round(),
          nextDueDate: nextDueDate,
          lastAmount: merchantTransactions.last.amount,
        ));
      }
    }

    return recurringExpenses;
  }

  /// Detect expected income (paychecks)
  Future<List<ExpectedIncome>> _detectExpectedIncome(
    String userId,
    List<models.Transaction> transactions,
  ) async {
    final expectedIncome = <ExpectedIncome>[];

    // Get income transactions
    final incomeTransactions = transactions.where(
      (t) => t.type == models.TransactionType.income,
    ).toList();

    if (incomeTransactions.length < 2) return expectedIncome;

    // Sort by date
    incomeTransactions.sort((a, b) => a.date.compareTo(b.date));

    // Calculate intervals
    final intervals = <int>[];
    for (int i = 1; i < incomeTransactions.length; i++) {
      final interval = incomeTransactions[i]
          .date
          .difference(incomeTransactions[i - 1].date)
          .inDays;
      intervals.add(interval);
    }

    if (intervals.isEmpty) return expectedIncome;

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    // Check if income is regular (within 20% variance)
    final variance = _calculateVariance(intervals);
    final isRegular = variance < (avgInterval * 0.2);

    if (isRegular) {
      // Calculate average amount
      final avgAmount = incomeTransactions.fold<double>(
            0.0,
            (sum, t) => sum + t.amount,
          ) /
          incomeTransactions.length;

      // Calculate next payday
      final lastDate = incomeTransactions.last.date;
      final nextPayday = lastDate.add(Duration(days: avgInterval.round()));

      expectedIncome.add(ExpectedIncome(
        source: incomeTransactions.last.merchant ?? 'Paycheck',
        amount: avgAmount,
        intervalDays: avgInterval.round(),
        nextDate: nextPayday,
      ));
    }

    return expectedIncome;
  }

  /// Project daily balances
  List<DailyProjection> _projectDailyBalances({
    required double currentBalance,
    required double dailyBurnRate,
    required List<RecurringExpense> recurringExpenses,
    required List<ExpectedIncome> expectedIncome,
    required int daysToProject,
  }) {
    final projections = <DailyProjection>[];
    var balance = currentBalance;
    final today = DateTime.now();

    for (int i = 0; i < daysToProject; i++) {
      final date = today.add(Duration(days: i));

      // Apply daily burn rate
      balance -= dailyBurnRate;

      // Check for recurring expenses due on this date
      for (final expense in recurringExpenses) {
        if (_isSameDay(date, expense.nextDueDate)) {
          balance -= expense.amount;
        }
      }

      // Check for expected income on this date
      for (final income in expectedIncome) {
        if (_isSameDay(date, income.nextDate)) {
          balance += income.amount;
        }
      }

      projections.add(DailyProjection(
        date: date,
        balance: balance,
        dailyChange: -dailyBurnRate,
      ));

      // Stop if balance goes negative
      if (balance <= 0) break;
    }

    return projections;
  }

  /// Calculate days until balance reaches $0
  int? _calculateDaysUntilZero(List<DailyProjection> projections) {
    for (int i = 0; i < projections.length; i++) {
      if (projections[i].balance <= 0) {
        return i;
      }
    }
    return null; // Won't hit $0 in projection period
  }

  /// Determine cash flow status
  CashFlowStatus _determineStatus(int? daysUntilZero, double balance) {
    if (balance <= 0) {
      return CashFlowStatus.critical;
    } else if (daysUntilZero != null && daysUntilZero < 7) {
      return CashFlowStatus.critical;
    } else if (daysUntilZero != null && daysUntilZero < 14) {
      return CashFlowStatus.warning;
    } else {
      return CashFlowStatus.healthy;
    }
  }

  /// Check if purchase is affordable
  bool _isAffordable({
    required double balanceAfterPurchase,
    required int? newDaysUntilZero,
    required int daysLost,
  }) {
    // Not affordable if balance goes negative
    if (balanceAfterPurchase < 0) return false;

    // Not affordable if it brings you to <7 days until $0
    if (newDaysUntilZero != null && newDaysUntilZero < 7) return false;

    // Not affordable if you lose >7 days of runway
    if (daysLost > 7) return false;

    return true;
  }

  /// Generate affordability recommendations
  List<String> _generateAffordabilityRecommendations({
    required double amount,
    String? itemName,
    required bool isAffordable,
    required double balanceAfterPurchase,
    required int? daysUntilZero,
    required double dailyBurnRate,
    ExpectedIncome? nextIncome,
  }) {
    final recommendations = <String>[];
    final item = itemName ?? 'this purchase';

    if (isAffordable) {
      recommendations.add('✅ You can afford $item');
      if (daysUntilZero != null) {
        recommendations.add(
            'You\'ll have \$${balanceAfterPurchase.toStringAsFixed(2)} for $daysUntilZero days');
      }
    } else {
      recommendations.add('⚠️ Not recommended');

      if (balanceAfterPurchase < 0) {
        recommendations.add('This would overdraw your account');
      } else if (daysUntilZero != null && daysUntilZero < 7) {
        recommendations.add(
            'You\'ll only have \$${balanceAfterPurchase.toStringAsFixed(2)} for $daysUntilZero days');
        final dailyNeeded = balanceAfterPurchase / daysUntilZero;
        recommendations.add(
            'That\'s \$${dailyNeeded.toStringAsFixed(2)}/day vs usual \$${dailyBurnRate.toStringAsFixed(2)}');
      }

      // Suggest alternatives
      if (nextIncome != null) {
        final daysUntilPayday =
            nextIncome.nextDate.difference(DateTime.now()).inDays;
        if (daysUntilPayday > 0) {
          recommendations.add('💡 Wait $daysUntilPayday days (after payday)');
        }
      }

      // Suggest smaller purchase
      final affordableAmount = amount * 0.5;
      recommendations.add('💡 Consider buying under \$${affordableAmount.toStringAsFixed(0)}');
    }

    return recommendations;
  }

  /// Calculate variance
  double _calculateVariance(List<int> numbers) {
    if (numbers.isEmpty) return 0.0;

    final mean = numbers.reduce((a, b) => a + b) / numbers.length;
    final squaredDiffs = numbers.map((n) => pow(n - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / numbers.length;
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ===== DATA CLASSES =====

class CashFlowPrediction {
  final double currentBalance;
  final double dailyBurnRate;
  final int? daysUntilZero;
  final double projectedEndBalance;
  final CashFlowStatus status;
  final List<DailyProjection> dailyProjections;
  final List<RecurringExpense> recurringExpenses;
  final List<ExpectedIncome> expectedIncome;
  final DateTime lastUpdated;

  CashFlowPrediction({
    required this.currentBalance,
    required this.dailyBurnRate,
    this.daysUntilZero,
    required this.projectedEndBalance,
    required this.status,
    required this.dailyProjections,
    required this.recurringExpenses,
    required this.expectedIncome,
    required this.lastUpdated,
  });

  String get statusMessage {
    switch (status) {
      case CashFlowStatus.critical:
        if (daysUntilZero != null) {
          return 'You\'ll hit \$0 in $daysUntilZero days';
        }
        return 'Critical: Balance very low';
      case CashFlowStatus.warning:
        return 'Running low - \$${currentBalance.toStringAsFixed(2)} for $daysUntilZero days';
      case CashFlowStatus.healthy:
        if (projectedEndBalance > 0) {
          return 'On track to end month with \$${projectedEndBalance.toStringAsFixed(2)}';
        }
        return 'Looking good!';
    }
  }
}

class DailyProjection {
  final DateTime date;
  final double balance;
  final double dailyChange;

  DailyProjection({
    required this.date,
    required this.balance,
    required this.dailyChange,
  });
}

class RecurringExpense {
  final String merchant;
  final double amount;
  final int intervalDays;
  final DateTime nextDueDate;
  final double lastAmount;

  RecurringExpense({
    required this.merchant,
    required this.amount,
    required this.intervalDays,
    required this.nextDueDate,
    required this.lastAmount,
  });
}

class ExpectedIncome {
  final String source;
  final double amount;
  final int intervalDays;
  final DateTime nextDate;

  ExpectedIncome({
    required this.source,
    required this.amount,
    required this.intervalDays,
    required this.nextDate,
  });
}

class AffordabilityCheck {
  final double amount;
  final String? itemName;
  final double currentBalance;
  final double balanceAfterPurchase;
  final bool isAffordable;
  final int? daysUntilZero;
  final int daysLost;
  final List<String> recommendations;
  final DateTime calculatedAt;

  AffordabilityCheck({
    required this.amount,
    this.itemName,
    required this.currentBalance,
    required this.balanceAfterPurchase,
    required this.isAffordable,
    this.daysUntilZero,
    required this.daysLost,
    required this.recommendations,
    required this.calculatedAt,
  });
}

enum CashFlowStatus {
  critical, // <7 days or balance <=0
  warning, // <14 days
  healthy, // >14 days or positive end balance
}
