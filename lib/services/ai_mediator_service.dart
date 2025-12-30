import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/couple_account.dart';
import '../models/transaction.dart' as models;

/// AI Mediator Service (Week 11 Feature)
///
/// Detects financial conflicts between couples and provides
/// supportive, constructive advice for resolution.
///
/// Features:
/// - Real-time conflict detection (<1 sec target)
/// - Pattern analysis (overspending, hidden purchases, etc.)
/// - Supportive tone always
/// - Conflict history tracking
/// - Resolution suggestions
class AIMediatorService {
  static final AIMediatorService _instance = AIMediatorService._internal();
  factory AIMediatorService() => _instance;
  AIMediatorService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gemini 2.5 Flash for fast conflict detection
  final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
    generationConfig: GenerationConfig(
      temperature: 0.7, // Balanced for empathetic responses
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 2048,
    ),
  );

  // =================================================================
  // CONFLICT DETECTION
  // =================================================================

  /// Detect conflicts between couple's spending patterns
  ///
  /// Returns null if no conflicts detected
  /// Target: <1 second detection time
  Future<CoupleConflict?> detectConflict({
    required String coupleAccountId,
    required String user1Id,
    required String user2Id,
    DateTime? sinceDate,
  }) async {
    final startTime = DateTime.now();

    try {
      print('🔍 Detecting couple conflicts...');

      // Get recent transactions for both users
      final since = sinceDate ?? DateTime.now().subtract(const Duration(days: 30));

      final user1Transactions = await _getUserTransactions(user1Id, since);
      final user2Transactions = await _getUserTransactions(user2Id, since);

      // Quick pattern checks (rule-based, <100ms)
      final quickConflict = await _quickConflictCheck(
        user1Transactions,
        user2Transactions,
        coupleAccountId,
      );

      if (quickConflict != null) {
        final elapsed = DateTime.now().difference(startTime);
        print('✅ Conflict detected in ${elapsed.inMilliseconds}ms (quick check)');
        return quickConflict;
      }

      // AI-powered deep analysis if no quick patterns found
      final aiConflict = await _aiConflictDetection(
        user1Transactions,
        user2Transactions,
        coupleAccountId,
      );

      final elapsed = DateTime.now().difference(startTime);
      print('✅ Conflict detection completed in ${elapsed.inMilliseconds}ms');

      if (elapsed.inSeconds > 1) {
        print('⚠️ Detection took longer than 1 second target');
      }

      return aiConflict;
    } catch (e) {
      print('❌ Error detecting conflicts: $e');
      return null;
    }
  }

  /// Quick rule-based conflict checks (fast)
  Future<CoupleConflict?> _quickConflictCheck(
    List<models.Transaction> user1Transactions,
    List<models.Transaction> user2Transactions,
    String coupleAccountId,
  ) async {
    // Pattern 1: Large purchase without discussion (>$500)
    for (final transaction in [...user1Transactions, ...user2Transactions]) {
      if (transaction.amount > 500 && transaction.type == models.TransactionType.expense) {
        final now = DateTime.now();
        final conflict = CoupleConflict(
          id: '${now.millisecondsSinceEpoch}_large_purchase',
          topic: 'Large Purchase Alert',
          detectedAt: now,
          mediationSummary: 'A purchase over \$${transaction.amount.toStringAsFixed(2)} was detected at ${transaction.merchant ?? 'a merchant'}. Consider discussing large purchases together to stay aligned on your financial goals.',
        );

        await _saveConflict(coupleAccountId, conflict);
        return conflict;
      }
    }

    // Pattern 2: Significant spending imbalance (>70/30 split)
    final user1Total = user1Transactions.fold<double>(
      0,
      (sum, t) => sum + (t.type == models.TransactionType.expense ? t.amount : 0),
    );
    final user2Total = user2Transactions.fold<double>(
      0,
      (sum, t) => sum + (t.type == models.TransactionType.expense ? t.amount : 0),
    );
    final total = user1Total + user2Total;

    if (total > 0) {
      final user1Percentage = (user1Total / total) * 100;
      final user2Percentage = (user2Total / total) * 100;

      if (user1Percentage > 70 || user2Percentage > 70) {
        final now = DateTime.now();
        final conflict = CoupleConflict(
          id: '${now.millisecondsSinceEpoch}_spending_imbalance',
          topic: 'Spending Imbalance Detected',
          detectedAt: now,
          mediationSummary: 'One partner is contributing ${user1Percentage > 70 ? user1Percentage.toStringAsFixed(0) : user2Percentage.toStringAsFixed(0)}% of the household spending. Consider having an open conversation about financial balance and what works best for both of you.',
        );

        await _saveConflict(coupleAccountId, conflict);
        return conflict;
      }
    }

    // Pattern 3: Excessive dining/entertainment spending
    final categoryCounts = <String, double>{};
    for (final transaction in [...user1Transactions, ...user2Transactions]) {
      if (transaction.type == models.TransactionType.expense) {
        categoryCounts[transaction.category] =
            (categoryCounts[transaction.category] ?? 0) + transaction.amount;
      }
    }

    const excessiveCategories = ['dining', 'entertainment', 'shopping'];
    for (final category in excessiveCategories) {
      final spending = categoryCounts[category] ?? 0;
      if (spending > 1000) {
        // >$1000/month in discretionary category
        final now = DateTime.now();
        final conflict = CoupleConflict(
          id: '${now.millisecondsSinceEpoch}_category_overspend',
          topic: 'High $category Spending',
          detectedAt: now,
          mediationSummary: 'You\'ve spent \$${spending.toStringAsFixed(2)} on $category this month. Consider setting a mutual budget for this category to help reach your savings goals together.',
        );

        await _saveConflict(coupleAccountId, conflict);
        return conflict;
      }
    }

    return null; // No quick conflicts found
  }

  /// AI-powered deep conflict analysis
  Future<CoupleConflict?> _aiConflictDetection(
    List<models.Transaction> user1Transactions,
    List<models.Transaction> user2Transactions,
    String coupleAccountId,
  ) async {
    if (user1Transactions.isEmpty && user2Transactions.isEmpty) {
      return null; // No data to analyze
    }

    try {
      final prompt = _buildConflictDetectionPrompt(
        user1Transactions,
        user2Transactions,
      );

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return null;
      }

      // Parse AI response
      final conflict = _parseConflictResponse(responseText, coupleAccountId);
      return conflict;
    } catch (e) {
      print('❌ Error in AI conflict detection: $e');
      return null;
    }
  }

  /// Build prompt for conflict detection
  String _buildConflictDetectionPrompt(
    List<models.Transaction> user1Transactions,
    List<models.Transaction> user2Transactions,
  ) {
    final user1Summary = _summarizeTransactions(user1Transactions);
    final user2Summary = _summarizeTransactions(user2Transactions);

    return '''
You are a supportive financial mediator helping couples manage their finances together.

Analyze these spending patterns and identify potential conflicts or areas of concern:

Partner 1 Spending:
$user1Summary

Partner 2 Spending:
$user2Summary

Look for:
1. Hidden or secretive purchases
2. Recurring overspending in certain categories
3. Misaligned financial priorities
4. Lack of communication about large purchases
5. Unequal contribution without discussion

If you find a conflict, respond with:
CONFLICT_FOUND
Topic: [brief topic, e.g., "Dining Overspending"]
Advice: [2-3 sentences of supportive, constructive advice focusing on communication and mutual goals]

If NO conflicts found, respond with:
NO_CONFLICT

Remember:
- Always be supportive and constructive
- Focus on communication and mutual understanding
- Avoid blame or judgment
- Suggest specific actionable steps
''';
  }

  /// Summarize transactions for AI analysis
  String _summarizeTransactions(List<models.Transaction> transactions) {
    if (transactions.isEmpty) return 'No transactions';

    final byCategory = <String, double>{};
    double total = 0;

    for (final transaction in transactions) {
      if (transaction.type == models.TransactionType.expense) {
        byCategory[transaction.category] =
            (byCategory[transaction.category] ?? 0) + transaction.amount;
        total += transaction.amount;
      }
    }

    final lines = <String>[
      'Total: \$${total.toStringAsFixed(2)}',
      'Categories:',
    ];

    byCategory.forEach((category, amount) {
      final percentage = (amount / total * 100).toStringAsFixed(0);
      lines.add('  - $category: \$${amount.toStringAsFixed(2)} ($percentage%)');
    });

    return lines.join('\n');
  }

  /// Parse AI conflict detection response
  CoupleConflict? _parseConflictResponse(String response, String coupleAccountId) {
    if (response.contains('NO_CONFLICT')) {
      return null;
    }

    if (!response.contains('CONFLICT_FOUND')) {
      return null;
    }

    try {
      final topicMatch = RegExp(r'Topic:\s*(.+)').firstMatch(response);
      final adviceMatch = RegExp(r'Advice:\s*(.+)', dotAll: true).firstMatch(response);

      if (topicMatch == null || adviceMatch == null) {
        return null;
      }

      final topic = topicMatch.group(1)?.trim() ?? 'Financial Concern';
      final advice = adviceMatch.group(1)?.trim() ?? 'Consider discussing this together.';

      final now = DateTime.now();
      final conflict = CoupleConflict(
        id: '${now.millisecondsSinceEpoch}_ai_detected',
        topic: topic,
        detectedAt: now,
        mediationSummary: advice,
      );

      _saveConflict(coupleAccountId, conflict);
      return conflict;
    } catch (e) {
      print('❌ Error parsing conflict response: $e');
      return null;
    }
  }

  /// Get user transactions for analysis
  Future<List<models.Transaction>> _getUserTransactions(
    String userId,
    DateTime since,
  ) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('date', descending: true)
        .limit(100)
        .get();

    return snapshot.docs
        .map((doc) => models.Transaction.fromFirestore(doc))
        .toList();
  }

  // =================================================================
  // CONFLICT MANAGEMENT
  // =================================================================

  /// Save conflict to couple account
  Future<void> _saveConflict(String coupleAccountId, CoupleConflict conflict) async {
    try {
      await _firestore.collection('couple_accounts').doc(coupleAccountId).update({
        'conflicts': FieldValue.arrayUnion([conflict.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Conflict saved to couple account');
    } catch (e) {
      print('❌ Error saving conflict: $e');
    }
  }

  /// Mark conflict as resolved
  Future<void> resolveConflict({
    required String coupleAccountId,
    required String conflictId,
  }) async {
    try {
      final docRef = _firestore.collection('couple_accounts').doc(coupleAccountId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final coupleAccount = CoupleAccount.fromFirestore(doc);
      final updatedConflicts = coupleAccount.conflicts.map((conflict) {
        if (conflict.id == conflictId) {
          return CoupleConflict(
            id: conflict.id,
            topic: conflict.topic,
            detectedAt: conflict.detectedAt,
            resolvedAt: DateTime.now(),
            mediationSummary: conflict.mediationSummary,
          );
        }
        return conflict;
      }).toList();

      await docRef.update({
        'conflicts': updatedConflicts.map((c) => c.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Conflict marked as resolved');
    } catch (e) {
      print('❌ Error resolving conflict: $e');
      rethrow;
    }
  }

  /// Get conflict history for couple
  Future<List<CoupleConflict>> getConflictHistory(String coupleAccountId) async {
    try {
      final doc = await _firestore.collection('couple_accounts').doc(coupleAccountId).get();

      if (!doc.exists) return [];

      final coupleAccount = CoupleAccount.fromFirestore(doc);
      return coupleAccount.conflicts;
    } catch (e) {
      print('❌ Error getting conflict history: $e');
      return [];
    }
  }

  /// Get active (unresolved) conflicts
  Future<List<CoupleConflict>> getActiveConflicts(String coupleAccountId) async {
    final allConflicts = await getConflictHistory(coupleAccountId);
    return allConflicts.where((c) => !c.isResolved).toList();
  }

  // =================================================================
  // MEDIATION ADVICE
  // =================================================================

  /// Generate personalized mediation advice for a conflict
  Future<String> generateMediationAdvice({
    required CoupleConflict conflict,
    required List<models.Transaction> recentTransactions,
  }) async {
    try {
      final prompt = '''
You are a supportive couples financial mediator.

Conflict: ${conflict.topic}
Current Advice: ${conflict.mediationSummary ?? 'None'}

Recent Spending Context:
${_summarizeTransactions(recentTransactions)}

Provide 3-4 specific, actionable steps the couple can take to resolve this conflict.
Focus on:
- Open communication
- Mutual understanding
- Practical solutions
- Maintaining trust

Be warm, supportive, and non-judgmental.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? conflict.mediationSummary ?? 'Consider discussing this together.';
    } catch (e) {
      print('❌ Error generating mediation advice: $e');
      return conflict.mediationSummary ?? 'Consider discussing this together.';
    }
  }
}
