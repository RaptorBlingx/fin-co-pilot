import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart' as model;
import 'memory_service.dart';

/// Generates contextual nudges/encouragements after transaction saves.
/// Rate-limited: max 1 nudge per 5 transactions, max 2 per day.
class NudgeService {
  final FirebaseFirestore _firestore;
  final MemoryService _memoryService;

  NudgeService({FirebaseFirestore? firestore, MemoryService? memoryService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _memoryService = memoryService ?? MemoryService();

  DocumentReference _nudgeStateRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('memory').doc('nudge_state');

  /// Check if a nudge should be shown after a transaction save.
  /// Returns a nudge message string, or null if rate-limited / not applicable.
  Future<String?> checkForNudge(model.Transaction tx) async {
    try {
      final state = await _loadNudgeState(tx.userId);

      // Rate limit: max 2 nudges per day
      if (_isToday(state.lastNudgeDate) && state.nudgeCountToday >= 2) {
        await _incrementTxCounter(tx.userId, state);
        return null;
      }

      // Rate limit: max 1 nudge per 5 transactions
      if (state.txSinceLastNudge < 4) {
        await _incrementTxCounter(tx.userId, state);
        return null;
      }

      // Determine nudge type
      final behavior = await _memoryService.getBehaviorProfile(tx.userId);
      final nudge = _selectNudge(tx, behavior);

      if (nudge != null) {
        await _recordNudge(tx.userId, state);
      } else {
        await _incrementTxCounter(tx.userId, state);
      }

      return nudge;
    } catch (e) {
      print('[NudgeService] checkForNudge error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Nudge selection
  // ---------------------------------------------------------------------------

  String? _selectNudge(model.Transaction tx, dynamic behavior) {
    final tagCount = tx.tags?.length ?? 0;
    final isHighContext = tagCount >= 2;
    final isLowContext = tagCount == 0;

    // Streak celebration (5+ day streak)
    if (behavior != null && behavior.streakDays >= 5 && behavior.streakDays % 5 == 0) {
      return _streakNudge(behavior.streakDays);
    }

    // High-context positive reinforcement
    if (isHighContext) {
      return _positiveReinforcementNudge(tx);
    }

    // Low-context gentle encouragement
    if (isLowContext) {
      return _contextEncouragementNudge(tx);
    }

    return null;
  }

  String _streakNudge(int days) {
    final messages = [
      '🔥 $days-day logging streak! You\'re building great financial awareness.',
      '🎯 $days days in a row! Consistency is the key to financial clarity.',
      '⭐ Amazing — $days-day streak! Your future self will thank you.',
    ];
    return messages[days % messages.length];
  }

  String _positiveReinforcementNudge(model.Transaction tx) {
    final tags = tx.tags ?? [];
    if (tags.any((t) => t.startsWith('social:'))) {
      return '👍 Great detail! Noting who you\'re with helps me spot social spending patterns.';
    }
    if (tags.any((t) => t == 'morning' || t == 'evening' || t == 'lunch')) {
      return '👍 Nice context! Time details help me understand your spending rhythm.';
    }
    return '👍 Rich context logged! The more detail you share, the smarter your insights become.';
  }

  String _contextEncouragementNudge(model.Transaction tx) {
    final amount = tx.amount;
    if (amount > 50) {
      return '💡 Tip: Adding details like where or who helps me give better insights on larger purchases.';
    }
    return '💡 Tip: Try saying "coffee with Sarah at Starbucks" — the extra context powers smarter insights!';
  }

  // ---------------------------------------------------------------------------
  // Nudge state persistence
  // ---------------------------------------------------------------------------

  Future<_NudgeState> _loadNudgeState(String userId) async {
    final doc = await _nudgeStateRef(userId).get();
    if (!doc.exists) return _NudgeState();
    final data = doc.data() as Map<String, dynamic>;
    return _NudgeState(
      lastNudgeDate: data['last_nudge_date'] != null
          ? DateTime.tryParse(data['last_nudge_date'])
          : null,
      nudgeCountToday: data['nudge_count_today'] as int? ?? 0,
      txSinceLastNudge: data['tx_since_last_nudge'] as int? ?? 0,
    );
  }

  Future<void> _incrementTxCounter(String userId, _NudgeState state) async {
    // Reset daily counter if it's a new day
    final resetDaily = !_isToday(state.lastNudgeDate);
    await _nudgeStateRef(userId).set({
      'last_nudge_date': state.lastNudgeDate?.toIso8601String(),
      'nudge_count_today': resetDaily ? 0 : state.nudgeCountToday,
      'tx_since_last_nudge': state.txSinceLastNudge + 1,
    });
  }

  Future<void> _recordNudge(String userId, _NudgeState state) async {
    final resetDaily = !_isToday(state.lastNudgeDate);
    await _nudgeStateRef(userId).set({
      'last_nudge_date': DateTime.now().toIso8601String(),
      'nudge_count_today': resetDaily ? 1 : state.nudgeCountToday + 1,
      'tx_since_last_nudge': 0,
    });
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _NudgeState {
  final DateTime? lastNudgeDate;
  final int nudgeCountToday;
  final int txSinceLastNudge;

  _NudgeState({
    this.lastNudgeDate,
    this.nudgeCountToday = 0,
    this.txSinceLastNudge = 0,
  });
}
