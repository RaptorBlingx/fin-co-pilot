// Memory models for the long-term user memory system.
// Stored in Firestore under `/users/{uid}/memory/`.

class SpendingPatterns {
  final Map<String, List<String>> topMerchantsByCategory;
  final Map<String, double> weeklyRhythm; // Mon-Sun avg
  final double avgTransactionSize;
  final String? peakSpendingDay;
  final String? peakSpendingTime;
  final DateTime? lastUpdated;
  final int transactionsSinceUpdate;

  SpendingPatterns({
    this.topMerchantsByCategory = const {},
    this.weeklyRhythm = const {},
    this.avgTransactionSize = 0,
    this.peakSpendingDay,
    this.peakSpendingTime,
    this.lastUpdated,
    this.transactionsSinceUpdate = 0,
  });

  Map<String, dynamic> toFirestore() => {
    'top_merchants_by_category': topMerchantsByCategory,
    'weekly_rhythm': weeklyRhythm,
    'avg_transaction_size': avgTransactionSize,
    'peak_spending_day': peakSpendingDay,
    'peak_spending_time': peakSpendingTime,
    'last_updated': lastUpdated?.toIso8601String(),
    'transactions_since_update': transactionsSinceUpdate,
  };

  factory SpendingPatterns.fromFirestore(Map<String, dynamic> data) {
    return SpendingPatterns(
      topMerchantsByCategory: (data['top_merchants_by_category'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ) ?? {},
      weeklyRhythm: (data['weekly_rhythm'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ) ?? {},
      avgTransactionSize: (data['avg_transaction_size'] as num?)?.toDouble() ?? 0,
      peakSpendingDay: data['peak_spending_day'] as String?,
      peakSpendingTime: data['peak_spending_time'] as String?,
      lastUpdated: data['last_updated'] != null ? DateTime.tryParse(data['last_updated']) : null,
      transactionsSinceUpdate: data['transactions_since_update'] as int? ?? 0,
    );
  }
}

class UserPreferences {
  final List<String> vocabularyPhrases;
  final List<String> frequentPeople;
  final List<String> preferredMerchants;
  final Map<String, List<String>> categoryCombos;
  final Map<String, List<double>> typicalAmountRanges;
  final DateTime? lastUpdated;
  final int transactionsSinceUpdate;

  UserPreferences({
    this.vocabularyPhrases = const [],
    this.frequentPeople = const [],
    this.preferredMerchants = const [],
    this.categoryCombos = const {},
    this.typicalAmountRanges = const {},
    this.lastUpdated,
    this.transactionsSinceUpdate = 0,
  });

  Map<String, dynamic> toFirestore() => {
    'vocabulary_phrases': vocabularyPhrases,
    'frequent_people': frequentPeople,
    'preferred_merchants': preferredMerchants,
    'category_combos': categoryCombos,
    'typical_amount_ranges': typicalAmountRanges,
    'last_updated': lastUpdated?.toIso8601String(),
    'transactions_since_update': transactionsSinceUpdate,
  };

  factory UserPreferences.fromFirestore(Map<String, dynamic> data) {
    return UserPreferences(
      vocabularyPhrases: List<String>.from(data['vocabulary_phrases'] ?? []),
      frequentPeople: List<String>.from(data['frequent_people'] ?? []),
      preferredMerchants: List<String>.from(data['preferred_merchants'] ?? []),
      categoryCombos: (data['category_combos'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ) ?? {},
      typicalAmountRanges: (data['typical_amount_ranges'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<double>.from((v as List).map((e) => (e as num).toDouble()))),
      ) ?? {},
      lastUpdated: data['last_updated'] != null ? DateTime.tryParse(data['last_updated']) : null,
      transactionsSinceUpdate: data['transactions_since_update'] as int? ?? 0,
    );
  }
}

class FinancialGoal {
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String status; // active, completed, paused

  FinancialGoal({
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.status = 'active',
  });

  double get progressPercent => targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  Map<String, dynamic> toMap() => {
    'name': name,
    'target_amount': targetAmount,
    'current_amount': currentAmount,
    'deadline': deadline?.toIso8601String(),
    'status': status,
  };

  factory FinancialGoal.fromMap(Map<String, dynamic> data) {
    return FinancialGoal(
      name: data['name'] ?? '',
      targetAmount: (data['target_amount'] as num?)?.toDouble() ?? 0,
      currentAmount: (data['current_amount'] as num?)?.toDouble() ?? 0,
      deadline: data['deadline'] != null ? DateTime.tryParse(data['deadline']) : null,
      status: data['status'] ?? 'active',
    );
  }
}

class FinancialGoals {
  final List<FinancialGoal> goals;
  final List<String> milestones;
  final DateTime? lastUpdated;

  FinancialGoals({
    this.goals = const [],
    this.milestones = const [],
    this.lastUpdated,
  });

  Map<String, dynamic> toFirestore() => {
    'goals': goals.map((g) => g.toMap()).toList(),
    'milestones': milestones,
    'last_updated': lastUpdated?.toIso8601String(),
  };

  factory FinancialGoals.fromFirestore(Map<String, dynamic> data) {
    return FinancialGoals(
      goals: (data['goals'] as List?)?.map((g) => FinancialGoal.fromMap(g)).toList() ?? [],
      milestones: List<String>.from(data['milestones'] ?? []),
      lastUpdated: data['last_updated'] != null ? DateTime.tryParse(data['last_updated']) : null,
    );
  }
}

class BehaviorProfile {
  final Map<String, int> typicalTxTimes; // hour -> count
  final double impulseVsPlannedRatio;
  final double weekendVsWeekdayRatio;
  final double averageContextRichness;
  final int streakDays;
  final int totalTransactions;
  final DateTime? lastTransactionDate;
  final DateTime? lastUpdated;

  BehaviorProfile({
    this.typicalTxTimes = const {},
    this.impulseVsPlannedRatio = 0.5,
    this.weekendVsWeekdayRatio = 0.3,
    this.averageContextRichness = 0,
    this.streakDays = 0,
    this.totalTransactions = 0,
    this.lastTransactionDate,
    this.lastUpdated,
  });

  Map<String, dynamic> toFirestore() => {
    'typical_tx_times': typicalTxTimes.map((k, v) => MapEntry(k, v)),
    'impulse_vs_planned_ratio': impulseVsPlannedRatio,
    'weekend_vs_weekday_ratio': weekendVsWeekdayRatio,
    'average_context_richness': averageContextRichness,
    'streak_days': streakDays,
    'total_transactions': totalTransactions,
    'last_transaction_date': lastTransactionDate?.toIso8601String(),
    'last_updated': lastUpdated?.toIso8601String(),
  };

  factory BehaviorProfile.fromFirestore(Map<String, dynamic> data) {
    return BehaviorProfile(
      typicalTxTimes: (data['typical_tx_times'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as int),
      ) ?? {},
      impulseVsPlannedRatio: (data['impulse_vs_planned_ratio'] as num?)?.toDouble() ?? 0.5,
      weekendVsWeekdayRatio: (data['weekend_vs_weekday_ratio'] as num?)?.toDouble() ?? 0.3,
      averageContextRichness: (data['average_context_richness'] as num?)?.toDouble() ?? 0,
      streakDays: data['streak_days'] as int? ?? 0,
      totalTransactions: data['total_transactions'] as int? ?? 0,
      lastTransactionDate: data['last_transaction_date'] != null
          ? DateTime.tryParse(data['last_transaction_date'])
          : null,
      lastUpdated: data['last_updated'] != null ? DateTime.tryParse(data['last_updated']) : null,
    );
  }
}

class LifeContextMention {
  final String topic;
  final int frequency;
  final DateTime? lastSeen;

  LifeContextMention({
    required this.topic,
    this.frequency = 1,
    this.lastSeen,
  });

  Map<String, dynamic> toMap() => {
    'topic': topic,
    'frequency': frequency,
    'last_seen': lastSeen?.toIso8601String(),
  };

  factory LifeContextMention.fromMap(Map<String, dynamic> data) {
    return LifeContextMention(
      topic: data['topic'] ?? '',
      frequency: data['frequency'] as int? ?? 1,
      lastSeen: data['last_seen'] != null ? DateTime.tryParse(data['last_seen']) : null,
    );
  }
}

class KnownRecurring {
  final String merchant;
  final String frequency; // weekly, monthly, etc.
  final double avgAmount;

  KnownRecurring({
    required this.merchant,
    this.frequency = 'monthly',
    this.avgAmount = 0,
  });

  Map<String, dynamic> toMap() => {
    'merchant': merchant,
    'frequency': frequency,
    'avg_amount': avgAmount,
  };

  factory KnownRecurring.fromMap(Map<String, dynamic> data) {
    return KnownRecurring(
      merchant: data['merchant'] ?? '',
      frequency: data['frequency'] ?? 'monthly',
      avgAmount: (data['avg_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LifeContext {
  final List<LifeContextMention> mentions;
  final List<KnownRecurring> knownRecurring;
  final List<String> lifeEvents;
  final DateTime? lastUpdated;

  LifeContext({
    this.mentions = const [],
    this.knownRecurring = const [],
    this.lifeEvents = const [],
    this.lastUpdated,
  });

  Map<String, dynamic> toFirestore() => {
    'mentions': mentions.map((m) => m.toMap()).toList(),
    'known_recurring': knownRecurring.map((r) => r.toMap()).toList(),
    'life_events': lifeEvents,
    'last_updated': lastUpdated?.toIso8601String(),
  };

  factory LifeContext.fromFirestore(Map<String, dynamic> data) {
    return LifeContext(
      mentions: (data['mentions'] as List?)?.map((m) => LifeContextMention.fromMap(m)).toList() ?? [],
      knownRecurring: (data['known_recurring'] as List?)?.map((r) => KnownRecurring.fromMap(r)).toList() ?? [],
      lifeEvents: List<String>.from(data['life_events'] ?? []),
      lastUpdated: data['last_updated'] != null ? DateTime.tryParse(data['last_updated']) : null,
    );
  }
}

class ConversationSummary {
  final DateTime date;
  final List<String> keyTopics;
  final List<String> decisions;
  final List<String> openQuestions;

  ConversationSummary({
    required this.date,
    this.keyTopics = const [],
    this.decisions = const [],
    this.openQuestions = const [],
  });

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'key_topics': keyTopics,
    'decisions': decisions,
    'open_questions': openQuestions,
  };

  factory ConversationSummary.fromMap(Map<String, dynamic> data) {
    return ConversationSummary(
      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      keyTopics: List<String>.from(data['key_topics'] ?? []),
      decisions: List<String>.from(data['decisions'] ?? []),
      openQuestions: List<String>.from(data['open_questions'] ?? []),
    );
  }
}

class ConversationSummaries {
  final List<ConversationSummary> summaries;

  ConversationSummaries({this.summaries = const []});

  Map<String, dynamic> toFirestore() => {
    'summaries': summaries.map((s) => s.toMap()).toList(),
  };

  factory ConversationSummaries.fromFirestore(Map<String, dynamic> data) {
    return ConversationSummaries(
      summaries: (data['summaries'] as List?)
          ?.map((s) => ConversationSummary.fromMap(s))
          .toList() ?? [],
    );
  }
}
