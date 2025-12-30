import 'package:cloud_firestore/cloud_firestore.dart';

/// Emotional spending tracking model
///
/// Per DATA_MODELS.md specification:
/// Tracks user stress levels (1-10) and associated spending behavior.
/// Used by Analyst Agent to identify emotional spending patterns.
///
/// Features:
/// - User-reported or AI-inferred stress levels
/// - Links transactions during stress periods
/// - AI-generated insights and coaching tips
/// - Supports Emotional Spending Detection (Week 5)
class StressLog {
  final String id;
  final String userId;
  final DateTime timestamp;

  /// Stress level: 1-10 (user reported or inferred by AI)
  final int stressLevel;

  /// Trigger category (optional): "work", "relationship", "health", etc.
  final String? trigger;

  /// Transaction IDs during stress period
  final List<String> transactions;

  /// Total amount spent during stress period
  final double totalSpent;

  /// Analyst Agent observation (optional)
  final String? aiInsight;

  /// Suggested coping mechanism (optional)
  final String? coachingTip;

  final DateTime createdAt;

  StressLog({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.stressLevel,
    this.trigger,
    required this.transactions,
    required this.totalSpent,
    this.aiInsight,
    this.coachingTip,
    required this.createdAt,
  }) : assert(stressLevel >= 1 && stressLevel <= 10, 'Stress level must be 1-10');

  /// Create from Firestore document
  factory StressLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StressLog(
      id: doc.id,
      userId: (data['user_id'] ?? data['userId']) as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      stressLevel: data['stressLevel'] as int,
      trigger: data['trigger'] as String?,
      transactions: List<String>.from(data['transactions'] ?? []),
      totalSpent: (data['totalSpent'] as num).toDouble(),
      aiInsight: data['aiInsight'] as String?,
      coachingTip: data['coachingTip'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'stressLevel': stressLevel,
      'trigger': trigger,
      'transactions': transactions,
      'totalSpent': totalSpent,
      'aiInsight': aiInsight,
      'coachingTip': coachingTip,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Check if stress level is high (7+)
  bool get isHighStress => stressLevel >= 7;

  /// Check if stress level is moderate (4-6)
  bool get isModerateStress => stressLevel >= 4 && stressLevel <= 6;

  /// Check if stress level is low (1-3)
  bool get isLowStress => stressLevel <= 3;

  /// Get stress level description
  String get stressLevelDescription {
    if (stressLevel >= 8) return 'Very High';
    if (stressLevel >= 6) return 'High';
    if (stressLevel >= 4) return 'Moderate';
    if (stressLevel >= 2) return 'Low';
    return 'Very Low';
  }

  /// Copy with new values
  StressLog copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    int? stressLevel,
    String? trigger,
    List<String>? transactions,
    double? totalSpent,
    String? aiInsight,
    String? coachingTip,
    DateTime? createdAt,
  }) {
    return StressLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      stressLevel: stressLevel ?? this.stressLevel,
      trigger: trigger ?? this.trigger,
      transactions: transactions ?? this.transactions,
      totalSpent: totalSpent ?? this.totalSpent,
      aiInsight: aiInsight ?? this.aiInsight,
      coachingTip: coachingTip ?? this.coachingTip,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
