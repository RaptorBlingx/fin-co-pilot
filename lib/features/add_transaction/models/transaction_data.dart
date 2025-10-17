import 'package:flutter/foundation.dart';

/// Enhanced transaction data model with required/optional field validation
class TransactionData {
  // REQUIRED FIELDS (Cannot be null for complete transaction)
  final double? amount;
  final String? item;
  final String? category;
  
  // OPTIONAL FIELDS (Encouraged but not required)
  final String? merchant;
  final DateTime? date;
  final String? description;
  final String? location;
  final String? paymentMethod;
  final String? currency;
  
  // Metadata
  final String? notes;
  final List<String>? tags;

  const TransactionData({
    this.amount,
    this.item,
    this.category,
    this.merchant,
    this.date,
    this.description,
    this.location,
    this.paymentMethod,
    this.currency,
    this.notes,
    this.tags,
  });

  /// Check if all required fields are present
  bool get hasRequiredFields => amount != null && item != null && (category != null && category!.isNotEmpty);

  /// Get list of missing required fields
  List<String> get missingRequiredFields {
    final missing = <String>[];
    if (amount == null) missing.add('amount');
    if (item == null || item!.isEmpty) missing.add('item');
    if (category == null || category!.isEmpty) missing.add('category');
    return missing;
  }

  /// Get list of complete fields for acknowledgment
  List<String> get completeFields {
    final complete = <String>[];
    if (amount != null) complete.add('amount');
    if (item != null && item!.isNotEmpty) complete.add('item');
    if (category != null && category!.isNotEmpty) complete.add('category');
    if (merchant != null && merchant!.isNotEmpty) complete.add('merchant');
    if (date != null) complete.add('date');
    if (description != null && description!.isNotEmpty) complete.add('description');
    if (location != null && location!.isNotEmpty) complete.add('location');
    if (paymentMethod != null && paymentMethod!.isNotEmpty) complete.add('paymentMethod');
    return complete;
  }

  /// Get optional fields that could be encouraged
  List<String> get encourageOptionalFields {
    final encourage = <String>[];
    if (merchant == null || merchant!.isEmpty) encourage.add('merchant');
    if (location == null || location!.isEmpty) encourage.add('location');
    if (description == null || description!.isEmpty) encourage.add('description');
    return encourage;
  }

  /// Smart merge with another TransactionData, prioritizing non-null values
  TransactionData mergeWith(TransactionData other) {
    return TransactionData(
      amount: other.amount ?? amount,
      item: (other.item != null && other.item!.isNotEmpty) ? other.item : item,
      category: (other.category != null && other.category!.isNotEmpty) ? other.category : category,
      merchant: (other.merchant != null && other.merchant!.isNotEmpty) ? other.merchant : merchant,
      date: other.date ?? date,
      description: (other.description != null && other.description!.isNotEmpty) ? other.description : description,
      location: (other.location != null && other.location!.isNotEmpty) ? other.location : location,
      paymentMethod: (other.paymentMethod != null && other.paymentMethod!.isNotEmpty) ? other.paymentMethod : paymentMethod,
      currency: (other.currency != null && other.currency!.isNotEmpty) ? other.currency : currency,
      notes: (other.notes != null && other.notes!.isNotEmpty) ? other.notes : notes,
      tags: other.tags ?? tags,
    );
  }

  /// Create copy with updated fields
  TransactionData copyWith({
    double? amount,
    String? item,
    String? category,
    String? merchant,
    DateTime? date,
    String? description,
    String? location,
    String? paymentMethod,
    String? currency,
    String? notes,
    List<String>? tags,
  }) {
    return TransactionData(
      amount: amount ?? this.amount,
      item: item ?? this.item,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      description: description ?? this.description,
      location: location ?? this.location,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }

  /// Convert to map for AI context
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'item': item,
      'category': category,
      'merchant': merchant,
      'date': date?.toIso8601String(),
      'description': description,
      'location': location,
      'paymentMethod': paymentMethod,
      'currency': currency ?? 'USD',
      'notes': notes,
      'tags': tags,
    };
  }

  /// Create from map (for AI response parsing)
  factory TransactionData.fromMap(Map<String, dynamic> map) {
    return TransactionData(
      amount: map['amount']?.toDouble(),
      item: map['item'],
      category: map['category'],
      merchant: map['merchant'],
      date: map['date'] != null ? DateTime.tryParse(map['date']) : null,
      description: map['description'],
      location: map['location'],
      paymentMethod: map['paymentMethod'],
      currency: map['currency'],
      notes: map['notes'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
    );
  }

  /// Get completion percentage for progress indication
  double get completionPercentage {
    const totalImportantFields = 6; // amount, item, category, merchant, date, description
    int completeCount = 0;
    
    if (amount != null) completeCount++;
    if (item != null && item!.isNotEmpty) completeCount++;
    if (category != null && category!.isNotEmpty) completeCount++;
    if (merchant != null && merchant!.isNotEmpty) completeCount++;
    if (date != null) completeCount++;
    if (description != null && description!.isNotEmpty) completeCount++;
    
    return completeCount / totalImportantFields;
  }

  /// Generate human-readable summary
  String get summary {
    final parts = <String>[];
    if (item != null) parts.add(item!);
    if (amount != null) parts.add('\$${amount!.toStringAsFixed(2)}');
    if (merchant != null) parts.add('at $merchant');
    if (date != null && !_isToday(date!)) {
      parts.add('on ${date!.day}/${date!.month}');
    }
    return parts.join(' ');
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionData &&
        other.amount == amount &&
        other.item == item &&
        other.category == category &&
        other.merchant == merchant &&
        other.date == date &&
        other.description == description &&
        other.location == location &&
        other.paymentMethod == paymentMethod &&
        other.currency == currency &&
        other.notes == notes &&
        listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return amount.hashCode ^
        item.hashCode ^
        category.hashCode ^
        merchant.hashCode ^
        date.hashCode ^
        description.hashCode ^
        location.hashCode ^
        paymentMethod.hashCode ^
        currency.hashCode ^
        notes.hashCode ^
        tags.hashCode;
  }

  @override
  String toString() {
    return 'TransactionData(${toMap()})';
  }
}