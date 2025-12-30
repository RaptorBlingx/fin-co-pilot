// =============================================================================
// TIER 2 FEATURE - DISABLED FOR V1.0 LAUNCH
// =============================================================================
// This service is part of V2.0 Price Intelligence features.
// Feature Flag: FeaturesConfig.enablePriceIntelligence = false
// 
// To re-enable:
// 1. Set FeaturesConfig.enablePriceIntelligence = true
// 2. Uncomment the code below
// 3. Test thoroughly
// =============================================================================

/* COMMENTED OUT FOR V1.0 - UNCOMMENT FOR V2.0

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/receipt_ocr_service.dart';
import '../models/watchlist_item.dart';

/// Price Intelligence Service (Week 10 Feature)
///
/// Provides price comparison and tracking:
/// - Add receipt items to watchlist
/// - Calculate market averages across all users
/// - Identify savings opportunities
/// - Track price trends
/// - Alert on good deals
///
/// Features:
/// - Cross-user price comparison
/// - Market average calculation
/// - Price drop alerts
/// - Savings recommendations
class PriceIntelligenceService {
  static final PriceIntelligenceService _instance = PriceIntelligenceService._internal();
  factory PriceIntelligenceService() => _instance;
  PriceIntelligenceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add receipt items to watchlist for price tracking
  Future<void> addReceiptItemsToWatchlist({
    required String userId,
    required List<ReceiptItem> items,
    required String merchant,
    required String transactionId,
    required DateTime date,
  }) async {
    try {
      print('📊 Adding ${items.length} items to watchlist...');

      for (final item in items) {
        // Skip if item has no meaningful price
        if (item.totalPrice == 0) continue;

        // Check if item already exists in watchlist
        final existingItem = await _findExistingWatchlistItem(
          userId: userId,
          productName: item.description,
        );

        if (existingItem != null) {
          // Update existing item with new purchase
          await _updateWatchlistItem(
            itemId: existingItem.id,
            newPurchase: PurchaseRecord(
              amount: item.totalPrice,
              merchant: merchant,
              date: date,
              transactionId: transactionId,
            ),
          );
        } else {
          // Create new watchlist item
          await _createWatchlistItem(
            userId: userId,
            item: item,
            merchant: merchant,
            transactionId: transactionId,
            date: date,
          );
        }
      }

      // Update market averages for all items
      await _updateMarketAverages(items.map((i) => i.description).toList());

      print('✅ Watchlist updated successfully');
    } catch (e) {
      print('❌ Error adding items to watchlist: $e');
    }
  }

  /// Find existing watchlist item by product name
  Future<WatchlistItem?> _findExistingWatchlistItem({
    required String userId,
    required String productName,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('watchlist')
          .where('user_id', isEqualTo: userId)
          .where('productName', isEqualTo: productName)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return WatchlistItem.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error finding watchlist item: $e');
      return null;
    }
  }

  /// Create new watchlist item
  Future<void> _createWatchlistItem({
    required String userId,
    required ReceiptItem item,
    required String merchant,
    required String transactionId,
    required DateTime date,
  }) async {
    try {
      final purchaseRecord = PurchaseRecord(
        amount: item.totalPrice,
        merchant: merchant,
        date: date,
        transactionId: transactionId,
      );

      final priceHistory = [
        PriceHistoryEntry(
          amount: item.totalPrice,
          merchant: merchant,
          date: date,
        ),
      ];

      final watchlistItem = WatchlistItem(
        id: '',
        userId: userId,
        productName: item.description,
        category: _guessCategory(item.description),
        lastPurchase: purchaseRecord,
        priceHistory: priceHistory,
        alertEnabled: true,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('watchlist').add(watchlistItem.toFirestore());
    } catch (e) {
      print('Error creating watchlist item: $e');
    }
  }

  /// Update existing watchlist item with new purchase
  Future<void> _updateWatchlistItem({
    required String itemId,
    required PurchaseRecord newPurchase,
  }) async {
    try {
      final doc = await _firestore.collection('watchlist').doc(itemId).get();
      if (!doc.exists) return;

      final item = WatchlistItem.fromFirestore(doc);

      // Add to price history
      final updatedHistory = [
        PriceHistoryEntry(
          amount: newPurchase.amount,
          merchant: newPurchase.merchant,
          date: newPurchase.date,
        ),
        ...item.priceHistory,
      ].take(10).toList(); // Keep last 10 purchases

      // Update document
      await _firestore.collection('watchlist').doc(itemId).update({
        'lastPurchase': newPurchase.toMap(),
        'priceHistory': updatedHistory.map((h) => h.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating watchlist item: $e');
    }
  }

  /// Update market averages for products
  Future<void> _updateMarketAverages(List<String> productNames) async {
    try {
      for (final productName in productNames) {
        // Get all watchlist items for this product (across all users)
        final snapshot = await _firestore
            .collection('watchlist')
            .where('productName', isEqualTo: productName)
            .get();

        if (snapshot.docs.isEmpty) continue;

        // Calculate market average from all users' last purchases
        final prices = snapshot.docs
            .map((doc) {
              final data = doc.data();
              final lastPurchase = data['lastPurchase'] as Map<String, dynamic>;
              return (lastPurchase['amount'] as num).toDouble();
            })
            .toList();

        final marketAverage = prices.reduce((a, b) => a + b) / prices.length;

        // Update all items with the market average
        for (final doc in snapshot.docs) {
          final item = WatchlistItem.fromFirestore(doc);
          final savings = item.lastPurchase.amount - marketAverage;

          await _firestore.collection('watchlist').doc(doc.id).update({
            'marketAverage': marketAverage,
            'savings': savings,
          });
        }
      }
    } catch (e) {
      print('Error updating market averages: $e');
    }
  }

  /// Guess product category from name
  String? _guessCategory(String productName) {
    final name = productName.toLowerCase();

    if (name.contains('milk') || name.contains('cheese') || name.contains('yogurt')) {
      return 'Dairy';
    } else if (name.contains('bread') || name.contains('cereal')) {
      return 'Bakery';
    } else if (name.contains('apple') || name.contains('banana') || name.contains('orange')) {
      return 'Produce';
    } else if (name.contains('chicken') || name.contains('beef') || name.contains('fish')) {
      return 'Meat';
    }

    return null;
  }

  /// Get price comparison for a product
  Future<PriceComparison?> getPriceComparison({
    required String userId,
    required String productName,
  }) async {
    try {
      // Get user's item
      final userItem = await _findExistingWatchlistItem(
        userId: userId,
        productName: productName,
      );

      if (userItem == null) return null;

      // Get market average
      final marketAverage = userItem.marketAverage;
      if (marketAverage == null) return null;

      // Find cheapest store
      final allItems = await _firestore
          .collection('watchlist')
          .where('productName', isEqualTo: productName)
          .get();

      String cheapestStore = 'Unknown';
      double cheapestPrice = double.infinity;

      for (final doc in allItems.docs) {
        final item = WatchlistItem.fromFirestore(doc);
        if (item.lastPurchase.amount < cheapestPrice) {
          cheapestPrice = item.lastPurchase.amount;
          cheapestStore = item.lastPurchase.merchant;
        }
      }

      final savingsOpportunity = userItem.lastPurchase.amount - cheapestPrice;

      return PriceComparison(
        averagePrice: marketAverage,
        savingsOpportunity: savingsOpportunity > 0 ? savingsOpportunity : 0,
        cheapestStore: cheapestStore,
        userPaidPrice: userItem.lastPurchase.amount,
      );
    } catch (e) {
      print('Error getting price comparison: $e');
      return null;
    }
  }

  /// Get user's watchlist stream
  Stream<List<WatchlistItem>> getWatchlistStream(String userId) {
    return _firestore
        .collection('watchlist')
        .where('user_id', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WatchlistItem.fromFirestore(doc))
            .toList());
  }

  /// Get price drop alerts (items that dropped >10% from average)
  Stream<List<WatchlistItem>> getPriceDropAlerts(String userId) {
    return getWatchlistStream(userId).map((items) {
      return items.where((item) {
        if (item.marketAverage == null) return false;
        final dropPercent = (item.marketAverage! - item.lastPurchase.amount) /
            item.marketAverage! *
            100;
        return dropPercent > 10;
      }).toList();
    });
  }

  /// Delete watchlist item
  Future<void> deleteWatchlistItem(String itemId) async {
    try {
      await _firestore.collection('watchlist').doc(itemId).delete();
    } catch (e) {
      print('Error deleting watchlist item: $e');
    }
  }

  /// Toggle alert for watchlist item
  Future<void> toggleAlert(String itemId, bool enabled) async {
    try {
      await _firestore.collection('watchlist').doc(itemId).update({
        'alertEnabled': enabled,
      });
    } catch (e) {
      print('Error toggling alert: $e');
    }
  }
}

/// Price comparison result
class PriceComparison {
  final double averagePrice;
  final double savingsOpportunity;
  final String cheapestStore;
  final double userPaidPrice;

  PriceComparison({
    required this.averagePrice,
    required this.savingsOpportunity,
    required this.cheapestStore,
    required this.userPaidPrice,
  });

  bool get isGoodDeal => userPaidPrice <= averagePrice;

  String get message {
    if (isGoodDeal) {
      return 'Great deal! You paid \$${(averagePrice - userPaidPrice).toStringAsFixed(2)} less than average.';
    } else {
      return 'You paid \$${(userPaidPrice - averagePrice).toStringAsFixed(2)} more than average at $cheapestStore.';
    }
  }
}

*/ // END OF TIER 2 DISABLED CODE - Price Intelligence Service
