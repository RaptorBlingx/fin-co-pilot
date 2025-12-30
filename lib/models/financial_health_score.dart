import 'package:cloud_firestore/cloud_firestore.dart';

/// Financial Health Score Model (NEW in v3)
///
/// Per Knowledge Base: DATA_MODELS.md - financial_health_scores collection
/// Historical 0-100 score tracking (Week 3 feature)
class FinancialHealthScore {
  final String id;
  final String userId;
  final DateTime calculatedAt;
  final int score;
  final ScoreBreakdown breakdown;
  final ScoreFactors factors;
  final ScoreTrend trend;
  final int? previousScore;

  FinancialHealthScore({
    required this.id,
    required this.userId,
    required this.calculatedAt,
    required this.score,
    required this.breakdown,
    required this.factors,
    required this.trend,
    this.previousScore,
  });

  factory FinancialHealthScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FinancialHealthScore(
      id: doc.id,
      userId: data['user_id'] as String? ?? data['userId'] as String,
      calculatedAt: (data['calculatedAt'] as Timestamp).toDate(),
      score: data['score'] as int,
      breakdown: ScoreBreakdown.fromMap(
          data['breakdown'] as Map<String, dynamic>),
      factors:
          ScoreFactors.fromMap(data['factors'] as Map<String, dynamic>),
      trend: ScoreTrend.values.byName(data['trend'] as String),
      previousScore: data['previousScore'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'calculatedAt': Timestamp.fromDate(calculatedAt),
      'score': score,
      'breakdown': breakdown.toMap(),
      'factors': factors.toMap(),
      'trend': trend.name,
      'previousScore': previousScore,
    };
  }

  /// Get score change from previous
  int? get scoreChange {
    if (previousScore == null) return null;
    return score - previousScore!;
  }

  /// Get score grade (A-F)
  String get grade {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  /// Get status message
  String get statusMessage {
    if (score >= 80) return 'Excellent financial health!';
    if (score >= 70) return 'Good progress, keep it up!';
    if (score >= 60) return 'You\'re building momentum!';
    return 'Let\'s work on improving together!';
  }
}

/// Score breakdown (per Knowledge Base: 4 components, 25 points each)
class ScoreBreakdown {
  final int budgetAdherence;      // 0-25
  final int savingsRate;          // 0-25
  final int debtManagement;       // 0-25
  final int spendingStability;    // 0-25

  ScoreBreakdown({
    required this.budgetAdherence,
    required this.savingsRate,
    required this.debtManagement,
    required this.spendingStability,
  });

  factory ScoreBreakdown.fromMap(Map<String, dynamic> map) {
    return ScoreBreakdown(
      budgetAdherence: map['budgetAdherence'] as int,
      savingsRate: map['savingsRate'] as int,
      debtManagement: map['debtManagement'] as int,
      spendingStability: map['spendingStability'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'budgetAdherence': budgetAdherence,
      'savingsRate': savingsRate,
      'debtManagement': debtManagement,
      'spendingStability': spendingStability,
    };
  }

  /// Calculate total score
  int get total =>
      budgetAdherence + savingsRate + debtManagement + spendingStability;
}

class ScoreFactors {
  final List<String> positives;
  final List<String> negatives;
  final List<String> recommendations;

  ScoreFactors({
    required this.positives,
    required this.negatives,
    required this.recommendations,
  });

  factory ScoreFactors.fromMap(Map<String, dynamic> map) {
    return ScoreFactors(
      positives: List<String>.from(map['positives'] ?? []),
      negatives: List<String>.from(map['negatives'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'positives': positives,
      'negatives': negatives,
      'recommendations': recommendations,
    };
  }
}

enum ScoreTrend {
  improving,
  stable,
  declining,
}
