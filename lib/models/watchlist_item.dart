import 'package:cloud_firestore/cloud_firestore.dart';

/// Price Intelligence - Receipt price tracking
///
/// Per DATA_MODELS.md specification:
/// Tracks product prices across purchases to identify savings opportunities.
/// Shows market averages and price trends.
///
/// Features:
/// - Price history tracking
/// - Market average comparison (calculated from all users)
/// - Savings calculation
/// - Alert notifications for good deals
/// - Week 9 feature: Price Intelligence
class WatchlistItem {
  final String id;
  final String userId;
  final String productName;

  /// Optional barcode for exact product matching
  final String? barcode;

  /// Product category (optional)
  final String? category;

  /// Most recent purchase
  final PurchaseRecord lastPurchase;

  /// Historical price data (NEW v3)
  final List<PriceHistoryEntry> priceHistory;

  /// Market average price across all users (NEW v3, calculated)
  final double? marketAverage;

  /// Potential savings compared to market average (NEW v3)
  final double? savings;

  /// Enable price drop alerts
  final bool alertEnabled;

  final DateTime addedAt;
  final DateTime updatedAt;

  WatchlistItem({
    required this.id,
    required this.userId,
    required this.productName,
    this.barcode,
    this.category,
    required this.lastPurchase,
    required this.priceHistory,
    this.marketAverage,
    this.savings,
    required this.alertEnabled,
    required this.addedAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory WatchlistItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse price history
    final historyData = data['priceHistory'] as List<dynamic>? ?? [];
    final history = historyData
        .map((h) => PriceHistoryEntry.fromMap(h as Map<String, dynamic>))
        .toList();

    return WatchlistItem(
      id: doc.id,
      userId: (data['user_id'] ?? data['userId']) as String,
      productName: data['productName'] as String,
      barcode: data['barcode'] as String?,
      category: data['category'] as String?,
      lastPurchase: PurchaseRecord.fromMap(
          data['lastPurchase'] as Map<String, dynamic>),
      priceHistory: history,
      marketAverage: data['marketAverage'] != null
          ? (data['marketAverage'] as num).toDouble()
          : null,
      savings: data['savings'] != null
          ? (data['savings'] as num).toDouble()
          : null,
      alertEnabled: data['alertEnabled'] as bool,
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'productName': productName,
      'barcode': barcode,
      'category': category,
      'lastPurchase': lastPurchase.toMap(),
      'priceHistory': priceHistory.map((h) => h.toMap()).toList(),
      'marketAverage': marketAverage,
      'savings': savings,
      'alertEnabled': alertEnabled,
      'addedAt': Timestamp.fromDate(addedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get lowest price from history
  double? get lowestPrice {
    if (priceHistory.isEmpty) return null;
    return priceHistory.map((h) => h.amount).reduce((a, b) => a < b ? a : b);
  }

  /// Get highest price from history
  double? get highestPrice {
    if (priceHistory.isEmpty) return null;
    return priceHistory.map((h) => h.amount).reduce((a, b) => a > b ? a : b);
  }

  /// Get average price from user's history
  double? get averagePrice {
    if (priceHistory.isEmpty) return null;
    final sum = priceHistory.fold<double>(0, (sum, h) => sum + h.amount);
    return sum / priceHistory.length;
  }

  /// Check if last purchase was a good deal (below average)
  bool get wasGoodDeal {
    final avg = averagePrice;
    if (avg == null) return false;
    return lastPurchase.amount < avg;
  }

  /// Get price trend: 'increasing', 'decreasing', 'stable'
  String get priceTrend {
    if (priceHistory.length < 2) return 'stable';

    final recent = priceHistory.take(3).map((h) => h.amount).toList();
    final older = priceHistory.skip(3).take(3).map((h) => h.amount).toList();

    if (older.isEmpty) return 'stable';

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;

    if (recentAvg > olderAvg * 1.1) return 'increasing';
    if (recentAvg < olderAvg * 0.9) return 'decreasing';
    return 'stable';
  }

  /// Compare to market average and get recommendation
  String? get savingsRecommendation {
    if (marketAverage == null) return null;

    final diff = lastPurchase.amount - marketAverage!;
    if (diff > 2) {
      return 'You paid \$${diff.toStringAsFixed(2)} more than average. Consider shopping elsewhere.';
    } else if (diff < -2) {
      return 'Great deal! You saved \$${(-diff).toStringAsFixed(2)} vs average.';
    }
    return null;
  }
}

/// Purchase record
class PurchaseRecord {
  final double amount;
  final String merchant;
  final DateTime date;
  final String transactionId;

  PurchaseRecord({
    required this.amount,
    required this.merchant,
    required this.date,
    required this.transactionId,
  });

  factory PurchaseRecord.fromMap(Map<String, dynamic> map) {
    return PurchaseRecord(
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'] as String,
      date: (map['date'] as Timestamp).toDate(),
      transactionId: map['transactionId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'merchant': merchant,
      'date': Timestamp.fromDate(date),
      'transactionId': transactionId,
    };
  }
}

/// Price history entry (NEW v3)
class PriceHistoryEntry {
  final double amount;
  final String merchant;
  final DateTime date;

  PriceHistoryEntry({
    required this.amount,
    required this.merchant,
    required this.date,
  });

  factory PriceHistoryEntry.fromMap(Map<String, dynamic> map) {
    return PriceHistoryEntry(
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'] as String,
      date: (map['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'merchant': merchant,
      'date': Timestamp.fromDate(date),
    };
  }
}
