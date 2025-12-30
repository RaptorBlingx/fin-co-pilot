import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction model (v3 specification)
///
/// Per DATA_MODELS.md specification:
/// Core transaction model with full v3 features:
/// - SMS source tracking
/// - AI agent attribution
/// - Receipt OCR integration
/// - Price intelligence
/// - Enhanced metadata
class Transaction {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String category;
  final TransactionType type;

  final String? merchant;
  final String? description;
  final String? notes;
  final List<String>? tags;

  final DateTime date;
  final String? time; // HH:MM format

  /// Payment method: 'card', 'cash', 'digital_wallet'
  final String? paymentMethod;
  final PaymentDetails? paymentDetails;

  /// Receipt data (optional)
  final ReceiptInfo? receipt;

  /// NEW v3: Enhanced metadata
  final TransactionMetadata metadata;

  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.category,
    required this.type,
    this.merchant,
    this.description,
    this.notes,
    this.tags,
    required this.date,
    this.time,
    this.paymentMethod,
    this.paymentDetails,
    this.receipt,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Transaction(
      id: doc.id,
      userId: (data['user_id'] ?? data['userId']) as String,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'USD',
      category: data['category'] as String,
      type: TransactionType.values.byName(data['type'] as String? ?? 'expense'),
      merchant: data['merchant'] as String?,
      description: data['description'] as String?,
      notes: data['notes'] as String?,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      paymentDetails: data['paymentDetails'] != null
          ? PaymentDetails.fromMap(data['paymentDetails'] as Map<String, dynamic>)
          : null,
      receipt: data['receipt'] != null
          ? ReceiptInfo.fromMap(data['receipt'] as Map<String, dynamic>)
          : null,
      metadata: TransactionMetadata.fromMap(
          data['metadata'] as Map<String, dynamic>? ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'category': category,
      'type': type.name,
      'merchant': merchant,
      'description': description,
      'notes': notes,
      'tags': tags,
      'date': Timestamp.fromDate(date),
      'time': time,
      'paymentMethod': paymentMethod,
      'paymentDetails': paymentDetails?.toMap(),
      'receipt': receipt?.toMap(),
      'metadata': metadata.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create new transaction
  factory Transaction.create({
    required String userId,
    required double amount,
    required String category,
    TransactionType type = TransactionType.expense,
    String? merchant,
    String? description,
    String? notes,
    List<String>? tags,
    DateTime? date,
    String? time,
    String? paymentMethod,
    PaymentDetails? paymentDetails,
    ReceiptInfo? receipt,
    required TransactionMetadata metadata,
    String currency = 'USD',
  }) {
    final now = DateTime.now();
    return Transaction(
      id: '',
      userId: userId,
      amount: amount,
      currency: currency,
      category: category,
      type: type,
      merchant: merchant,
      description: description,
      notes: notes,
      tags: tags,
      date: date ?? now,
      time: time,
      paymentMethod: paymentMethod,
      paymentDetails: paymentDetails,
      receipt: receipt,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy with updated fields
  Transaction copyWith({
    String? id,
    double? amount,
    String? currency,
    String? category,
    TransactionType? type,
    String? merchant,
    String? description,
    String? notes,
    List<String>? tags,
    DateTime? date,
    String? time,
    TransactionMetadata? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      type: type ?? this.type,
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      date: date ?? this.date,
      time: time ?? this.time,
      paymentMethod: paymentMethod,
      paymentDetails: paymentDetails,
      receipt: receipt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if transaction has receipt
  bool get hasReceipt => receipt != null;

  /// Check if transaction was auto-captured (SMS or voice)
  bool get isAutoCaptured =>
      metadata.source == 'sms' || metadata.source == 'voice';

  /// Check if transaction needs verification
  bool get needsVerification => !metadata.verified && metadata.confidence != null && metadata.confidence! < 0.9;
}

/// Payment details
class PaymentDetails {
  final String? cardLast4;
  final String? cardBrand;

  PaymentDetails({
    this.cardLast4,
    this.cardBrand,
  });

  factory PaymentDetails.fromMap(Map<String, dynamic> map) {
    return PaymentDetails(
      cardLast4: map['cardLast4'] as String?,
      cardBrand: map['cardBrand'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
    };
  }
}

/// Receipt information
class ReceiptInfo {
  final String imageUrl;
  final String? thumbnailUrl;
  final DateTime uploadedAt;
  final ReceiptData? parsedData;

  /// NEW v3: Price intelligence comparison
  final PriceComparison? priceComparison;

  ReceiptInfo({
    required this.imageUrl,
    this.thumbnailUrl,
    required this.uploadedAt,
    this.parsedData,
    this.priceComparison,
  });

  factory ReceiptInfo.fromMap(Map<String, dynamic> map) {
    return ReceiptInfo(
      imageUrl: map['imageUrl'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      parsedData: map['parsedData'] != null
          ? ReceiptData.fromMap(map['parsedData'] as Map<String, dynamic>)
          : null,
      priceComparison: map['priceComparison'] != null
          ? PriceComparison.fromMap(
              map['priceComparison'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'parsedData': parsedData?.toMap(),
      'priceComparison': priceComparison?.toMap(),
    };
  }
}

/// Parsed receipt data (from Vision Service)
class ReceiptData {
  final List<ReceiptItem> items;
  final double subtotal;
  final double tax;
  final double? tip;
  final double total;

  ReceiptData({
    required this.items,
    required this.subtotal,
    required this.tax,
    this.tip,
    required this.total,
  });

  factory ReceiptData.fromMap(Map<String, dynamic> map) {
    final itemsData = map['items'] as List<dynamic>;
    final items = itemsData
        .map((item) => ReceiptItem.fromMap(item as Map<String, dynamic>))
        .toList();

    return ReceiptData(
      items: items,
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      tip: map['tip'] != null ? (map['tip'] as num).toDouble() : null,
      total: (map['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'tip': tip,
      'total': total,
    };
  }
}

/// Individual receipt item
class ReceiptItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  ReceiptItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      description: map['description'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

/// NEW v3: Price intelligence comparison
class PriceComparison {
  final double averagePrice;
  final double savingsOpportunity;
  final String cheapestStore;

  PriceComparison({
    required this.averagePrice,
    required this.savingsOpportunity,
    required this.cheapestStore,
  });

  factory PriceComparison.fromMap(Map<String, dynamic> map) {
    return PriceComparison(
      averagePrice: (map['averagePrice'] as num).toDouble(),
      savingsOpportunity: (map['savingsOpportunity'] as num).toDouble(),
      cheapestStore: map['cheapestStore'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averagePrice': averagePrice,
      'savingsOpportunity': savingsOpportunity,
      'cheapestStore': cheapestStore,
    };
  }

  /// Check if user got a good deal
  bool get isGoodDeal => savingsOpportunity < 0;
}

/// NEW v3: Enhanced transaction metadata
class TransactionMetadata {
  /// Source: 'manual', 'voice', 'chat', 'receipt', 'sms' (NEW v3)
  final String source;

  /// AI confidence: 0-1 (optional)
  final double? confidence;

  /// User verified
  final bool verified;

  /// User edited after creation
  final bool edited;

  /// NEW v3: Which AI agent processed this transaction
  /// Values: 'financial_copilot', 'vision', 'analyst'
  final String? aiAgent;

  TransactionMetadata({
    required this.source,
    this.confidence,
    required this.verified,
    required this.edited,
    this.aiAgent,
  });

  factory TransactionMetadata.fromMap(Map<String, dynamic> map) {
    return TransactionMetadata(
      source: map['source'] as String? ?? 'manual',
      confidence: map['confidence'] != null
          ? (map['confidence'] as num).toDouble()
          : null,
      verified: map['verified'] as bool? ?? false,
      edited: map['edited'] as bool? ?? false,
      aiAgent: map['aiAgent'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'confidence': confidence,
      'verified': verified,
      'edited': edited,
      'aiAgent': aiAgent,
    };
  }
}

/// Transaction type
enum TransactionType {
  expense,
  income,
}

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
