import 'package:cloud_firestore/cloud_firestore.dart';

/// Money Story Model (NEW in v3)
///
/// Per Knowledge Base: DATA_MODELS.md - money_stories collection
/// Daily narrative summaries generated at 9 PM by Analyst Agent
class MoneyStory {
  final String id;
  final String userId;
  final DateTime date;
  final String story;
  final MoneyStoryHighlights highlights;
  final List<String> transactions;
  final DateTime generatedAt;
  final DateTime? sentAt;

  MoneyStory({
    required this.id,
    required this.userId,
    required this.date,
    required this.story,
    required this.highlights,
    required this.transactions,
    required this.generatedAt,
    this.sentAt,
  });

  factory MoneyStory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoneyStory(
      id: doc.id,
      userId: (data['user_id'] ?? data['userId']) as String,
      date: (data['date'] as Timestamp).toDate(),
      story: data['story'] as String,
      highlights: MoneyStoryHighlights.fromMap(
          data['highlights'] as Map<String, dynamic>),
      transactions: List<String>.from(data['transactions'] ?? []),
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      sentAt: data['sentAt'] != null
          ? (data['sentAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'date': Timestamp.fromDate(date),
      'story': story,
      'highlights': highlights.toMap(),
      'transactions': transactions,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
    };
  }
}

class MoneyStoryHighlights {
  final double totalSpent;
  final double totalIncome;
  final String topCategory;
  final Map<String, dynamic>? topTransaction;
  final int transactionCount;
  final String budgetStatus;

  MoneyStoryHighlights({
    required this.totalSpent,
    required this.totalIncome,
    required this.topCategory,
    this.topTransaction,
    required this.transactionCount,
    required this.budgetStatus,
  });

  factory MoneyStoryHighlights.fromMap(Map<String, dynamic> map) {
    return MoneyStoryHighlights(
      totalSpent: (map['totalSpent'] as num).toDouble(),
      totalIncome: (map['totalIncome'] as num).toDouble(),
      topCategory: map['topCategory'] as String,
      topTransaction: map['topTransaction'] as Map<String, dynamic>?,
      transactionCount: map['transactionCount'] as int,
      budgetStatus: map['budgetStatus'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSpent': totalSpent,
      'totalIncome': totalIncome,
      'topCategory': topCategory,
      'topTransaction': topTransaction,
      'transactionCount': transactionCount,
      'budgetStatus': budgetStatus,
    };
  }
}
