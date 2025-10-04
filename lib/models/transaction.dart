import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String id;
  final String userId;
  final double amount;
  final String description;
  final String category;
  final String merchant;
  final DateTime date;
  final String? receiptImageUrl;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.category,
    required this.merchant,
    required this.date,
    this.receiptImageUrl,
    this.notes,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Transaction to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'description': description,
      'category': category,
      'merchant': merchant,
      'date': Timestamp.fromDate(date),
      'receiptImageUrl': receiptImageUrl,
      'notes': notes,
      'metadata': metadata ?? {},
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create Transaction from Firestore document
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Transaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      merchant: data['merchant'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      receiptImageUrl: data['receiptImageUrl'],
      notes: data['notes'],
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create new Transaction with generated ID
  factory Transaction.create({
    required String userId,
    required double amount,
    required String description,
    required String category,
    required String merchant,
    DateTime? date,
    String? receiptImageUrl,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return Transaction(
      id: '', // Will be set by Firestore
      userId: userId,
      amount: amount,
      description: description,
      category: category,
      merchant: merchant,
      date: date ?? now,
      receiptImageUrl: receiptImageUrl,
      notes: notes,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copy with updated fields
  Transaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? description,
    String? category,
    String? merchant,
    DateTime? date,
    String? receiptImageUrl,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, amount: \$$amount, description: $description, category: $category, merchant: $merchant, date: $date)';
  }
}

// Transaction categories for classification
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
    'Other',
  ];

  // Category keywords for auto-classification
  static const Map<String, List<String>> categoryKeywords = {
    'Food & Dining': [
      'restaurant', 'food', 'cafe', 'coffee', 'pizza', 'burger', 'meal',
      'dining', 'lunch', 'dinner', 'breakfast', 'snack', 'grocery', 'supermarket',
      'mcdonalds', 'starbucks', 'subway', 'dominos', 'kfc'
    ],
    'Shopping': [
      'store', 'shop', 'mall', 'retail', 'amazon', 'walmart', 'target',
      'clothing', 'clothes', 'shoes', 'electronics', 'book', 'toy'
    ],
    'Transportation': [
      'gas', 'fuel', 'uber', 'lyft', 'taxi', 'bus', 'train', 'parking',
      'toll', 'car', 'auto', 'mechanic', 'repair', 'service'
    ],
    'Bills & Utilities': [
      'electric', 'electricity', 'water', 'gas', 'internet', 'phone',
      'cable', 'insurance', 'rent', 'mortgage', 'loan', 'payment'
    ],
    'Entertainment': [
      'movie', 'cinema', 'theater', 'concert', 'show', 'game', 'netflix',
      'spotify', 'subscription', 'streaming', 'entertainment'
    ],
    'Health & Medical': [
      'doctor', 'hospital', 'pharmacy', 'medical', 'health', 'medicine',
      'prescription', 'dentist', 'clinic', 'therapy'
    ],
    'Travel': [
      'hotel', 'flight', 'airline', 'booking', 'vacation', 'trip',
      'travel', 'airbnb', 'resort', 'cruise'
    ],
    'Education': [
      'school', 'university', 'college', 'education', 'tuition', 'book',
      'course', 'training', 'seminar'
    ],
    'Business': [
      'office', 'supplies', 'meeting', 'conference', 'business', 'equipment',
      'software', 'subscription', 'service'
    ],
    'Personal Care': [
      'salon', 'spa', 'beauty', 'haircut', 'cosmetics', 'personal',
      'care', 'hygiene', 'grooming'
    ],
    'Home & Garden': [
      'home', 'garden', 'furniture', 'appliance', 'tools', 'hardware',
      'depot', 'lowes', 'ikea', 'decoration'
    ],
    'Gifts & Donations': [
      'gift', 'donation', 'charity', 'present', 'birthday', 'wedding',
      'anniversary', 'holiday'
    ],
  };

  // Get category based on text analysis
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