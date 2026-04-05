import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction type enum
enum TransactionType {
  expense,
  income,
}

/// Consolidated Transaction model
///
/// Single source of truth for all transaction data.
/// Uses snake_case Firestore field names matching the primary data layer.
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
  final List<String>? tags;

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
    this.tags,
  });

  /// Alias for transactionDate (v3 compatibility)
  DateTime get date => transactionDate;

  /// Inferred transaction type from category
  TransactionType get type =>
      category.toLowerCase() == 'income' ? TransactionType.income : TransactionType.expense;

  /// Convert to Firestore document
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
      if (tags != null && tags!.isNotEmpty) 'tags': tags,
    };
  }

  /// Create from Firestore document (supports both field naming conventions)
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Transaction(
      id: doc.id,
      userId: data['user_id'] ?? data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      category: data['category'] ?? 'other',
      subcategory: data['subcategory'],
      merchant: data['merchant'],
      description: data['description'],
      notes: data['notes'],
      paymentMethod: data['payment_method'] ?? data['paymentMethod'] ?? 'cash',
      transactionDate: _parseDate(data['transaction_date'] ?? data['date']),
      createdAt: _parseDate(data['created_at'] ?? data['createdAt']),
      inputMethod: data['input_method'] ?? data['inputMethod'] ?? 'manual',
      receiptImageUrl: data['receipt_image_url'] ?? data['receiptImageUrl'],
      receiptData: data['receipt_data'] ?? data['receiptData'],
      aiConfidence: (data['ai_confidence'] ?? data['aiConfidence'])?.toDouble(),
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
    );
  }

  /// Create from Map
  factory Transaction.fromMap(Map<String, dynamic> data, String id) {
    return Transaction(
      id: id,
      userId: data['user_id'] ?? data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      category: data['category'] ?? 'other',
      subcategory: data['subcategory'],
      merchant: data['merchant'],
      description: data['description'],
      notes: data['notes'],
      paymentMethod: data['payment_method'] ?? data['paymentMethod'] ?? 'cash',
      transactionDate: _parseDate(data['transaction_date'] ?? data['date']),
      createdAt: _parseDate(data['created_at'] ?? data['createdAt']),
      inputMethod: data['input_method'] ?? data['inputMethod'] ?? 'manual',
      receiptImageUrl: data['receipt_image_url'] ?? data['receiptImageUrl'],
      receiptData: data['receipt_data'] ?? data['receiptData'],
      aiConfidence: (data['ai_confidence'] ?? data['aiConfidence'])?.toDouble(),
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Copy with method for updates
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
    List<String>? tags,
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
      tags: tags ?? this.tags,
    );
  }
}

/// Transaction type enum is defined at top of file

/// Transaction categories
class TransactionCategories {
  static const List<String> categories = [
    'Food & Dining',
    'Shopping',
    'Transportation',
    'Bills & Utilities',
    'Entertainment',
    'Health & Medical',
    'Travel',
    'Education',
    'Business',
    'Personal Care',
    'Home & Garden',
    'Gifts & Donations',
    'Income',
    'Other',
  ];

  /// Category keywords for auto-classification
  static const Map<String, List<String>> categoryKeywords = {
    'Food & Dining': [
      'restaurant',
      'food',
      'cafe',
      'coffee',
      'pizza',
      'burger',
      'meal',
      'dining',
      'lunch',
      'dinner',
      'breakfast',
      'snack',
      'grocery',
      'supermarket',
      'mcdonalds',
      'starbucks',
      'subway',
      'dominos',
      'kfc'
    ],
    'Shopping': [
      'store',
      'shop',
      'mall',
      'retail',
      'amazon',
      'walmart',
      'target',
      'clothing',
      'clothes',
      'shoes',
      'electronics',
      'book',
      'toy'
    ],
    'Transportation': [
      'gas',
      'fuel',
      'uber',
      'lyft',
      'taxi',
      'bus',
      'train',
      'parking',
      'toll',
      'car',
      'auto',
      'mechanic',
      'repair',
      'service'
    ],
    'Bills & Utilities': [
      'electric',
      'electricity',
      'water',
      'gas',
      'internet',
      'phone',
      'cable',
      'insurance',
      'rent',
      'mortgage',
      'loan',
      'payment'
    ],
    'Entertainment': [
      'movie',
      'cinema',
      'theater',
      'concert',
      'show',
      'game',
      'netflix',
      'spotify',
      'subscription',
      'streaming',
      'entertainment'
    ],
    'Health & Medical': [
      'doctor',
      'hospital',
      'pharmacy',
      'medical',
      'health',
      'medicine',
      'prescription',
      'dentist',
      'clinic',
      'therapy'
    ],
    'Travel': [
      'hotel',
      'flight',
      'airline',
      'booking',
      'vacation',
      'trip',
      'travel',
      'airbnb',
      'resort',
      'cruise'
    ],
    'Education': [
      'school',
      'university',
      'college',
      'education',
      'tuition',
      'book',
      'course',
      'training',
      'seminar'
    ],
    'Business': [
      'office',
      'supplies',
      'meeting',
      'conference',
      'business',
      'equipment',
      'software',
      'subscription',
      'service'
    ],
    'Personal Care': [
      'salon',
      'spa',
      'beauty',
      'haircut',
      'cosmetics',
      'personal',
      'care',
      'hygiene',
      'grooming'
    ],
    'Home & Garden': [
      'home',
      'garden',
      'furniture',
      'appliance',
      'tools',
      'hardware',
      'depot',
      'lowes',
      'ikea',
      'decoration'
    ],
    'Gifts & Donations': [
      'gift',
      'donation',
      'charity',
      'present',
      'birthday',
      'wedding',
      'anniversary',
      'holiday'
    ],
  };

  /// Get category based on text analysis
  static String classifyTransaction(String description, String merchant) {
    final text = '$description $merchant'.toLowerCase();

    for (final category in categoryKeywords.keys) {
      final keywords = categoryKeywords[category]!;
      for (final keyword in keywords) {
        if (text.contains(keyword.toLowerCase())) {
          return category;
        }
      }
    }

    return 'Other';
  }
}
