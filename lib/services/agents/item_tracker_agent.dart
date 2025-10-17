import 'package:cloud_firestore/cloud_firestore.dart';
import 'receipt_agent.dart';

/// Agent 6: Item Tracker Agent
/// Tracks individual items across transactions for price trends and insights
class ItemTrackerAgent {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save items from a receipt to item tracking database
  Future<void> trackItems({
    required String userId,
    required String transactionId,
    required List<ReceiptItem> items,
    required DateTime purchaseDate,
    required String? merchant,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final item in items) {
        // Create item tracking record
        final itemRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('tracked_items')
            .doc();

        batch.set(itemRef, {
          'transaction_id': transactionId,
          'item_name': item.name,
          'normalized_name': _normalizeItemName(item.name),
          'category': item.category ?? 'Other',
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.totalPrice,
          'merchant': merchant,
          'purchase_date': Timestamp.fromDate(purchaseDate),
          'created_at': FieldValue.serverTimestamp(),
        });

        // Update item profile (global tracking across all transactions)
        await _updateItemProfile(
          userId: userId,
          item: item,
          merchant: merchant,
          purchaseDate: purchaseDate,
        );
      }

      await batch.commit();
    } catch (e) {
      print('Item Tracker Agent Error: $e');
      rethrow;
    }
  }

  /// Update item profile with purchase history
  Future<void> _updateItemProfile({
    required String userId,
    required ReceiptItem item,
    required String? merchant,
    required DateTime purchaseDate,
  }) async {
    final normalizedName = _normalizeItemName(item.name);
    final profileRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('item_profiles')
        .doc(normalizedName);

    final profileDoc = await profileRef.get();

    if (profileDoc.exists) {
      // Update existing profile
      await profileRef.update({
        'last_purchase_date': Timestamp.fromDate(purchaseDate),
        'purchase_count': FieldValue.increment(1),
        'total_spent': FieldValue.increment(item.totalPrice),
        'last_price': item.unitPrice,
        'last_merchant': merchant,
        'price_history': FieldValue.arrayUnion([
          {
            'date': Timestamp.fromDate(purchaseDate),
            'price': item.unitPrice,
            'merchant': merchant,
          }
        ]),
      });
    } else {
      // Create new profile
      await profileRef.set({
        'item_name': item.name,
        'normalized_name': normalizedName,
        'category': item.category ?? 'Other',
        'first_purchase_date': Timestamp.fromDate(purchaseDate),
        'last_purchase_date': Timestamp.fromDate(purchaseDate),
        'purchase_count': 1,
        'total_spent': item.totalPrice,
        'average_price': item.unitPrice,
        'last_price': item.unitPrice,
        'last_merchant': merchant,
        'price_history': [
          {
            'date': Timestamp.fromDate(purchaseDate),
            'price': item.unitPrice,
            'merchant': merchant,
          }
        ],
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get item purchase history
  Future<ItemPurchaseHistory> getItemHistory({
    required String userId,
    required String itemName,
  }) async {
    final normalizedName = _normalizeItemName(itemName);
    final profileRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('item_profiles')
        .doc(normalizedName);

    final doc = await profileRef.get();
    if (!doc.exists) {
      return ItemPurchaseHistory(itemName: itemName, purchases: []);
    }

    final data = doc.data()!;
    final priceHistory = data['price_history'] as List? ?? [];

    return ItemPurchaseHistory(
      itemName: itemName,
      purchaseCount: data['purchase_count'] ?? 0,
      averagePrice: (data['average_price'] as num?)?.toDouble() ?? 0.0,
      lastPrice: (data['last_price'] as num?)?.toDouble() ?? 0.0,
      lastMerchant: data['last_merchant'],
      purchases: priceHistory.map((p) {
        return ItemPurchase(
          date: (p['date'] as Timestamp).toDate(),
          price: (p['price'] as num).toDouble(),
          merchant: p['merchant'],
        );
      }).toList(),
    );
  }

  /// Normalize item name for matching
  String _normalizeItemName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Get all tracked items for a user (for dashboard)
  Future<List<ItemPurchaseHistory>> getAllTrackedItems({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final profilesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('item_profiles')
          .orderBy('last_purchase_date', descending: true)
          .limit(limit)
          .get();

      final items = <ItemPurchaseHistory>[];

      for (final doc in profilesSnapshot.docs) {
        final data = doc.data();
        final priceHistory = data['price_history'] as List? ?? [];

        items.add(ItemPurchaseHistory(
          itemName: data['item_name'] ?? 'Unknown',
          purchaseCount: data['purchase_count'] ?? 0,
          averagePrice: (data['average_price'] as num?)?.toDouble() ?? 0.0,
          lastPrice: (data['last_price'] as num?)?.toDouble() ?? 0.0,
          lastMerchant: data['last_merchant'],
          category: data['category'] ?? 'Other',
          firstPurchaseDate: (data['first_purchase_date'] as Timestamp?)?.toDate(),
          lastPurchaseDate: (data['last_purchase_date'] as Timestamp?)?.toDate(),
          purchases: priceHistory.map((p) {
            return ItemPurchase(
              date: (p['date'] as Timestamp).toDate(),
              price: (p['price'] as num).toDouble(),
              merchant: p['merchant'],
            );
          }).toList(),
        ));
      }

      return items;
    } catch (e) {
      print('Error loading tracked items: $e');
      return [];
    }
  }

  /// Get price trend for an item
  Future<PriceTrend> getPriceTrend({
    required String userId,
    required String itemName,
  }) async {
    final history = await getItemHistory(userId: userId, itemName: itemName);

    if (history.purchases.length < 2) {
      return PriceTrend(
        trend: 'stable',
        percentageChange: 0.0,
        message: 'Not enough data for trend analysis',
      );
    }

    final purchases = history.purchases..sort((a, b) => a.date.compareTo(b.date));
    final oldestPrice = purchases.first.price;
    final latestPrice = purchases.last.price;

    final change = ((latestPrice - oldestPrice) / oldestPrice) * 100;

    String trend;
    String message;

    if (change > 10) {
      trend = 'increasing';
      message = 'Price up ${change.toStringAsFixed(1)}% since first purchase';
    } else if (change < -10) {
      trend = 'decreasing';
      message = 'Price down ${change.abs().toStringAsFixed(1)}% since first purchase';
    } else {
      trend = 'stable';
      message = 'Price relatively stable';
    }

    return PriceTrend(
      trend: trend,
      percentageChange: change,
      message: message,
    );
  }

  /// Calculate purchase frequency for predictions
  int? calculatePurchaseFrequency(List<ItemPurchase> purchases) {
    if (purchases.length < 2) return null;

    // Sort by date
    final sorted = purchases.toList()..sort((a, b) => a.date.compareTo(b.date));

    // Calculate days between purchases
    final intervals = <int>[];
    for (int i = 1; i < sorted.length; i++) {
      final days = sorted[i].date.difference(sorted[i - 1].date).inDays;
      if (days > 0) intervals.add(days);
    }

    if (intervals.isEmpty) return null;

    // Return average interval
    final sum = intervals.reduce((a, b) => a + b);
    return (sum / intervals.length).round();
  }

  /// Predict next purchase date
  DateTime? predictNextPurchase(ItemPurchaseHistory item) {
    final frequency = calculatePurchaseFrequency(item.purchases);
    if (frequency == null || item.lastPurchaseDate == null) return null;

    return item.lastPurchaseDate!.add(Duration(days: frequency));
  }
}

/// Item purchase history
class ItemPurchaseHistory {
  final String itemName;
  final int purchaseCount;
  final double averagePrice;
  final double lastPrice;
  final String? lastMerchant;
  final String category;
  final DateTime? firstPurchaseDate;
  final DateTime? lastPurchaseDate;
  final List<ItemPurchase> purchases;

  ItemPurchaseHistory({
    required this.itemName,
    this.purchaseCount = 0,
    this.averagePrice = 0.0,
    this.lastPrice = 0.0,
    this.lastMerchant,
    this.category = 'Other',
    this.firstPurchaseDate,
    this.lastPurchaseDate,
    required this.purchases,
  });
}

/// Single item purchase record
class ItemPurchase {
  final DateTime date;
  final double price;
  final String? merchant;

  ItemPurchase({
    required this.date,
    required this.price,
    this.merchant,
  });
}

/// Price trend analysis
class PriceTrend {
  final String trend; // 'increasing', 'decreasing', 'stable'
  final double percentageChange;
  final String message;

  PriceTrend({
    required this.trend,
    required this.percentageChange,
    required this.message,
  });
}
