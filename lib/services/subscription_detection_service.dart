import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart' as models;
import '../models/subscription.dart';
import 'dart:math' as math;

/// Subscription Detection Service
///
/// Week 8: Subscription Detection (Killer Feature #7)
/// Automatically detects recurring charges from transaction history.
///
/// Features:
/// - Analyzes last 90 days of transactions
/// - Detects same merchant with similar amounts
/// - Identifies frequency (weekly, monthly, yearly)
/// - Predicts next charge date
/// - Calculates annual cost and potential savings
/// - Cloud Function ready (runs weekly)
///
/// Detection Algorithm:
/// - Group by merchant
/// - Find transactions with similar amounts (±10%)
/// - Calculate time intervals between charges
/// - Classify frequency based on interval patterns
/// - Require minimum 2 charges to detect
class SubscriptionDetectionService {
  static final SubscriptionDetectionService _instance =
      SubscriptionDetectionService._internal();
  factory SubscriptionDetectionService() => _instance;
  SubscriptionDetectionService._internal();

  final _firestore = FirebaseFirestore.instance;

  /// Detect subscriptions for a user
  ///
  /// This should be called weekly by a Cloud Function,
  /// but can also be triggered manually.
  Future<List<Subscription>> detectSubscriptions(String userId) async {
    print('[SubscriptionDetection] Analyzing subscriptions for user: $userId');

    // Get last 90 days of transactions
    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
    final transactions = await _getTransactions(userId, ninetyDaysAgo);

    if (transactions.isEmpty) {
      print('[SubscriptionDetection] No transactions found');
      return [];
    }

    print('[SubscriptionDetection] Found ${transactions.length} transactions');

    // Group transactions by merchant
    final byMerchant = <String, List<models.Transaction>>{};
    for (final txn in transactions) {
      if (txn.type == models.TransactionType.expense && txn.merchant != null) {
        byMerchant.putIfAbsent(txn.merchant!, () => []).add(txn);
      }
    }

    // Detect subscriptions for each merchant
    final detectedSubscriptions = <Subscription>[];

    for (final entry in byMerchant.entries) {
      final merchant = entry.key;
      final merchantTxns = entry.value;

      // Need at least 2 transactions to detect a pattern
      if (merchantTxns.length < 2) continue;

      // Sort by date
      merchantTxns.sort((a, b) => a.date.compareTo(b.date));

      // Try to detect recurring pattern
      final subscription = _detectRecurringPattern(
        userId,
        merchant,
        merchantTxns,
      );

      if (subscription != null) {
        detectedSubscriptions.add(subscription);
      }
    }

    // Save detected subscriptions
    for (final subscription in detectedSubscriptions) {
      await _saveOrUpdateSubscription(subscription);
    }

    print('[SubscriptionDetection] Detected ${detectedSubscriptions.length} subscriptions');
    return detectedSubscriptions;
  }

  /// Detect recurring pattern in merchant transactions
  Subscription? _detectRecurringPattern(
    String userId,
    String merchant,
    List<models.Transaction> transactions,
  ) {
    // Group transactions by similar amounts (±10%)
    final amountGroups = _groupBySimilarAmounts(transactions);

    // Find the largest group (most recurring charges)
    if (amountGroups.isEmpty) return null;

    final largestGroup = amountGroups.reduce((a, b) => a.length > b.length ? a : b);

    // Need at least 2 charges to establish a pattern
    if (largestGroup.length < 2) return null;

    // Calculate average amount
    final avgAmount = largestGroup.fold<double>(
          0,
          (sum, txn) => sum + txn.amount,
        ) /
        largestGroup.length;

    // Calculate intervals between charges
    final intervals = <int>[];
    for (var i = 1; i < largestGroup.length; i++) {
      final daysBetween = largestGroup[i].date.difference(largestGroup[i - 1].date).inDays;
      intervals.add(daysBetween);
    }

    if (intervals.isEmpty) return null;

    // Determine frequency based on average interval
    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    // Check if intervals are consistent (variance check)
    final variance = _calculateVariance(intervals);
    final stdDev = math.sqrt(variance);

    // If variance is too high, not a subscription (irregular pattern)
    if (stdDev > avgInterval * 0.3) {
      print('[SubscriptionDetection] $merchant: Too much variance ($stdDev days), not a subscription');
      return null;
    }

    // Classify frequency
    SubscriptionFrequency frequency;
    if (avgInterval <= 10) {
      frequency = SubscriptionFrequency.weekly;
    } else if (avgInterval <= 45) {
      frequency = SubscriptionFrequency.monthly;
    } else if (avgInterval >= 300) {
      frequency = SubscriptionFrequency.yearly;
    } else {
      // Not a clear pattern
      return null;
    }

    // Calculate next expected charge
    final lastCharge = largestGroup.last;
    final nextCharge = _calculateNextCharge(lastCharge.date, frequency);

    // Determine category
    final category = _guessCategory(merchant, largestGroup.first.category);

    // Calculate potential savings (if user rarely uses it)
    final savings = _calculatePotentialSavings(avgAmount, frequency);

    return Subscription(
      id: '', // Firestore will generate
      userId: userId,
      merchant: merchant,
      amount: avgAmount,
      currency: largestGroup.first.currency,
      frequency: frequency,
      lastCharge: lastCharge.date,
      nextExpectedCharge: nextCharge,
      detectedAt: DateTime.now(),
      transactions: largestGroup.map((t) => t.id).toList(),
      status: SubscriptionStatus.active,
      userConfirmed: false,
      metadata: SubscriptionMetadata(
        category: category,
        cancelUrl: _guessCancelUrl(merchant),
        savings: savings,
      ),
      updatedAt: DateTime.now(),
    );
  }

  /// Group transactions by similar amounts (±10%)
  List<List<models.Transaction>> _groupBySimilarAmounts(
    List<models.Transaction> transactions,
  ) {
    final groups = <List<models.Transaction>>[];

    for (final txn in transactions) {
      var addedToGroup = false;

      for (final group in groups) {
        // Check if this transaction's amount is within 10% of group average
        final groupAvg = group.fold<double>(0, (sum, t) => sum + t.amount) / group.length;
        final difference = (txn.amount - groupAvg).abs();
        final percentDiff = difference / groupAvg;

        if (percentDiff <= 0.1) {
          // Within 10%, add to this group
          group.add(txn);
          addedToGroup = true;
          break;
        }
      }

      if (!addedToGroup) {
        // Create new group
        groups.add([txn]);
      }
    }

    return groups;
  }

  /// Calculate variance of intervals
  double _calculateVariance(List<int> numbers) {
    if (numbers.isEmpty) return 0.0;

    final mean = numbers.reduce((a, b) => a + b) / numbers.length;
    final squaredDiffs = numbers.map((n) => math.pow(n - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / numbers.length;
  }

  /// Calculate next charge date based on frequency
  DateTime _calculateNextCharge(DateTime lastCharge, SubscriptionFrequency frequency) {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return lastCharge.add(const Duration(days: 7));
      case SubscriptionFrequency.monthly:
        return DateTime(
          lastCharge.year,
          lastCharge.month + 1,
          lastCharge.day,
        );
      case SubscriptionFrequency.yearly:
        return DateTime(
          lastCharge.year + 1,
          lastCharge.month,
          lastCharge.day,
        );
    }
  }

  /// Guess subscription category
  String _guessCategory(String merchant, String transactionCategory) {
    final lowerMerchant = merchant.toLowerCase();

    // Common subscription categories
    if (lowerMerchant.contains('netflix') ||
        lowerMerchant.contains('hulu') ||
        lowerMerchant.contains('disney') ||
        lowerMerchant.contains('spotify') ||
        lowerMerchant.contains('youtube')) {
      return 'Entertainment';
    }

    if (lowerMerchant.contains('gym') ||
        lowerMerchant.contains('fitness') ||
        lowerMerchant.contains('planet')) {
      return 'Health & Fitness';
    }

    if (lowerMerchant.contains('amazon') ||
        lowerMerchant.contains('prime')) {
      return 'Shopping';
    }

    if (lowerMerchant.contains('cloud') ||
        lowerMerchant.contains('storage') ||
        lowerMerchant.contains('dropbox') ||
        lowerMerchant.contains('google')) {
      return 'Software & Services';
    }

    // Fall back to transaction category
    return transactionCategory;
  }

  /// Guess cancel URL for common services
  String? _guessCancelUrl(String merchant) {
    final lowerMerchant = merchant.toLowerCase();

    final cancelUrls = {
      'netflix': 'https://www.netflix.com/cancelplan',
      'spotify': 'https://www.spotify.com/account/subscription/',
      'hulu': 'https://secure.hulu.com/account',
      'disney': 'https://www.disneyplus.com/account',
      'amazon': 'https://www.amazon.com/gp/primecentral',
      'youtube': 'https://www.youtube.com/paid_memberships',
    };

    for (final entry in cancelUrls.entries) {
      if (lowerMerchant.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Calculate potential savings if subscription is rarely used
  double? _calculatePotentialSavings(double amount, SubscriptionFrequency frequency) {
    // This is a simple heuristic - in a real app, you'd track usage
    // For now, just return the annual cost as potential savings
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return amount * 52;
      case SubscriptionFrequency.monthly:
        return amount * 12;
      case SubscriptionFrequency.yearly:
        return amount;
    }
  }

  /// Get transactions for analysis
  Future<List<models.Transaction>> _getTransactions(
    String userId,
    DateTime since,
  ) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('transaction_date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('transaction_date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => models.Transaction.fromFirestore(doc))
        .toList();
  }

  /// Save or update subscription
  Future<void> _saveOrUpdateSubscription(Subscription subscription) async {
    // Check if subscription already exists for this merchant
    final existing = await _firestore
        .collection('subscriptions')
        .where('user_id', isEqualTo: subscription.userId)
        .where('merchant', isEqualTo: subscription.merchant)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Update existing
      await existing.docs.first.reference.update({
        'amount': subscription.amount,
        'lastCharge': Timestamp.fromDate(subscription.lastCharge),
        'nextExpectedCharge': Timestamp.fromDate(subscription.nextExpectedCharge),
        'transactions': subscription.transactions,
        'updatedAt': Timestamp.now(),
      });
    } else {
      // Create new
      await _firestore.collection('subscriptions').add(subscription.toFirestore());
    }
  }

  /// Get all active subscriptions for a user
  Future<List<Subscription>> getActiveSubscriptions(String userId) async {
    final snapshot = await _firestore
        .collection('subscriptions')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('amount', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Subscription.fromFirestore(doc))
        .toList();
  }

  /// Get subscriptions stream
  Stream<List<Subscription>> getSubscriptionsStream(String userId) {
    return _firestore
        .collection('subscriptions')
        .where('user_id', isEqualTo: userId)
        .orderBy('amount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Subscription.fromFirestore(doc))
            .toList());
  }

  /// Calculate total monthly cost
  double calculateMonthlyTotal(List<Subscription> subscriptions) {
    return subscriptions.fold<double>(0, (sum, sub) {
      switch (sub.frequency) {
        case SubscriptionFrequency.weekly:
          return sum + (sub.amount * 52 / 12);
        case SubscriptionFrequency.monthly:
          return sum + sub.amount;
        case SubscriptionFrequency.yearly:
          return sum + (sub.amount / 12);
      }
    });
  }

  /// Calculate total annual cost
  double calculateAnnualTotal(List<Subscription> subscriptions) {
    return subscriptions.fold<double>(0, (sum, sub) => sum + sub.annualCost);
  }

  /// Mark subscription as canceled
  Future<void> cancelSubscription(String subscriptionId) async {
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': SubscriptionStatus.canceled.name,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Confirm subscription (user acknowledged it)
  Future<void> confirmSubscription(String subscriptionId) async {
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'userConfirmed': true,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Flag subscription for review
  Future<void> flagSubscription(String subscriptionId) async {
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': SubscriptionStatus.flagged.name,
      'updatedAt': Timestamp.now(),
    });
  }
}
