/// Rich user context assembled by UserContextBuilder.
/// Injected into every agent's system instruction for personalized responses.
class UserContext {
  final String userId;
  final String? displayName;
  final String primaryCurrency;
  final String primaryLanguage;
  final String? country;
  final String subscriptionTier; // 'free' | 'pro'
  final int accountAgeDays;

  // Temporal context
  final String timeOfDay; // 'morning' | 'afternoon' | 'evening' | 'night'
  final String dayOfWeek; // 'Monday' .. 'Sunday'
  final String monthPosition; // 'start' | 'mid' | 'end'
  final String timezone;

  // Budget context
  final double? budgetAmount;
  final double? budgetSpent;
  final double? budgetUtilization; // 0.0 - 1.0+
  final int? budgetDaysRemaining;

  // Spending snapshot
  final double monthTotal;
  final double lastMonthTotal;
  final double monthDelta; // percentage change
  final List<CategorySnapshot> topCategories;
  final List<String> recentMerchants;

  // Memory (Phase 3)
  final String? memoryDossier;

  // Conversation memory (Phase 4)
  final String? conversationHistory;

  const UserContext({
    required this.userId,
    this.displayName,
    this.primaryCurrency = 'USD',
    this.primaryLanguage = 'en',
    this.country,
    this.subscriptionTier = 'free',
    this.accountAgeDays = 0,
    this.timeOfDay = 'morning',
    this.dayOfWeek = 'Monday',
    this.monthPosition = 'start',
    this.timezone = 'UTC',
    this.budgetAmount,
    this.budgetSpent,
    this.budgetUtilization,
    this.budgetDaysRemaining,
    this.monthTotal = 0,
    this.lastMonthTotal = 0,
    this.monthDelta = 0,
    this.topCategories = const [],
    this.recentMerchants = const [],
    this.memoryDossier,
    this.conversationHistory,
  });

  /// Currency symbol for display purposes.
  String get currencySymbol {
    switch (primaryCurrency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'CAD':
        return 'CA\$';
      case 'AUD':
        return 'A\$';
      case 'TRY':
        return '₺';
      case 'JPY':
        return '¥';
      case 'INR':
        return '₹';
      case 'CHF':
        return 'CHF';
      case 'SEK':
      case 'NOK':
      case 'DKK':
        return 'kr';
      default:
        return primaryCurrency;
    }
  }

  bool get hasBudget => budgetAmount != null && budgetAmount! > 0;

  bool get hasSpendingHistory => monthTotal > 0 || lastMonthTotal > 0;

  /// Convert to a simple map (for legacy compatibility with existing code).
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'primaryCurrency': primaryCurrency,
      'primaryLanguage': primaryLanguage,
      'country': country,
      'subscriptionTier': subscriptionTier,
      'accountAgeDays': accountAgeDays,
      'timeOfDay': timeOfDay,
      'dayOfWeek': dayOfWeek,
      'monthPosition': monthPosition,
      'hasBudget': hasBudget,
      'budgetAmount': budgetAmount,
      'budgetSpent': budgetSpent,
      'budgetUtilization': budgetUtilization,
      'monthTotal': monthTotal,
      'lastMonthTotal': lastMonthTotal,
      'transactionCount': topCategories.fold<int>(0, (sum, c) => sum + c.txCount),
    };
  }
}

/// Snapshot of spending in a single category.
class CategorySnapshot {
  final String name;
  final double amount;
  final int txCount;

  const CategorySnapshot({
    required this.name,
    required this.amount,
    required this.txCount,
  });
}
