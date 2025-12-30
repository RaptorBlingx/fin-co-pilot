import 'package:cloud_firestore/cloud_firestore.dart';

/// Contextual coaching tips library
///
/// Per DATA_MODELS.md specification:
/// Pre-written coaching tips shown in contextual moments.
/// Triggered by specific user behaviors or patterns.
///
/// Features:
/// - Category-based organization
/// - Trigger-based activation
/// - User effectiveness ratings
/// - Usage tracking
/// - Read-only for users (admin creates)
/// - Supports Week 5: Emotional Spending + Coaching Tips
class CoachingTip {
  final String id;

  /// Category: "budgeting", "impulse", "savings", "debt", "stress", etc.
  final String category;

  /// Trigger condition: "over_budget", "impulse_spending", "high_stress", etc.
  final String trigger;

  /// Short actionable advice (1-2 sentences)
  final String tip;

  /// Detailed explanation (optional, 2-3 paragraphs)
  final String? longForm;

  /// Tags for filtering/search
  final List<String> tags;

  /// User effectiveness rating: 0-5 (aggregated from user feedback)
  final double? effectiveness;

  /// How many times this tip has been shown to users
  final int usageCount;

  final DateTime createdAt;

  CoachingTip({
    required this.id,
    required this.category,
    required this.trigger,
    required this.tip,
    this.longForm,
    required this.tags,
    this.effectiveness,
    required this.usageCount,
    required this.createdAt,
  }) : assert(
            effectiveness == null || (effectiveness >= 0 && effectiveness <= 5),
            'Effectiveness must be 0-5');

  /// Create from Firestore document
  factory CoachingTip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoachingTip(
      id: doc.id,
      category: data['category'] as String,
      trigger: data['trigger'] as String,
      tip: data['tip'] as String,
      longForm: data['longForm'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
      effectiveness: data['effectiveness'] != null
          ? (data['effectiveness'] as num).toDouble()
          : null,
      usageCount: data['usageCount'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'trigger': trigger,
      'tip': tip,
      'longForm': longForm,
      'tags': tags,
      'effectiveness': effectiveness,
      'usageCount': usageCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Check if tip is highly rated (4.0+)
  bool get isHighlyRated => effectiveness != null && effectiveness! >= 4.0;

  /// Check if tip is well-tested (shown 10+ times)
  bool get isWellTested => usageCount >= 10;

  /// Check if tip is proven effective (highly rated AND well-tested)
  bool get isProvenEffective => isHighlyRated && isWellTested;

  /// Get effectiveness rating as stars (e.g., "⭐⭐⭐⭐")
  String get effectivenessStars {
    if (effectiveness == null) return 'Not rated';
    final stars = '⭐' * effectiveness!.round();
    return stars.isEmpty ? 'Not rated' : stars;
  }

  /// Copy with updated usage count
  CoachingTip incrementUsage() {
    return CoachingTip(
      id: id,
      category: category,
      trigger: trigger,
      tip: tip,
      longForm: longForm,
      tags: tags,
      effectiveness: effectiveness,
      usageCount: usageCount + 1,
      createdAt: createdAt,
    );
  }

  /// Copy with updated effectiveness rating
  CoachingTip updateEffectiveness(double newRating) {
    assert(newRating >= 0 && newRating <= 5, 'Rating must be 0-5');
    return CoachingTip(
      id: id,
      category: category,
      trigger: trigger,
      tip: tip,
      longForm: longForm,
      tags: tags,
      effectiveness: newRating,
      usageCount: usageCount,
      createdAt: createdAt,
    );
  }
}

/// Common coaching tip categories
class CoachingCategory {
  static const String budgeting = 'budgeting';
  static const String impulse = 'impulse';
  static const String savings = 'savings';
  static const String debt = 'debt';
  static const String stress = 'stress';
  static const String planning = 'planning';
  static const String habits = 'habits';
}

/// Common coaching tip triggers
class CoachingTrigger {
  static const String overBudget = 'over_budget';
  static const String impulseSpending = 'impulse_spending';
  static const String highStress = 'high_stress';
  static const String lowSavings = 'low_savings';
  static const String missedBill = 'missed_bill';
  static const String largePurchase = 'large_purchase';
  static const String frequentSmallSpends = 'frequent_small_spends';
  static const String budgetStreak = 'budget_streak';
  static const String savingsMilestone = 'savings_milestone';
}
