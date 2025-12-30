import 'package:cloud_firestore/cloud_firestore.dart';

/// SMS Transaction Model (NEW in v3)
///
/// Per Knowledge Base: DATA_MODELS.md - sms_transactions collection
/// SMS auto-parsing pending confirmations (Week 2 feature)
class SmsTransaction {
  final String id;
  final String userId;
  final String smsBody;
  final String sender;
  final SmsTransactionParsed parsed;
  final SmsTransactionStatus status;
  final DateTime receivedAt;
  final DateTime expiresAt;
  final DateTime? confirmedAt;
  final String? savedTransactionId;

  SmsTransaction({
    required this.id,
    required this.userId,
    required this.smsBody,
    required this.sender,
    required this.parsed,
    required this.status,
    required this.receivedAt,
    required this.expiresAt,
    this.confirmedAt,
    this.savedTransactionId,
  });

  factory SmsTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SmsTransaction(
      id: doc.id,
      userId: (data['user_id'] ?? data['userId']) as String,
      smsBody: data['smsBody'] as String,
      sender: data['sender'] as String,
      parsed: SmsTransactionParsed.fromMap(
          data['parsed'] as Map<String, dynamic>),
      status: SmsTransactionStatus.values.byName(data['status'] as String),
      receivedAt: (data['receivedAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
      savedTransactionId: data['savedTransactionId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'smsBody': smsBody,
      'sender': sender,
      'parsed': parsed.toMap(),
      'status': status.name,
      'receivedAt': Timestamp.fromDate(receivedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'confirmedAt':
          confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'savedTransactionId': savedTransactionId,
    };
  }
}

class SmsTransactionParsed {
  final double amount;
  final String merchant;
  final DateTime date;
  final String? cardLast4;
  final double confidence;
  final String suggestedCategory;

  SmsTransactionParsed({
    required this.amount,
    required this.merchant,
    required this.date,
    this.cardLast4,
    required this.confidence,
    required this.suggestedCategory,
  });

  factory SmsTransactionParsed.fromMap(Map<String, dynamic> map) {
    return SmsTransactionParsed(
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'] as String,
      date: (map['date'] as Timestamp).toDate(),
      cardLast4: map['cardLast4'] as String?,
      confidence: (map['confidence'] as num).toDouble(),
      suggestedCategory: map['suggestedCategory'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'merchant': merchant,
      'date': Timestamp.fromDate(date),
      'cardLast4': cardLast4,
      'confidence': confidence,
      'suggestedCategory': suggestedCategory,
    };
  }
}

enum SmsTransactionStatus {
  pending,
  confirmed,
  rejected,
  expired,
}
