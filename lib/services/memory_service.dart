import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memory_models.dart';
import '../models/transaction.dart' as model;

/// Service for managing long-term user memory in Firestore.
/// Memory docs live under `/users/{uid}/memory/`.
class MemoryService {
  final FirebaseFirestore _firestore;

  MemoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _memoryCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('memory');

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Fire-and-forget update after every transaction save.
  /// Updates behavior_profile and increments counters on other docs.
  Future<void> updateFromTransaction(model.Transaction tx) async {
    try {
      await _updateBehaviorProfile(tx);
    } catch (e) {
      // Fire-and-forget — log but don't throw
      print('[MemoryService] updateFromTransaction error: $e');
    }
  }

  /// Returns a compressed text dossier (~300 tokens) from all memory docs.
  Future<String> getMemoryDossier(String userId) async {
    try {
      final docs = await Future.wait([
        _memoryCollection(userId).doc('behavior_profile').get(),
        _memoryCollection(userId).doc('spending_patterns').get(),
        _memoryCollection(userId).doc('preferences').get(),
        _memoryCollection(userId).doc('financial_goals').get(),
        _memoryCollection(userId).doc('life_context').get(),
      ]);

      final behavior = docs[0].exists
          ? BehaviorProfile.fromFirestore(docs[0].data() as Map<String, dynamic>)
          : null;
      final patterns = docs[1].exists
          ? SpendingPatterns.fromFirestore(docs[1].data() as Map<String, dynamic>)
          : null;
      final prefs = docs[2].exists
          ? UserPreferences.fromFirestore(docs[2].data() as Map<String, dynamic>)
          : null;
      final goals = docs[3].exists
          ? FinancialGoals.fromFirestore(docs[3].data() as Map<String, dynamic>)
          : null;
      final life = docs[4].exists
          ? LifeContext.fromFirestore(docs[4].data() as Map<String, dynamic>)
          : null;

      return _buildDossier(behavior, patterns, prefs, goals, life);
    } catch (e) {
      print('[MemoryService] getMemoryDossier error: $e');
      return '';
    }
  }

  /// Returns the user's active financial goals.
  Future<List<FinancialGoal>> getFinancialGoals(String userId) async {
    try {
      final doc = await _memoryCollection(userId).doc('financial_goals').get();
      if (!doc.exists) return [];
      final goals = FinancialGoals.fromFirestore(doc.data() as Map<String, dynamic>);
      return goals.goals.where((g) => g.status == 'active').toList();
    } catch (e) {
      print('[MemoryService] getFinancialGoals error: $e');
      return [];
    }
  }

  /// Returns the behavior profile for a user.
  Future<BehaviorProfile?> getBehaviorProfile(String userId) async {
    try {
      final doc = await _memoryCollection(userId).doc('behavior_profile').get();
      if (!doc.exists) return null;
      return BehaviorProfile.fromFirestore(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('[MemoryService] getBehaviorProfile error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal — behavior_profile update
  // ---------------------------------------------------------------------------

  Future<void> _updateBehaviorProfile(model.Transaction tx) async {
    final ref = _memoryCollection(tx.userId).doc('behavior_profile');
    final doc = await ref.get();

    BehaviorProfile existing;
    if (doc.exists) {
      existing = BehaviorProfile.fromFirestore(doc.data() as Map<String, dynamic>);
    } else {
      existing = BehaviorProfile();
    }

    final hour = tx.transactionDate.hour.toString();
    final updatedTimes = Map<String, int>.from(existing.typicalTxTimes);
    updatedTimes[hour] = (updatedTimes[hour] ?? 0) + 1;

    final newTotal = existing.totalTransactions + 1;

    // Calculate streak
    int newStreak = existing.streakDays;
    if (existing.lastTransactionDate != null) {
      final daysSince = tx.transactionDate.difference(existing.lastTransactionDate!).inDays;
      if (daysSince <= 1) {
        newStreak = existing.streakDays + (daysSince == 1 ? 1 : 0);
      } else {
        newStreak = 1; // streak broken
      }
    } else {
      newStreak = 1;
    }

    // Context richness: tags count as richness signal
    final tagCount = tx.tags?.length ?? 0;
    final txRichness = tagCount > 0 ? 1.0 : 0.0;
    final newAvgRichness = ((existing.averageContextRichness * existing.totalTransactions) + txRichness) / newTotal;

    // Weekend vs weekday ratio
    final isWeekend = tx.transactionDate.weekday >= 6;
    final weekendCount = (existing.weekendVsWeekdayRatio * existing.totalTransactions).round();
    final newWeekendCount = weekendCount + (isWeekend ? 1 : 0);
    final newWeekendRatio = newTotal > 0 ? newWeekendCount / newTotal : 0.3;

    final updated = BehaviorProfile(
      typicalTxTimes: updatedTimes,
      impulseVsPlannedRatio: existing.impulseVsPlannedRatio,
      weekendVsWeekdayRatio: newWeekendRatio,
      averageContextRichness: newAvgRichness,
      streakDays: newStreak,
      totalTransactions: newTotal,
      lastTransactionDate: tx.transactionDate,
      lastUpdated: DateTime.now(),
    );

    await ref.set(updated.toFirestore());
  }

  // ---------------------------------------------------------------------------
  // Internal — dossier generation (string interpolation, no AI call)
  // ---------------------------------------------------------------------------

  String _buildDossier(
    BehaviorProfile? behavior,
    SpendingPatterns? patterns,
    UserPreferences? prefs,
    FinancialGoals? goals,
    LifeContext? life,
  ) {
    final buf = StringBuffer();

    if (behavior != null && behavior.totalTransactions > 0) {
      buf.writeln('BEHAVIOR: ${behavior.totalTransactions} total txs, '
          '${behavior.streakDays}-day streak, '
          'avg richness ${behavior.averageContextRichness.toStringAsFixed(1)}.');

      if (behavior.typicalTxTimes.isNotEmpty) {
        final peakHour = _peakKey(behavior.typicalTxTimes);
        if (peakHour != null) {
          buf.writeln('Peak spending hour: ${peakHour}h.');
        }
      }
    }

    if (patterns != null && patterns.avgTransactionSize > 0) {
      buf.writeln('PATTERNS: avg tx size ${patterns.avgTransactionSize.toStringAsFixed(2)}');
      if (patterns.peakSpendingDay != null) {
        buf.write(', peak day ${patterns.peakSpendingDay}');
      }
      buf.writeln('.');
    }

    if (prefs != null) {
      if (prefs.frequentPeople.isNotEmpty) {
        buf.writeln('PEOPLE: ${prefs.frequentPeople.take(5).join(", ")}.');
      }
      if (prefs.preferredMerchants.isNotEmpty) {
        buf.writeln('FAV MERCHANTS: ${prefs.preferredMerchants.take(5).join(", ")}.');
      }
    }

    if (goals != null) {
      final active = goals.goals.where((g) => g.status == 'active').toList();
      if (active.isNotEmpty) {
        buf.writeln('GOALS: ${active.map((g) => '${g.name} (${g.progressPercent.toStringAsFixed(0)}%)').join(", ")}.');
      }
    }

    if (life != null) {
      if (life.knownRecurring.isNotEmpty) {
        buf.writeln('RECURRING: ${life.knownRecurring.take(3).map((r) => '${r.merchant} ${r.frequency}').join(", ")}.');
      }
    }

    return buf.toString().trim();
  }

  String? _peakKey(Map<String, int> map) {
    if (map.isEmpty) return null;
    return map.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // ---------------------------------------------------------------------------
  // Aggregation — analyzes recent transactions, updates spending_patterns
  // and life_context docs. Designed to run periodically (>24h between runs).
  // ---------------------------------------------------------------------------

  /// Run weekly aggregation if >24h since last run. Returns true if it ran.
  Future<bool> runAggregationIfNeeded(String userId) async {
    try {
      final patternsDoc = await _memoryCollection(userId).doc('spending_patterns').get();
      if (patternsDoc.exists) {
        final data = patternsDoc.data() as Map<String, dynamic>?;
        final lastUpdated = data?['last_updated'] as String?;
        if (lastUpdated != null) {
          final lastRun = DateTime.tryParse(lastUpdated);
          if (lastRun != null && DateTime.now().difference(lastRun).inHours < 24) {
            return false; // Too soon
          }
        }
      }
      await runWeeklyAggregation(userId);
      return true;
    } catch (e) {
      print('[MemoryService] runAggregationIfNeeded error: $e');
      return false;
    }
  }

  /// Analyzes last 7 days of transactions and updates spending_patterns
  /// and life_context docs.
  Future<void> runWeeklyAggregation(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .where('transaction_date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .orderBy('transaction_date', descending: true)
          .get();

      if (snapshot.docs.isEmpty) return;

      await Future.wait([
        _aggregateSpendingPatterns(userId, snapshot.docs),
        _aggregateLifeContext(userId, snapshot.docs),
        _aggregatePreferences(userId, snapshot.docs),
      ]);
    } catch (e) {
      print('[MemoryService] runWeeklyAggregation error: $e');
    }
  }

  Future<void> _aggregateSpendingPatterns(
    String userId,
    List<QueryDocumentSnapshot> docs,
  ) async {
    final categoryMerchants = <String, Map<String, int>>{};
    final dayTotals = <String, double>{};
    final hourCounts = <String, int>{};
    double totalAmount = 0;

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final category = data['category'] as String? ?? 'other';
      final merchant = data['merchant'] as String?;

      totalAmount += amount;

      // Parse transaction date
      DateTime? txDate;
      final rawDate = data['transaction_date'];
      if (rawDate is Timestamp) {
        txDate = rawDate.toDate();
      } else if (rawDate is String) {
        txDate = DateTime.tryParse(rawDate);
      }

      if (txDate != null) {
        final dayName = dayNames[txDate.weekday - 1];
        dayTotals[dayName] = (dayTotals[dayName] ?? 0) + amount;
        final hour = txDate.hour.toString();
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }

      if (merchant != null && merchant.isNotEmpty) {
        categoryMerchants.putIfAbsent(category, () => {});
        categoryMerchants[category]![merchant] =
            (categoryMerchants[category]![merchant] ?? 0) + 1;
      }
    }

    // Build top merchants per category (top 3 each)
    final topMerchants = <String, List<String>>{};
    for (final entry in categoryMerchants.entries) {
      final sorted = entry.value.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topMerchants[entry.key] = sorted.take(3).map((e) => e.key).toList();
    }

    // Peak spending day & time
    String? peakDay;
    if (dayTotals.isNotEmpty) {
      peakDay = dayTotals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }
    String? peakTime;
    if (hourCounts.isNotEmpty) {
      final peakHour = int.tryParse(_peakKey(hourCounts) ?? '');
      if (peakHour != null) {
        if (peakHour < 12) {
          peakTime = 'morning';
        } else if (peakHour < 17) {
          peakTime = 'afternoon';
        } else {
          peakTime = 'evening';
        }
      }
    }

    final patterns = SpendingPatterns(
      topMerchantsByCategory: topMerchants,
      weeklyRhythm: dayTotals,
      avgTransactionSize: docs.isNotEmpty ? totalAmount / docs.length : 0,
      peakSpendingDay: peakDay,
      peakSpendingTime: peakTime,
      lastUpdated: DateTime.now(),
      transactionsSinceUpdate: 0,
    );

    await _memoryCollection(userId).doc('spending_patterns').set(patterns.toFirestore());
  }

  Future<void> _aggregateLifeContext(
    String userId,
    List<QueryDocumentSnapshot> docs,
  ) async {
    // Detect recurring merchants
    final merchantCounts = <String, List<double>>{};
    final tagTopics = <String, int>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final merchant = data['merchant'] as String?;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final tags = data['tags'] as List?;

      if (merchant != null && merchant.isNotEmpty) {
        merchantCounts.putIfAbsent(merchant, () => []);
        merchantCounts[merchant]!.add(amount);
      }

      // Extract social/location mentions from tags
      if (tags != null) {
        for (final tag in tags) {
          final t = tag.toString();
          if (t.startsWith('social:') || t.startsWith('location:')) {
            final topic = t;
            tagTopics[topic] = (tagTopics[topic] ?? 0) + 1;
          }
        }
      }
    }

    // Merchants appearing 2+ times in the week are likely recurring
    final recurring = <KnownRecurring>[];
    for (final entry in merchantCounts.entries) {
      if (entry.value.length >= 2) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        final freq = entry.value.length >= 5 ? 'daily' : 'weekly';
        recurring.add(KnownRecurring(
          merchant: entry.key,
          frequency: freq,
          avgAmount: avg,
        ));
      }
    }

    // Load existing life_context to merge mentions
    final existingDoc = await _memoryCollection(userId).doc('life_context').get();
    List<LifeContextMention> existingMentions = [];
    List<String> existingEvents = [];
    if (existingDoc.exists) {
      final existing = LifeContext.fromFirestore(existingDoc.data() as Map<String, dynamic>);
      existingMentions = List.from(existing.mentions);
      existingEvents = List.from(existing.lifeEvents);
    }

    // Merge tag topics into mentions
    for (final entry in tagTopics.entries) {
      final idx = existingMentions.indexWhere((m) => m.topic == entry.key);
      if (idx >= 0) {
        existingMentions[idx] = LifeContextMention(
          topic: entry.key,
          frequency: existingMentions[idx].frequency + entry.value,
          lastSeen: DateTime.now(),
        );
      } else {
        existingMentions.add(LifeContextMention(
          topic: entry.key,
          frequency: entry.value,
          lastSeen: DateTime.now(),
        ));
      }
    }

    final lifeContext = LifeContext(
      mentions: existingMentions,
      knownRecurring: recurring,
      lifeEvents: existingEvents,
      lastUpdated: DateTime.now(),
    );

    await _memoryCollection(userId).doc('life_context').set(lifeContext.toFirestore());
  }

  Future<void> _aggregatePreferences(
    String userId,
    List<QueryDocumentSnapshot> docs,
  ) async {
    final merchants = <String, int>{};
    final people = <String, int>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final merchant = data['merchant'] as String?;
      final tags = data['tags'] as List?;

      if (merchant != null && merchant.isNotEmpty) {
        merchants[merchant] = (merchants[merchant] ?? 0) + 1;
      }

      if (tags != null) {
        for (final tag in tags) {
          final t = tag.toString();
          if (t.startsWith('social:')) {
            final person = t.substring(7);
            people[person] = (people[person] ?? 0) + 1;
          }
        }
      }
    }

    // Sort by frequency, take top entries
    final sortedMerchants = merchants.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedPeople = people.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Load existing to preserve vocabulary and amount ranges
    final existingDoc = await _memoryCollection(userId).doc('preferences').get();
    UserPreferences existing = UserPreferences();
    if (existingDoc.exists) {
      existing = UserPreferences.fromFirestore(existingDoc.data() as Map<String, dynamic>);
    }

    final prefs = UserPreferences(
      vocabularyPhrases: existing.vocabularyPhrases,
      frequentPeople: sortedPeople.take(10).map((e) => e.key).toList(),
      preferredMerchants: sortedMerchants.take(10).map((e) => e.key).toList(),
      categoryCombos: existing.categoryCombos,
      typicalAmountRanges: existing.typicalAmountRanges,
      lastUpdated: DateTime.now(),
      transactionsSinceUpdate: 0,
    );

    await _memoryCollection(userId).doc('preferences').set(prefs.toFirestore());
  }
}
