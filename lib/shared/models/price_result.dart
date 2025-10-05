import 'package:cloud_firestore/cloud_firestore.dart';

class PriceResult {
  final String id;
  final String productQuery;
  final String merchant;
  final double price;
  final String currency;
  final String availability; // in_stock, out_of_stock, pre_order
  final String? url;
  final String? notes;
  final String country;
  final DateTime foundAt;

  PriceResult({
    required this.id,
    required this.productQuery,
    required this.merchant,
    required this.price,
    required this.currency,
    required this.availability,
    this.url,
    this.notes,
    required this.country,
    required this.foundAt,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'product_query': productQuery,
      'merchant': merchant,
      'price': price,
      'currency': currency,
      'availability': availability,
      'url': url,
      'notes': notes,
      'country': country,
      'found_at': Timestamp.fromDate(foundAt),
    };
  }

  // Create from Firestore map
  factory PriceResult.fromMap(Map<String, dynamic> map) {
    return PriceResult(
      id: map['id'] ?? '',
      productQuery: map['product_query'] ?? '',
      merchant: map['merchant'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      availability: map['availability'] ?? 'unknown',
      url: map['url'],
      notes: map['notes'],
      country: map['country'] ?? '',
      foundAt: map['found_at'] != null
          ? (map['found_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // UI Helper Getters
  bool get isAvailable => availability.toLowerCase() == 'in_stock';

  bool get hasUrl => url != null && url!.isNotEmpty;

  String get formattedPrice => '$currency ${price.toStringAsFixed(2)}';

  String get availabilityDisplay {
    switch (availability.toLowerCase()) {
      case 'in_stock':
        return 'In Stock';
      case 'out_of_stock':
        return 'Out of Stock';
      case 'pre_order':
        return 'Pre-Order';
      default:
        return 'Unknown';
    }
  }

  String get availabilityIcon {
    switch (availability.toLowerCase()) {
      case 'in_stock':
        return '✅';
      case 'out_of_stock':
        return '❌';
      case 'pre_order':
        return '⏰';
      default:
        return '❓';
    }
  }
}