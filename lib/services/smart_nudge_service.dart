// =============================================================================
// TIER 2 FEATURE - DISABLED FOR V1.0 LAUNCH
// =============================================================================
// This service is part of V2.0 Smart Nudges & Pattern Learning features.
// Feature Flag: FeaturesConfig.enableSmartNudges = false
// 
// To re-enable for V2.0:
// 1. Set FeaturesConfig.enableSmartNudges = true in features_config.dart
// 2. Uncomment the code below
// 3. Test thoroughly
// =============================================================================

/* COMMENTED OUT FOR V1.0 - UNCOMMENT FOR V2.0

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/smart_nudge.dart';
import '../models/transaction.dart' as models;
import '../models/budget.dart';
import 'notification_service.dart';

/// Smart Nudge Service
///
/// Week 4 Killer Feature #4: Proactive spending warnings
/// - Budget warnings: "You're at 90% of your dining budget"
/// - Impulse alerts: "You've spent $200 on shopping in 3 days"
/// - Bill reminders: "Netflix due tomorrow"
/// - Savings opportunities: "You could save $50/month"
///
/// Target: <1 sec detection, 20%+ reduction in overspending
class SmartNudgeService {
  static final SmartNudgeService _instance = SmartNudgeService._internal();
  factory SmartNudgeService() => _instance;
  SmartNudgeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Check for nudges after a transaction is created
  Future<void> checkForNudges({
    required String userId,
    required models.Transaction transaction,
  }) async {
    try {
      // Run all nudge checks in parallel
      await Future.wait([
        _checkBudgetWarnings(userId, transaction),
        _checkImpulseSpending(userId, transaction),
        _checkSpendingPatterns(userId, transaction),
      ]);
    } catch (e) {
      print('Error checking for nudges: $e');
    }
  }

  /// Check for budget warnings (90%, 100%)
  Future<void> _checkBudgetWarnings(
    String userId,
    models.Transaction transaction,
  ) async {
    try {
      // Only check expense transactions
      if (transaction.type != models.TransactionType.expense) return;

      // Get active budgets for this category
      final budgets = await _getActiveBudgets(userId);

      for (final budget in budgets) {
        // Check if this transaction affects this budget
        bool affectsBudget = false;

        if (budget.categories != null &&
            budget.categories!.containsKey(transaction.category)) {
          // Per-category budget
          affectsBudget = true;
        } else if (budget.categories == null || budget.categories!.isEmpty) {
          // Overall budget
          affectsBudget = true;
        }

        if (!affectsBudget) continue;

        // Calculate spending including this transaction
        final currentSpending = await _getCategorySpending(
          userId,
          transaction.category,
          budget.period.start,
          budget.period.end,
        );

        double budgetLimit;
        if (budget.categories != null &&
            budget.categories!.containsKey(transaction.category)) {
          budgetLimit = budget.categories![transaction.category]!.budgeted;
        } else {
          budgetLimit = budget.amount;
        }

        final percentageUsed = (currentSpending / budgetLimit * 100);

        // Generate nudge at 90% threshold
        if (percentageUsed >= 90 && percentageUsed < 100) {
          await _createBudgetWarningNudge(
            userId: userId,
            budget: budget,
            category: transaction.category,
            currentSpending: currentSpending,
            budgetLimit: budgetLimit,
            percentageUsed: percentageUsed,
            transaction: transaction,
          );
        }
        // Generate critical nudge at 100% threshold
        else if (percentageUsed >= 100) {
          await _createBudgetExceededNudge(
            userId: userId,
            budget: budget,
            category: transaction.category,
            currentSpending: currentSpending,
            budgetLimit: budgetLimit,
            overAmount: currentSpending - budgetLimit,
            transaction: transaction,
          );
        }
      }
    } catch (e) {
      print('Error checking budget warnings: $e');
    }
  }

  /// Check for impulse spending (multiple purchases in short time)
  Future<void> _checkImpulseSpending(
    String userId,
    models.Transaction transaction,
  ) async {
    try {
      // Only check expense transactions
      if (transaction.type != models.TransactionType.expense) return;

      // Get transactions in the last 3 days for this category
      final threeDaysAgo =
          DateTime.now().subtract(const Duration(days: 3));

      final recentTransactions = await _getTransactions(
        userId,
        threeDaysAgo,
        DateTime.now(),
        category: transaction.category,
      );

      // Count transactions and calculate total
      final count = recentTransactions.length;
      final total = recentTransactions.fold<double>(
        0.0,
        (sum, t) => sum + t.amount,
      );

      // Trigger impulse alert if 3+ purchases in 3 days or >$200 spent
      if (count >= 3 || total >= 200) {
        await _createImpulseAlertNudge(
          userId: userId,
          category: transaction.category,
          count: count,
          total: total,
          transaction: transaction,
        );
      }
    } catch (e) {
      print('Error checking impulse spending: $e');
    }
  }

  /// Check for spending patterns (frequent small purchases)
  Future<void> _checkSpendingPatterns(
    String userId,
    models.Transaction transaction,
  ) async {
    try {
      // Only check expense transactions
      if (transaction.type != models.TransactionType.expense) return;

      // Get transactions at the same merchant in the last week
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      final merchantTransactions = await _getTransactions(
        userId,
        oneWeekAgo,
        DateTime.now(),
      );

      final sameMerchant = merchantTransactions.where(
        (t) => t.merchant?.toLowerCase() ==
            transaction.merchant?.toLowerCase(),
      ).toList();

      // If 3+ visits to same merchant in a week
      if (sameMerchant.length >= 3) {
        final total = sameMerchant.fold<double>(
          0.0,
          (sum, t) => sum + t.amount,
        );

        await _createPatternNudge(
          userId: userId,
          merchant: transaction.merchant ?? 'this merchant',
          count: sameMerchant.length,
          total: total,
          transaction: transaction,
        );
      }
    } catch (e) {
      print('Error checking spending patterns: $e');
    }
  }

  /// Create budget warning nudge (90% threshold)
  Future<void> _createBudgetWarningNudge({
    required String userId,
    required Budget budget,
    required String category,
    required double currentSpending,
    required double budgetLimit,
    required double percentageUsed,
    required models.Transaction transaction,
  }) async {
    // Check if similar nudge exists in last 24 hours
    if (await _hasRecentNudge(
      userId,
      NudgeType.budgetWarning,
      hours: 24,
    )) {
      return;
    }

    final remaining = budgetLimit - currentSpending;

    final nudge = SmartNudge(
      id: '',
      userId: userId,
      type: NudgeType.budgetWarning,
      priority: NudgePriority.medium,
      title: '${category} Budget Alert',
      message:
          'You\'re at ${percentageUsed.toStringAsFixed(0)}% of your ${category.toLowerCase()} budget. \$${remaining.toStringAsFixed(2)} remaining for ${budget.daysRemaining} days.',
      data: {
        'budgetId': budget.id,
        'category': category,
        'currentSpending': currentSpending,
        'budgetLimit': budgetLimit,
        'percentageUsed': percentageUsed,
        'remaining': remaining,
      },
      triggeredBy: NudgeTrigger(
        transactionId: transaction.id,
        budgetId: budget.id,
      ),
      action: NudgeAction(
        label: 'View Budget',
        type: NudgeActionType.viewBudget,
        target: budget.id,
      ),
      status: NudgeStatus.active,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
    );

    // Save to Firestore
    await _firestore.collection('smart_nudges').add(nudge.toFirestore());

    // Send push notification
    await _notificationService.showGeneral(
      id: nudge.hashCode,
      title: nudge.title,
      body: nudge.message,
      payload: {'nudgeType': 'budget_warning', 'budgetId': budget.id},
    );
  }

  /// Create budget exceeded nudge (100% threshold)
  Future<void> _createBudgetExceededNudge({
    required String userId,
    required Budget budget,
    required String category,
    required double currentSpending,
    required double budgetLimit,
    required double overAmount,
    required models.Transaction transaction,
  }) async {
    // Check if similar nudge exists in last 12 hours
    if (await _hasRecentNudge(
      userId,
      NudgeType.budgetWarning,
      hours: 12,
    )) {
      return;
    }

    final nudge = SmartNudge(
      id: '',
      userId: userId,
      type: NudgeType.budgetWarning,
      priority: NudgePriority.high,
      title: '${category} Budget Exceeded',
      message:
          'You\'ve exceeded your ${category.toLowerCase()} budget by \$${overAmount.toStringAsFixed(2)}. ${budget.daysRemaining} days left in this period.',
      data: {
        'budgetId': budget.id,
        'category': category,
        'currentSpending': currentSpending,
        'budgetLimit': budgetLimit,
        'overAmount': overAmount,
      },
      triggeredBy: NudgeTrigger(
        transactionId: transaction.id,
        budgetId: budget.id,
      ),
      action: NudgeAction(
        label: 'View Budget',
        type: NudgeActionType.viewBudget,
        target: budget.id,
      ),
      status: NudgeStatus.active,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
    );

    // Save to Firestore
    await _firestore.collection('smart_nudges').add(nudge.toFirestore());

    // Send push notification
    await _notificationService.showGeneral(
      id: nudge.hashCode,
      title: nudge.title,
      body: nudge.message,
      payload: {'nudgeType': 'budget_exceeded', 'budgetId': budget.id},
    );
  }

  /// Create impulse alert nudge
  Future<void> _createImpulseAlertNudge({
    required String userId,
    required String category,
    required int count,
    required double total,
    required models.Transaction transaction,
  }) async {
    // Check if similar nudge exists in last 24 hours
    if (await _hasRecentNudge(
      userId,
      NudgeType.impulseAlert,
      hours: 24,
    )) {
      return;
    }

    final nudge = SmartNudge(
      id: '',
      userId: userId,
      type: NudgeType.impulseAlert,
      priority: NudgePriority.medium,
      title: 'Spending Pattern Alert',
      message:
          'You\'ve made $count ${category.toLowerCase()} purchases in the last 3 days (\$${total.toStringAsFixed(2)} total). Take a pause?',
      data: {
        'category': category,
        'count': count,
        'total': total,
        'days': 3,
      },
      triggeredBy: NudgeTrigger(
        transactionId: transaction.id,
        pattern: 'frequent_category_purchases',
      ),
      action: NudgeAction(
        label: 'View Transactions',
        type: NudgeActionType.viewTransactions,
      ),
      status: NudgeStatus.active,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
    );

    // Save to Firestore
    await _firestore.collection('smart_nudges').add(nudge.toFirestore());

    // Send push notification
    await _notificationService.showGeneral(
      id: nudge.hashCode,
      title: nudge.title,
      body: nudge.message,
      payload: {'nudgeType': 'impulse_alert'},
    );
  }

  /// Create pattern nudge (frequent merchant visits)
  Future<void> _createPatternNudge({
    required String userId,
    required String merchant,
    required int count,
    required double total,
    required models.Transaction transaction,
  }) async {
    // Check if similar nudge exists in last 48 hours
    if (await _hasRecentNudge(
      userId,
      NudgeType.impulseAlert,
      hours: 48,
    )) {
      return;
    }

    // Calculate potential savings
    final avgPerVisit = total / count;
    final monthlySavings = (avgPerVisit * count * 4.3).toStringAsFixed(0);

    final nudge = SmartNudge(
      id: '',
      userId: userId,
      type: NudgeType.savingsOpportunity,
      priority: NudgePriority.low,
      title: '$merchant Alert',
      message:
          '$count visits this week (\$${total.toStringAsFixed(2)}). Reducing by half could save \$$monthlySavings/month.',
      data: {
        'merchant': merchant,
        'count': count,
        'total': total,
        'potentialSavings': monthlySavings,
      },
      triggeredBy: NudgeTrigger(
        transactionId: transaction.id,
        pattern: 'frequent_merchant_visits',
      ),
      action: NudgeAction(
        label: 'View Transactions',
        type: NudgeActionType.viewTransactions,
      ),
      status: NudgeStatus.active,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    // Save to Firestore
    await _firestore.collection('smart_nudges').add(nudge.toFirestore());

    // Send push notification
    await _notificationService.showGeneral(
      id: nudge.hashCode,
      title: nudge.title,
      body: nudge.message,
      payload: {'nudgeType': 'savings_opportunity'},
    );
  }

  /// Get active nudges for a user
  Future<List<SmartNudge>> getActiveNudges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('smart_nudges')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('generatedAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => SmartNudge.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting active nudges: $e');
      return [];
    }
  }

  /// Dismiss a nudge
  Future<void> dismissNudge(String nudgeId) async {
    await _firestore.collection('smart_nudges').doc(nudgeId).update({
      'status': NudgeStatus.dismissed.name,
      'dismissedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===== HELPER METHODS =====

  /// Get active budgets
  Future<List<Budget>> _getActiveBudgets(String userId) async {
    final snapshot = await _firestore
        .collection('budgets')
        .where('user_id', isEqualTo: userId)
        .where('period.start', isLessThanOrEqualTo: Timestamp.now())
        .where('period.end', isGreaterThanOrEqualTo: Timestamp.now())
        .get();

    return snapshot.docs.map((doc) => Budget.fromFirestore(doc)).toList();
  }

  /// Get category spending for a period
  Future<double> _getCategorySpending(
    String userId,
    String category,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.fold<double>(0.0, (sum, doc) {
      final data = doc.data();
      return sum + (data['amount'] as num).toDouble();
    });
  }

  /// Get transactions for a period
  Future<List<models.Transaction>> _getTransactions(
    String userId,
    DateTime start,
    DateTime end, {
    String? category,
  }) async {
    var query = _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => models.Transaction.fromFirestore(doc))
        .toList();
  }

  /// Check if a recent nudge of the same type exists
  Future<bool> _hasRecentNudge(
    String userId,
    NudgeType type, {
    required int hours,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));

    final snapshot = await _firestore
        .collection('smart_nudges')
        .where('user_id', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .where('generatedAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}

*/ // END OF TIER 2 DISABLED CODE - Smart Nudge Service
