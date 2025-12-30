import 'package:cloud_firestore/cloud_firestore.dart';

/// Budget model
///
/// Per DATA_MODELS.md specification:
/// Tracks spending budgets (monthly, weekly, custom periods).
/// Supports overall budget and per-category allocations.
///
/// Features:
/// - Multiple budget types (monthly, weekly, custom)
/// - Category-based budgeting
/// - Auto-calculated spent/remaining amounts
/// - Alert thresholds (75%, 90%, 100%)
/// - Recurring budget support
class Budget {
  final String id;
  final String userId;
  final String name;
  final BudgetType type;

  final double amount;
  final String currency;

  /// Budget period
  final BudgetPeriod period;

  /// Per-category budget allocations (optional)
  final Map<String, CategoryBudget>? categories;

  /// Total spent (calculated field)
  final double totalSpent;

  /// Alert settings
  final BudgetAlerts alerts;

  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.amount,
    required this.currency,
    required this.period,
    this.categories,
    required this.totalSpent,
    required this.alerts,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse categories map (optional)
    Map<String, CategoryBudget>? categories;
    if (data['categories'] != null) {
      final categoriesData = data['categories'] as Map<String, dynamic>;
      categories = categoriesData.map(
        (category, budgetData) => MapEntry(
          category,
          CategoryBudget.fromMap(budgetData as Map<String, dynamic>),
        ),
      );
    }

    return Budget(
      id: doc.id,
      userId: (data['user_id'] ?? data['userId']) as String,
      name: data['name'] as String,
      type: BudgetType.values.byName(data['type'] as String),
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String,
      period: BudgetPeriod.fromMap(data['period'] as Map<String, dynamic>),
      categories: categories,
      totalSpent: (data['totalSpent'] as num).toDouble(),
      alerts: BudgetAlerts.fromMap(data['alerts'] as Map<String, dynamic>),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'period': period.toMap(),
      'categories':
          categories?.map((category, budget) => MapEntry(category, budget.toMap())),
      'totalSpent': totalSpent,
      'alerts': alerts.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get remaining budget
  double get remaining => amount - totalSpent;

  /// Get percentage spent (0-100)
  double get percentageSpent => (totalSpent / amount * 100).clamp(0, 999);

  /// Check if budget is exceeded
  bool get isExceeded => totalSpent > amount;

  /// Check if budget is at threshold
  bool isAtThreshold(int threshold) => percentageSpent >= threshold;

  /// Check if budget is active (within period)
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(period.start) && now.isBefore(period.end);
  }

  /// Check if budget is expired
  bool get isExpired => DateTime.now().isAfter(period.end);

  /// Get days remaining in budget period
  int get daysRemaining {
    if (isExpired) return 0;
    return period.end.difference(DateTime.now()).inDays;
  }

  /// Get budget status message
  String get statusMessage {
    if (isExceeded) {
      return 'Over budget by \$${(totalSpent - amount).toStringAsFixed(2)}';
    } else if (percentageSpent >= 90) {
      return '${percentageSpent.toStringAsFixed(0)}% spent - Almost at limit!';
    } else if (percentageSpent >= 75) {
      return '${percentageSpent.toStringAsFixed(0)}% spent - Getting close';
    } else {
      return '\$${remaining.toStringAsFixed(2)} remaining';
    }
  }
}

/// Budget period
class BudgetPeriod {
  final DateTime start;
  final DateTime end;
  final bool recurring;

  BudgetPeriod({
    required this.start,
    required this.end,
    required this.recurring,
  });

  factory BudgetPeriod.fromMap(Map<String, dynamic> map) {
    return BudgetPeriod(
      start: (map['start'] as Timestamp).toDate(),
      end: (map['end'] as Timestamp).toDate(),
      recurring: map['recurring'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'recurring': recurring,
    };
  }

  /// Get period duration in days
  int get durationInDays => end.difference(start).inDays;
}

/// Per-category budget allocation
class CategoryBudget {
  final double budgeted;

  /// Calculated: amount spent in this category
  final double spent;

  /// Calculated: remaining budget for this category
  final double remaining;

  CategoryBudget({
    required this.budgeted,
    required this.spent,
    required this.remaining,
  });

  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    return CategoryBudget(
      budgeted: (map['budgeted'] as num).toDouble(),
      spent: (map['spent'] as num).toDouble(),
      remaining: (map['remaining'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'budgeted': budgeted,
      'spent': spent,
      'remaining': remaining,
    };
  }

  /// Get percentage spent (0-100)
  double get percentageSpent => (spent / budgeted * 100).clamp(0, 999);

  /// Check if category budget is exceeded
  bool get isExceeded => spent > budgeted;
}

/// Budget alert settings
class BudgetAlerts {
  final bool enabled;

  /// Alert thresholds (e.g., [75, 90, 100])
  final List<int> thresholds;

  /// Last alert timestamp (optional)
  final DateTime? lastAlertAt;

  BudgetAlerts({
    required this.enabled,
    required this.thresholds,
    this.lastAlertAt,
  });

  factory BudgetAlerts.fromMap(Map<String, dynamic> map) {
    return BudgetAlerts(
      enabled: map['enabled'] as bool,
      thresholds: List<int>.from(map['thresholds'] ?? [75, 90, 100]),
      lastAlertAt: map['lastAlertAt'] != null
          ? (map['lastAlertAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'thresholds': thresholds,
      'lastAlertAt':
          lastAlertAt != null ? Timestamp.fromDate(lastAlertAt!) : null,
    };
  }

  /// Get next threshold to trigger
  int? getNextThreshold(double currentPercentage) {
    if (!enabled) return null;
    for (final threshold in thresholds) {
      if (currentPercentage < threshold) return threshold;
    }
    return null;
  }
}

/// Budget type
enum BudgetType {
  monthly,
  weekly,
  custom,
}
