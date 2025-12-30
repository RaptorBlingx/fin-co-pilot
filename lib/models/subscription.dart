import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription Model (NEW in v3)
///
/// Per Knowledge Base: DATA_MODELS.md - subscriptions collection
/// Detected recurring charges (Week 8 feature)
class Subscription {
  final String id;
  final String userId;
  final String merchant;
  final double amount;
  final String currency;
  final SubscriptionFrequency frequency;
  final DateTime lastCharge;
  final DateTime nextExpectedCharge;
  final DateTime detectedAt;
  final List<String> transactions;
  final SubscriptionStatus status;
  final bool userConfirmed;
  final SubscriptionMetadata metadata;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.merchant,
    required this.amount,
    required this.currency,
    required this.frequency,
    required this.lastCharge,
    required this.nextExpectedCharge,
    required this.detectedAt,
    required this.transactions,
    required this.status,
    required this.userConfirmed,
    required this.metadata,
    required this.updatedAt,
  });

  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      userId: data['user_id'] as String? ?? data['userId'] as String,
      merchant: data['merchant'] as String,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String,
      frequency: SubscriptionFrequency.values.byName(data['frequency'] as String),
      lastCharge: (data['lastCharge'] as Timestamp).toDate(),
      nextExpectedCharge: (data['nextExpectedCharge'] as Timestamp).toDate(),
      detectedAt: (data['detectedAt'] as Timestamp).toDate(),
      transactions: List<String>.from(data['transactions'] ?? []),
      status: SubscriptionStatus.values.byName(data['status'] as String),
      userConfirmed: data['userConfirmed'] as bool,
      metadata: SubscriptionMetadata.fromMap(
          data['metadata'] as Map<String, dynamic>),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'merchant': merchant,
      'amount': amount,
      'currency': currency,
      'frequency': frequency.name,
      'lastCharge': Timestamp.fromDate(lastCharge),
      'nextExpectedCharge': Timestamp.fromDate(nextExpectedCharge),
      'detectedAt': Timestamp.fromDate(detectedAt),
      'transactions': transactions,
      'status': status.name,
      'userConfirmed': userConfirmed,
      'metadata': metadata.toMap(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Calculate annual cost
  double get annualCost {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return amount * 52;
      case SubscriptionFrequency.monthly:
        return amount * 12;
      case SubscriptionFrequency.yearly:
        return amount;
    }
  }
}

class SubscriptionMetadata {
  final String? category;
  final String? cancelUrl;
  final double? savings;

  SubscriptionMetadata({
    this.category,
    this.cancelUrl,
    this.savings,
  });

  factory SubscriptionMetadata.fromMap(Map<String, dynamic> map) {
    return SubscriptionMetadata(
      category: map['category'] as String?,
      cancelUrl: map['cancelUrl'] as String?,
      savings: map['savings'] != null ? (map['savings'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'cancelUrl': cancelUrl,
      'savings': savings,
    };
  }
}

enum SubscriptionFrequency {
  weekly,
  monthly,
  yearly,
}

enum SubscriptionStatus {
  active,
  canceled,
  flagged,
}
