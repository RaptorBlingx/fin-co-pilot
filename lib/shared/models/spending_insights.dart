class SpendingInsights {
  final double totalSpent;
  final int transactionCount;
  final Map<String, double> byCategory;
  final Map<String, double> byMerchant;
  final List<DailySpending> dailySpending;
  final double averagePerDay;
  final double averagePerTransaction;
  final String topCategory;
  final String topMerchant;
  final List<String> aiInsights;

  SpendingInsights({
    required this.totalSpent,
    required this.transactionCount,
    required this.byCategory,
    required this.byMerchant,
    required this.dailySpending,
    required this.averagePerDay,
    required this.averagePerTransaction,
    required this.topCategory,
    required this.topMerchant,
    required this.aiInsights,
  });

  // Helper method to get spending trend compared to previous period
  double getTrendPercentage(SpendingInsights? previousPeriod) {
    if (previousPeriod == null || previousPeriod.totalSpent == 0) return 0;
    return ((totalSpent - previousPeriod.totalSpent) / previousPeriod.totalSpent) * 100;
  }

  // Helper method to check if spending is increasing
  bool isSpendingIncreasing(SpendingInsights? previousPeriod) {
    return getTrendPercentage(previousPeriod) > 0;
  }

  // Helper method to get formatted trend text
  String getTrendText(SpendingInsights? previousPeriod) {
    final percentage = getTrendPercentage(previousPeriod);
    if (percentage == 0) return 'No change from last month';
    
    final isIncrease = percentage > 0;
    final absPercentage = percentage.abs().toStringAsFixed(1);
    
    return '${isIncrease ? '+' : '-'}$absPercentage% vs last month';
  }

  // Helper method to get category percentages for pie chart
  Map<String, double> getCategoryPercentages() {
    if (totalSpent == 0) return {};
    
    return byCategory.map((category, amount) => 
      MapEntry(category, (amount / totalSpent) * 100));
  }

  // Helper method to get top categories (up to 5)
  List<MapEntry<String, double>> getTopCategories({int limit = 5}) {
    final sortedEntries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(limit).toList();
  }

  // Helper method to get top merchants (up to 5)
  List<MapEntry<String, double>> getTopMerchants({int limit = 5}) {
    final sortedEntries = byMerchant.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(limit).toList();
  }
}

class DailySpending {
  final DateTime date;
  final double amount;
  final int count;

  DailySpending({
    required this.date,
    required this.amount,
    required this.count,
  });

  // Helper method to format date for display
  String get formattedDate => '${date.day}/${date.month}';
  
  // Helper method to get day of week
  String get dayOfWeek {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  // Helper method to check if this is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
}