import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_context.dart';
import 'memory_service.dart';
import 'conversation_memory_service.dart';
import 'preferences_service.dart';

/// Assembles rich [UserContext] from multiple Firestore sources.
/// Caches results in memory with a 5-minute TTL for budget/spending data.
class UserContextBuilder {
  static final UserContextBuilder _instance = UserContextBuilder._internal();
  factory UserContextBuilder() => _instance;
  UserContextBuilder._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MemoryService _memoryService = MemoryService();
  final ConversationMemoryService _conversationMemory = ConversationMemoryService();

  // In-memory cache
  UserContext? _cached;
  DateTime? _cachedAt;
  static const _cacheTtl = Duration(minutes: 5);

  /// Build rich context for the given user. Returns cached version if fresh.
  Future<UserContext> build(String userId) async {
    if (_cached != null &&
        _cached!.userId == userId &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return _cached!;
    }

    try {
      // Fire all Firestore reads in parallel
      final results = await Future.wait([
        _fetchUserProfile(userId),         // 0
        _fetchCurrentBudget(userId),       // 1
        _fetchMonthSpending(userId),       // 2
        _fetchLastMonthTotal(userId),      // 3
        _memoryService.getMemoryDossier(userId), // 4
        _conversationMemory.loadRecentSummaries(userId), // 5
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final budget = results[1] as Map<String, dynamic>?;
      final spending = results[2] as _SpendingSnapshot;
      final lastMonthTotal = results[3] as double;
      final memoryDossier = results[4] as String;
      final conversationHistory = results[5] as String;

      // Temporal context
      final now = DateTime.now();
      final timeOfDay = _resolveTimeOfDay(now.hour);
      final dayOfWeek = _resolveDayOfWeek(now.weekday);
      final monthPosition = _resolveMonthPosition(now.day);

      // Account age
      final createdAt = profile['created_at'];
      int accountAgeDays = 0;
      if (createdAt is Timestamp) {
        accountAgeDays = now.difference(createdAt.toDate()).inDays;
      }

      // Budget calculations
      double? budgetAmount;
      double? budgetSpent;
      double? budgetUtilization;
      int? budgetDaysRemaining;

      if (budget != null) {
        budgetAmount = (budget['amount'] as num?)?.toDouble();
        budgetSpent = (budget['total_spent'] as num?)?.toDouble();
        if (budgetAmount != null && budgetAmount > 0 && budgetSpent != null) {
          budgetUtilization = budgetSpent / budgetAmount;
        }
        // Days remaining in the month
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
        budgetDaysRemaining = lastDayOfMonth - now.day;
      }

      // Month-over-month delta
      double monthDelta = 0;
      if (lastMonthTotal > 0) {
        monthDelta =
            ((spending.total - lastMonthTotal) / lastMonthTotal) * 100;
      }

      // Resolve currency & language (Firestore > local prefs > defaults)
      final currency = (profile['currency_preference'] as String?) ??
          PreferencesService.getCurrency() ??
          'USD';
      final language = (profile['language_preference'] as String?) ??
          PreferencesService.getLanguage() ??
          'en';

      final ctx = UserContext(
        userId: userId,
        displayName: profile['display_name'] as String?,
        primaryCurrency: currency,
        primaryLanguage: language,
        country: profile['country_code'] as String?,
        subscriptionTier: (profile['subscription_tier'] as String?) ?? 'free',
        accountAgeDays: accountAgeDays,
        timeOfDay: timeOfDay,
        dayOfWeek: dayOfWeek,
        monthPosition: monthPosition,
        timezone: now.timeZoneName,
        budgetAmount: budgetAmount,
        budgetSpent: budgetSpent,
        budgetUtilization: budgetUtilization,
        budgetDaysRemaining: budgetDaysRemaining,
        monthTotal: spending.total,
        lastMonthTotal: lastMonthTotal,
        monthDelta: monthDelta,
        topCategories: spending.topCategories,
        recentMerchants: spending.recentMerchants,
        memoryDossier: memoryDossier.isNotEmpty ? memoryDossier : null,
        conversationHistory: conversationHistory.isNotEmpty ? conversationHistory : null,
      );

      _cached = ctx;
      _cachedAt = DateTime.now();

      if (kDebugMode) {
        print('✅ UserContextBuilder: Built context for $userId '
            '(currency=$currency, budget=${budgetAmount ?? "none"}, '
            'monthTotal=${spending.total.toStringAsFixed(2)})');
      }

      return ctx;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ UserContextBuilder error: $e');
      }
      // Return minimal context on failure
      return UserContext(
        userId: userId,
        primaryCurrency: PreferencesService.getCurrency() ?? 'USD',
        primaryLanguage: PreferencesService.getLanguage() ?? 'en',
      );
    }
  }

  /// Invalidate the cache (call after budget or profile changes).
  void invalidate() {
    _cached = null;
    _cachedAt = null;
  }

  // ---------------------------------------------------------------------------
  // Firestore queries
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _fetchUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? (doc.data() ?? {}) : {};
  }

  Future<Map<String, dynamic>?> _fetchCurrentBudget(String userId) async {
    final now = DateTime.now();
    final currentMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final snapshot = await _firestore
        .collection('budgets')
        .where('user_id', isEqualTo: userId)
        .where('month', isEqualTo: currentMonth)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
  }

  Future<_SpendingSnapshot> _fetchMonthSpending(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('transaction_date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .orderBy('transaction_date', descending: true)
        .get();

    if (snapshot.docs.isEmpty) {
      return _SpendingSnapshot(total: 0, topCategories: [], recentMerchants: []);
    }

    double total = 0;
    final categoryMap = <String, _CatAccum>{};
    final merchants = <String>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      total += amount;

      final category = data['category'] as String? ?? 'Other';
      categoryMap.putIfAbsent(category, () => _CatAccum());
      categoryMap[category]!.amount += amount;
      categoryMap[category]!.count++;

      final merchant = data['merchant'] as String?;
      if (merchant != null &&
          merchant.isNotEmpty &&
          !merchants.contains(merchant)) {
        merchants.add(merchant);
      }
    }

    // Top 3 categories by amount
    final sortedCats = categoryMap.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));
    final topCategories = sortedCats.take(3).map((e) {
      return CategorySnapshot(
        name: e.key,
        amount: e.value.amount,
        txCount: e.value.count,
      );
    }).toList();

    return _SpendingSnapshot(
      total: total,
      topCategories: topCategories,
      recentMerchants: merchants.take(5).toList(),
    );
  }

  Future<double> _fetchLastMonthTotal(String userId) async {
    final now = DateTime.now();
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);

    final snapshot = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('transaction_date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfLastMonth))
        .where('transaction_date',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfLastMonth))
        .get();

    double total = 0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _resolveTimeOfDay(int hour) {
    if (hour < 6) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    if (hour < 21) return 'evening';
    return 'night';
  }

  String _resolveDayOfWeek(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _resolveMonthPosition(int day) {
    if (day <= 7) return 'start';
    if (day <= 22) return 'mid';
    return 'end';
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _SpendingSnapshot {
  final double total;
  final List<CategorySnapshot> topCategories;
  final List<String> recentMerchants;

  _SpendingSnapshot({
    required this.total,
    required this.topCategories,
    required this.recentMerchants,
  });
}

class _CatAccum {
  double amount = 0;
  int count = 0;
}
