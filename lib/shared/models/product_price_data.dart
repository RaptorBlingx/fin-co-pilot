import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive Product Price Data Model
/// Supports barcode lookup, multi-retailer comparison, price history
class ProductPriceData {
  final String id;
  final String? barcode;
  final String name;
  final String? brand;
  final String? category;
  final String? imageUrl;
  final String? description;
  final List<RetailerPrice> retailers;
  final DateTime lastUpdated;

  ProductPriceData({
    required this.id,
    this.barcode,
    required this.name,
    this.brand,
    this.category,
    this.imageUrl,
    this.description,
    required this.retailers,
    required this.lastUpdated,
  });

  /// Get cheapest price across all retailers
  double get cheapestPrice {
    if (retailers.isEmpty) return 0.0;
    return retailers
        .map((r) => r.price)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Get retailer with cheapest price
  RetailerPrice? get cheapestRetailer {
    if (retailers.isEmpty) return null;
    return retailers.reduce((a, b) => a.price < b.price ? a : b);
  }

  /// Get highest price (for comparison)
  double get highestPrice {
    if (retailers.isEmpty) return 0.0;
    return retailers
        .map((r) => r.price)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Calculate max savings
  double get maxSavings => highestPrice - cheapestPrice;

  /// Calculate savings percentage
  double get savingsPercentage =>
      highestPrice > 0 ? (maxSavings / highestPrice) * 100 : 0.0;

  /// Check if any retailer has stock
  bool get isAvailable =>
      retailers.any((r) => r.availability.toLowerCase() == 'in_stock');

  factory ProductPriceData.fromJson(Map<String, dynamic> json) {
    return ProductPriceData(
      id: json['id'] as String,
      barcode: json['barcode'] as String?,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      retailers: (json['retailers'] as List)
          .map((r) => RetailerPrice.fromJson(r as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.now(),
    );
  }

  factory ProductPriceData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductPriceData(
      id: doc.id,
      barcode: data['barcode'] as String?,
      name: data['name'] as String,
      brand: data['brand'] as String?,
      category: data['category'] as String?,
      imageUrl: data['imageUrl'] as String?,
      description: data['description'] as String?,
      retailers: (data['retailers'] as List)
          .map((r) => RetailerPrice.fromJson(r as Map<String, dynamic>))
          .toList(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'category': category,
      'imageUrl': imageUrl,
      'description': description,
      'retailers': retailers.map((r) => r.toJson()).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}

/// Individual retailer price information
class RetailerPrice {
  final String name;
  final double price;
  final String availability; // in_stock, out_of_stock, limited, pre_order
  final String? url;
  final String? shipping;
  final DateTime? deliveryEstimate;

  RetailerPrice({
    required this.name,
    required this.price,
    required this.availability,
    this.url,
    this.shipping,
    this.deliveryEstimate,
  });

  bool get isInStock => availability.toLowerCase() == 'in_stock';
  bool get isAvailable => isInStock || availability.toLowerCase() == 'limited';

  factory RetailerPrice.fromJson(Map<String, dynamic> json) {
    return RetailerPrice(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      availability: json['availability'] as String? ?? 'unknown',
      url: json['url'] as String?,
      shipping: json['shipping'] as String?,
      deliveryEstimate: json['deliveryEstimate'] != null
          ? DateTime.tryParse(json['deliveryEstimate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'availability': availability,
      'url': url,
      'shipping': shipping,
      'deliveryEstimate': deliveryEstimate?.toIso8601String(),
    };
  }
}

/// User's product watchlist item
class WatchlistItem {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String? imageUrl;
  final double targetPrice;
  final double currentPrice;
  final bool alertEnabled;
  final DateTime addedAt;
  final DateTime? lastChecked;

  WatchlistItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.targetPrice,
    required this.currentPrice,
    this.alertEnabled = true,
    required this.addedAt,
    this.lastChecked,
  });

  bool get isPriceBelowTarget => currentPrice <= targetPrice;
  double get savingsFromTarget => targetPrice - currentPrice;
  double get savingsPercentage =>
      targetPrice > 0 ? (savingsFromTarget / targetPrice) * 100 : 0.0;

  factory WatchlistItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WatchlistItem(
      id: doc.id,
      userId: data['userId'] as String,
      productId: data['productId'] as String,
      productName: data['productName'] as String,
      imageUrl: data['imageUrl'] as String?,
      targetPrice: (data['targetPrice'] as num).toDouble(),
      currentPrice: (data['currentPrice'] as num).toDouble(),
      alertEnabled: data['alertEnabled'] as bool? ?? true,
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      lastChecked: data['lastChecked'] != null
          ? (data['lastChecked'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'targetPrice': targetPrice,
      'currentPrice': currentPrice,
      'alertEnabled': alertEnabled,
      'addedAt': Timestamp.fromDate(addedAt),
      'lastChecked': lastChecked != null
          ? Timestamp.fromDate(lastChecked!)
          : null,
    };
  }
}
