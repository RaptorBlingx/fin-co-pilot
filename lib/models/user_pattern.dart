import 'package:cloud_firestore/cloud_firestore.dart';

/// ML-generated spending patterns (Pattern Learner Agent)
///
/// Per DATA_MODELS.md specification:
/// Analyzes user transaction history to identify patterns, trends, and anomalies.
/// Used for personalized insights and proactive recommendations.
///
/// Features:
/// - Category-based spending analysis
/// - Budget adherence tracking
/// - Emotional spending patterns (NEW v3)
/// - Anomaly detection
/// - Read-only for users (Cloud Functions write)
/// - Document ID is the userId
class UserPattern {
  /// User ID (also the document ID)
  final String userId;
  final DateTime updatedAt;

  /// Spending patterns by category
  final Map<String, CategorySpendingPattern> spendingPatterns;

  /// Budget adherence trends
  final BudgetTrends budgetTrends;

  /// NEW v3: Emotional spending patterns
  final EmotionalPatterns? emotionalPatterns;

  /// Detected anomalies
  final List<SpendingAnomaly> anomalies;

  UserPattern({
    required this.userId,
    required this.updatedAt,
    required this.spendingPatterns,
    required this.budgetTrends,
    this.emotionalPatterns,
    required this.anomalies,
  });

  /// Create from Firestore document
  factory UserPattern.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse spending patterns map
    final patternsData = data['spendingPatterns'] as Map<String, dynamic>;
    final patterns = patternsData.map(
      (category, patternData) => MapEntry(
        category,
        CategorySpendingPattern.fromMap(
            patternData as Map<String, dynamic>),
      ),
    );

    // Parse anomalies array
    final anomaliesData = data['anomalies'] as List<dynamic>? ?? [];
    final anomalies = anomaliesData
        .map((a) => SpendingAnomaly.fromMap(a as Map<String, dynamic>))
        .toList();

    return UserPattern(
      userId: doc.id,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      spendingPatterns: patterns,
      budgetTrends:
          BudgetTrends.fromMap(data['budgetTrends'] as Map<String, dynamic>),
      emotionalPatterns: data['emotionalPatterns'] != null
          ? EmotionalPatterns.fromMap(
              data['emotionalPatterns'] as Map<String, dynamic>)
          : null,
      anomalies: anomalies,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'updatedAt': Timestamp.fromDate(updatedAt),
      'spendingPatterns': spendingPatterns
          .map((category, pattern) => MapEntry(category, pattern.toMap())),
      'budgetTrends': budgetTrends.toMap(),
      'emotionalPatterns': emotionalPatterns?.toMap(),
      'anomalies': anomalies.map((a) => a.toMap()).toList(),
    };
  }

  /// Get high-priority anomalies (severity >= 0.7)
  List<SpendingAnomaly> get highPriorityAnomalies =>
      anomalies.where((a) => a.severity >= 0.7).toList();

  /// Get recent anomalies (last 30 days)
  List<SpendingAnomaly> get recentAnomalies {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return anomalies.where((a) => a.detectedAt.isAfter(thirtyDaysAgo)).toList();
  }

  /// Check if user has emotional spending patterns
  bool get hasEmotionalSpending =>
      emotionalPatterns != null &&
      emotionalPatterns!.stressSpendingTriggers.isNotEmpty;
}

/// Spending pattern for a specific category
class CategorySpendingPattern {
  /// Average transaction amount
  final double avgAmount;

  /// Transactions per month
  final double frequency;

  /// Most common merchants
  final List<String> commonMerchants;

  /// Peak days of week (0 = Sunday, 6 = Saturday)
  final List<int> peakDays;

  /// Peak hours (0-23)
  final List<int> peakTimes;

  /// Trend: increasing, stable, decreasing
  final SpendingTrend trend;

  CategorySpendingPattern({
    required this.avgAmount,
    required this.frequency,
    required this.commonMerchants,
    required this.peakDays,
    required this.peakTimes,
    required this.trend,
  });

  factory CategorySpendingPattern.fromMap(Map<String, dynamic> map) {
    return CategorySpendingPattern(
      avgAmount: (map['avgAmount'] as num).toDouble(),
      frequency: (map['frequency'] as num).toDouble(),
      commonMerchants: List<String>.from(map['commonMerchants'] ?? []),
      peakDays: List<int>.from(map['peakDays'] ?? []),
      peakTimes: List<int>.from(map['peakTimes'] ?? []),
      trend: SpendingTrend.values.byName(map['trend'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'avgAmount': avgAmount,
      'frequency': frequency,
      'commonMerchants': commonMerchants,
      'peakDays': peakDays,
      'peakTimes': peakTimes,
      'trend': trend.name,
    };
  }

  /// Get most common merchant
  String? get topMerchant =>
      commonMerchants.isNotEmpty ? commonMerchants.first : null;

  /// Get peak day name
  String? get peakDayName {
    if (peakDays.isEmpty) return null;
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[peakDays.first];
  }
}

/// Budget adherence trends
class BudgetTrends {
  /// Budget adherence rate: 0-100
  final double adherenceRate;

  /// Categories where user overspends
  final List<String> overSpendCategories;

  /// Average monthly spending
  final double avgMonthlySpend;

  /// Estimated monthly income (optional)
  final double? monthlyIncomeEstimate;

  BudgetTrends({
    required this.adherenceRate,
    required this.overSpendCategories,
    required this.avgMonthlySpend,
    this.monthlyIncomeEstimate,
  });

  factory BudgetTrends.fromMap(Map<String, dynamic> map) {
    return BudgetTrends(
      adherenceRate: (map['adherenceRate'] as num).toDouble(),
      overSpendCategories: List<String>.from(map['overSpendCategories'] ?? []),
      avgMonthlySpend: (map['avgMonthlySpend'] as num).toDouble(),
      monthlyIncomeEstimate: map['monthlyIncomeEstimate'] != null
          ? (map['monthlyIncomeEstimate'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adherenceRate': adherenceRate,
      'overSpendCategories': overSpendCategories,
      'avgMonthlySpend': avgMonthlySpend,
      'monthlyIncomeEstimate': monthlyIncomeEstimate,
    };
  }

  /// Check if adherence is good (>= 80%)
  bool get isGoodAdherence => adherenceRate >= 80;

  /// Check if adherence is poor (< 60%)
  bool get isPoorAdherence => adherenceRate < 60;
}

/// NEW v3: Emotional spending patterns
class EmotionalPatterns {
  /// Triggers that lead to stress spending
  final List<String> stressSpendingTriggers;

  /// Categories prone to impulse purchases
  final List<String> impulseCategories;

  /// Average amount spent during stress periods
  final double avgStressSpend;

  EmotionalPatterns({
    required this.stressSpendingTriggers,
    required this.impulseCategories,
    required this.avgStressSpend,
  });

  factory EmotionalPatterns.fromMap(Map<String, dynamic> map) {
    return EmotionalPatterns(
      stressSpendingTriggers:
          List<String>.from(map['stressSpendingTriggers'] ?? []),
      impulseCategories: List<String>.from(map['impulseCategories'] ?? []),
      avgStressSpend: (map['avgStressSpend'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stressSpendingTriggers': stressSpendingTriggers,
      'impulseCategories': impulseCategories,
      'avgStressSpend': avgStressSpend,
    };
  }

  /// Get primary stress trigger
  String? get primaryTrigger => stressSpendingTriggers.isNotEmpty
      ? stressSpendingTriggers.first
      : null;

  /// Get primary impulse category
  String? get primaryImpulseCategory =>
      impulseCategories.isNotEmpty ? impulseCategories.first : null;
}

/// Detected spending anomaly
class SpendingAnomaly {
  final String transactionId;

  /// Anomaly type: "large_purchase", "unusual_time", "unusual_merchant", etc.
  final String type;

  /// Severity: 0-1 (0 = minor, 1 = critical)
  final double severity;

  final DateTime detectedAt;

  SpendingAnomaly({
    required this.transactionId,
    required this.type,
    required this.severity,
    required this.detectedAt,
  }) : assert(severity >= 0 && severity <= 1, 'Severity must be 0-1');

  factory SpendingAnomaly.fromMap(Map<String, dynamic> map) {
    return SpendingAnomaly(
      transactionId: map['transactionId'] as String,
      type: map['type'] as String,
      severity: (map['severity'] as num).toDouble(),
      detectedAt: (map['detectedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'type': type,
      'severity': severity,
      'detectedAt': Timestamp.fromDate(detectedAt),
    };
  }

  /// Check if high severity (>= 0.7)
  bool get isHighSeverity => severity >= 0.7;

  /// Check if medium severity (0.4-0.7)
  bool get isMediumSeverity => severity >= 0.4 && severity < 0.7;

  /// Check if low severity (< 0.4)
  bool get isLowSeverity => severity < 0.4;
}

/// Spending trend enum
enum SpendingTrend {
  increasing,
  stable,
  decreasing,
}
