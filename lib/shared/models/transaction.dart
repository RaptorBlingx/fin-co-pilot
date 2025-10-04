import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String? id;
  final String userId;
  final double amount;
  final String currency;
  final String category;
  final String? subcategory;
  final String? merchant;
  final String? description;
  final String? notes;
  final String paymentMethod;
  final DateTime transactionDate;
  final DateTime createdAt;
  final String inputMethod;
  final String? receiptImageUrl;
  final Map<String, dynamic>? receiptData;
  final double? aiConfidence;

  Transaction({
    this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.category,
    this.subcategory,
    this.merchant,
    this.description,
    this.notes,
    this.paymentMethod = 'cash',
    required this.transactionDate,
    required this.createdAt,
    this.inputMethod = 'manual',
    this.receiptImageUrl,
    this.receiptData,
    this.aiConfidence,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'category': category,
      'subcategory': subcategory,
      'merchant': merchant,
      'description': description,
      'notes': notes,
      'payment_method': paymentMethod,
      'transaction_date': Timestamp.fromDate(transactionDate),
      'created_at': Timestamp.fromDate(createdAt),
      'input_method': inputMethod,
      'receipt_image_url': receiptImageUrl,
      'receipt_data': receiptData,
      'ai_confidence': aiConfidence,
    };
  }

  // Create from Firestore document
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Transaction(
      id: doc.id,
      userId: data['user_id'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      category: data['category'] ?? 'other',
      subcategory: data['subcategory'],
      merchant: data['merchant'],
      description: data['description'],
      notes: data['notes'],
      paymentMethod: data['payment_method'] ?? 'cash',
      transactionDate: (data['transaction_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      inputMethod: data['input_method'] ?? 'manual',
      receiptImageUrl: data['receipt_image_url'],
      receiptData: data['receipt_data'],
      aiConfidence: data['ai_confidence']?.toDouble(),
    );
  }

  // Copy with method for updates
  Transaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    String? category,
    String? subcategory,
    String? merchant,
    String? description,
    String? notes,
    String? paymentMethod,
    DateTime? transactionDate,
    DateTime? createdAt,
    String? inputMethod,
    String? receiptImageUrl,
    Map<String, dynamic>? receiptData,
    double? aiConfidence,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      inputMethod: inputMethod ?? this.inputMethod,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      receiptData: receiptData ?? this.receiptData,
      aiConfidence: aiConfidence ?? this.aiConfidence,
    );
  }
}