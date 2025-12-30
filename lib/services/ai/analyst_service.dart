import 'package:firebase_ai/firebase_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

/// Analyst Agent - Background analysis (5% of interactions)
///
/// Per Knowledge Base: AI_AGENTS_SPECIFICATION.md
/// - Model: Gemini 2.5 Flash
/// - Temperature: 0.4 (balanced for analysis)
/// - TopK: 40
/// - TopP: 0.9
/// - MaxTokens: 1024
///
/// Purpose:
/// - Daily Money Story (9 PM scheduled)
/// - Weekly Pattern Analysis (Sunday 8 PM)
/// - Anomaly Detection (Firestore triggers)
class AnalystService {
  final GenerativeModel _model;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // System prompt from Knowledge Base: AI_AGENTS_SPECIFICATION.md
  static const String _moneyStoryPrompt = '''
You are the Analyst Agent for Fin Copilot. Generate a daily "Money Story" - a warm, narrative summary of the user's spending today.

PERSONALITY:
- Storyteller, not accountant
- Encouraging, supportive, positive
- Makes numbers feel human
- Celebrates good decisions
- Gentle on overspending

STORY STRUCTURE:
1. Opening (set the tone)
   - "Today was a [adjective] day for your wallet!"
   - Make it conversational, warm

2. Summary (quick facts)
   - Total spent today
   - Top category
   - Comparison to yesterday/last week

3. Highlights (the story)
   - Notable transactions (interesting, large, or fun)
   - Use emojis to make it visual
   - Example: "Started with \$5.50 ☕ at Starbucks"

4. Insight (the takeaway)
   - Pattern observation
   - Progress update
   - Encouragement

5. Budget status (the reality check)
   - Week/month progress
   - Frame positively even if over

RULES:
- Keep it under 150 words
- Use 3-5 emojis total
- Always end on positive note
- Never use: debt, broke, failing
- Use: building, progress, journey, growing

EXAMPLE:
"Today was a balanced day for your wallet! 🎯

You spent \$87 across 4 transactions:
• \$5.50 - Coffee ☕ Starbucks
• \$15 - Lunch 🌯 Chipotle
• \$66.50 - Groceries 🛒 Whole Foods

Groceries took the lead today (\$66.50), which is smart planning for the week ahead!

This week you're at \$342 - that's \$58 under your weekly budget. You're building great momentum! 🎉"
''';

  static const String _weeklyAnalysisPrompt = '''
You are the Analyst Agent. Analyze a week of spending and provide insights.

ANALYSIS GOALS:
1. Identify spending patterns
2. Detect anomalies or unusual behavior
3. Spot opportunities to save
4. Recognize positive trends
5. Provide actionable recommendations

OUTPUT:
Return JSON with this structure:
{
  "summary": {
    "totalSpent": 0.00,
    "avgDailySpend": 0.00,
    "topCategory": "Category",
    "transactionCount": 0
  },
  "patterns": [
    {
      "type": "peak_spending_day",
      "detail": "Most spending on Friday (\$XX)",
      "insight": "Consider planning Friday meals in advance"
    }
  ],
  "anomalies": [
    {
      "type": "unusual_transaction",
      "detail": "Large purchase at XX",
      "severity": "low|medium|high"
    }
  ],
  "opportunities": [
    {
      "category": "Coffee",
      "potential_savings": 0.00,
      "recommendation": "Try making coffee at home 3 days/week"
    }
  ],
  "positives": [
    "Spent \$50 less than last week",
    "Stayed under budget every day"
  ]
}
''';

  static const String _anomalyDetectionPrompt = '''
You are the Analyst Agent. Detect if a transaction is anomalous.

ANOMALY TYPES:
1. Unusually large amount for category
2. Unusual time (e.g., 3 AM purchase)
3. Unusual merchant for user
4. Duplicate transaction (same amount/merchant/time)
5. Suspicious pattern (many small transactions)

SEVERITY:
- low: Slightly unusual, no action needed
- medium: Notable, user should be aware
- high: Very unusual, potential fraud

OUTPUT JSON:
{
  "isAnomaly": true/false,
  "type": "large_amount|unusual_time|new_merchant|duplicate|pattern",
  "severity": "low|medium|high",
  "message": "User-friendly explanation",
  "recommendation": "What user should do"
}
''';

  AnalystService()
      : _model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.5-flash',
        );

  /// Generate Daily Money Story (called by Cloud Function at 9 PM)
  ///
  /// Per Knowledge Base: Should run daily at 9 PM via Cloud Function
  Future<Map<String, dynamic>> generateMoneyStory(
      String userId, DateTime date) async {
    try {
      // Get today's transactions
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'success': true,
          'story': '💤 Rest day for your wallet! No spending today. Sometimes the best money story is no story at all. Keep up the savings streak!',
          'highlights': {
            'totalSpent': 0.0,
            'totalIncome': 0.0,
            'topCategory': 'None',
            'transactionCount': 0,
            'budgetStatus': 'On track',
          },
        };
      }

      // Build transaction summary
      final transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'amount': data['amount'],
          'merchant': data['merchant'] ?? 'Unknown',
          'category': data['category'],
          'description': data['description'] ?? '',
        };
      }).toList();

      final totalSpent = transactions.fold<double>(
        0.0,
        (sum, txn) => sum + (txn['amount'] as num).toDouble(),
      );

      // Get week/month context
      final weekContext = await _getWeekContext(userId, date);

      // Generate story
      final prompt = '''
$_moneyStoryPrompt

TODAY'S TRANSACTIONS:
${transactions.map((t) => '- \$${t['amount']} at ${t['merchant']} (${t['category']})').join('\n')}

TOTAL: \$${totalSpent.toStringAsFixed(2)}

WEEKLY CONTEXT:
- Week total: \$${weekContext['weekTotal']}
- Budget: \$${weekContext['budget']}
- Status: ${weekContext['status']}

Generate the Money Story now (150 words max, 3-5 emojis):
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final story = response.text ?? 'Your money story for today!';

      // Calculate highlights
      final categoryTotals = <String, double>{};
      for (final txn in transactions) {
        final category = txn['category'] as String;
        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + (txn['amount'] as num).toDouble();
      }

      final topCategory = categoryTotals.entries.isNotEmpty
          ? categoryTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : 'None';

      final highlights = {
        'totalSpent': totalSpent,
        'totalIncome': 0.0,
        'topCategory': topCategory,
        'topTransaction': transactions.isNotEmpty
            ? {
                'merchant': transactions.first['merchant'],
                'amount': transactions.first['amount'],
              }
            : null,
        'transactionCount': transactions.length,
        'budgetStatus': weekContext['status'],
      };

      // Save to Firestore
      await _saveMoneyStory(userId, date, story, highlights, transactions);

      return {
        'success': true,
        'story': story,
        'highlights': highlights,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Analyze weekly patterns (called by Cloud Function Sunday 8 PM)
  Future<Map<String, dynamic>> analyzeWeeklyPatterns(
      String userId, DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('date', isLessThan: Timestamp.fromDate(weekEnd))
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'success': true,
          'summary': {
            'totalSpent': 0.0,
            'avgDailySpend': 0.0,
            'topCategory': 'None',
            'transactionCount': 0,
          },
          'patterns': [],
          'anomalies': [],
          'opportunities': [],
          'positives': ['No spending this week - excellent savings!'],
        };
      }

      // Build transaction data
      final transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'amount': data['amount'],
          'merchant': data['merchant'] ?? 'Unknown',
          'category': data['category'],
          'date': (data['date'] as Timestamp).toDate().toIso8601String(),
        };
      }).toList();

      final prompt = '''
$_weeklyAnalysisPrompt

TRANSACTIONS THIS WEEK:
${transactions.map((t) => '${t['date']}: \$${t['amount']} at ${t['merchant']} (${t['category']})').join('\n')}

Analyze and return JSON:
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '{}';

      // Parse analysis
      final analysis = _parseWeeklyAnalysis(responseText);

      // Save patterns to user_patterns collection
      await _saveWeeklyPatterns(userId, weekStart, analysis);

      return {
        'success': true,
        ...analysis,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Detect anomalies in transaction (called by Firestore trigger)
  Future<Map<String, dynamic>> detectAnomaly(
      String userId, Map<String, dynamic> transaction) async {
    try {
      // Get user's historical data (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final history = snapshot.docs.map((doc) => doc.data()).toList();

      // Calculate statistics
      final amounts =
          history.map((t) => (t['amount'] as num).toDouble()).toList();
      final avgAmount =
          amounts.isNotEmpty ? amounts.reduce((a, b) => a + b) / amounts.length : 0.0;
      final maxAmount = amounts.isNotEmpty ? amounts.reduce((a, b) => a > b ? a : b) : 0.0;

      final prompt = '''
$_anomalyDetectionPrompt

NEW TRANSACTION:
- Amount: \$${transaction['amount']}
- Merchant: ${transaction['merchant']}
- Category: ${transaction['category']}
- Time: ${transaction['date']}

USER HISTORY (30 days):
- Average transaction: \$${avgAmount.toStringAsFixed(2)}
- Max transaction: \$${maxAmount.toStringAsFixed(2)}
- Total transactions: ${history.length}

Analyze and return JSON:
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '{}';

      // Parse anomaly detection
      final anomaly = _parseAnomalyDetection(responseText);

      // If high severity, save to insights for user notification
      if (anomaly['isAnomaly'] == true &&
          anomaly['severity'] == 'high') {
        await _saveAnomalyInsight(userId, transaction, anomaly);
      }

      return {
        'success': true,
        ...anomaly,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get week context for story
  Future<Map<String, dynamic>> _getWeekContext(
      String userId, DateTime date) async {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final snapshot = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('date', isLessThan: Timestamp.fromDate(endOfWeek))
        .get();

    final weekTotal = snapshot.docs.fold<double>(
      0.0,
      (sum, doc) => sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0.0),
    );

    // Get budget (simplified - would normally check actual budget)
    const budget = 500.0;
    final status = weekTotal < budget ? 'Under budget' : 'Over budget';

    return {
      'weekTotal': weekTotal.toStringAsFixed(2),
      'budget': budget.toStringAsFixed(2),
      'status': status,
    };
  }

  /// Save Money Story to Firestore
  Future<void> _saveMoneyStory(String userId, DateTime date, String story,
      Map<String, dynamic> highlights, List<Map<String, dynamic>> transactions) async {
    await _firestore.collection('money_stories').add({
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'story': story,
      'highlights': highlights,
      'transactions': transactions.map((t) => t['merchant']).toList(),
      'generatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Save weekly patterns
  Future<void> _saveWeeklyPatterns(
      String userId, DateTime weekStart, Map<String, dynamic> analysis) async {
    await _firestore.collection('user_patterns').doc(userId).set({
      'userId': userId,
      'lastAnalysis': Timestamp.fromDate(weekStart),
      'weeklyAnalysis': analysis,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Save anomaly as insight
  Future<void> _saveAnomalyInsight(String userId,
      Map<String, dynamic> transaction, Map<String, dynamic> anomaly) async {
    await _firestore.collection('insights').add({
      'userId': userId,
      'type': 'anomaly',
      'priority': anomaly['severity'] == 'high' ? 'high' : 'medium',
      'title': 'Unusual Transaction Detected',
      'message': anomaly['message'],
      'data': {
        'transaction': transaction,
        'anomalyType': anomaly['type'],
      },
      'status': 'active',
      'generatedAt': FieldValue.serverTimestamp(),
      'generatedBy': 'analyst_agent',
    });
  }

  /// Parse weekly analysis JSON
  Map<String, dynamic> _parseWeeklyAnalysis(String responseText) {
    try {
      final jsonMatch =
          RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(responseText);
      final jsonString = jsonMatch?.group(1) ?? responseText;
      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonString);

      if (objectMatch == null) {
        throw Exception('No JSON found');
      }

      return json.decode(objectMatch.group(0)!);
    } catch (e) {
      return {
        'summary': {
          'totalSpent': 0.0,
          'avgDailySpend': 0.0,
          'topCategory': 'Unknown',
          'transactionCount': 0,
        },
        'patterns': [],
        'anomalies': [],
        'opportunities': [],
        'positives': [],
      };
    }
  }

  /// Parse anomaly detection JSON
  Map<String, dynamic> _parseAnomalyDetection(String responseText) {
    try {
      final jsonMatch =
          RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(responseText);
      final jsonString = jsonMatch?.group(1) ?? responseText;
      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonString);

      if (objectMatch == null) {
        throw Exception('No JSON found');
      }

      return json.decode(objectMatch.group(0)!);
    } catch (e) {
      return {
        'isAnomaly': false,
        'type': 'unknown',
        'severity': 'low',
        'message': 'Analysis unavailable',
        'recommendation': 'No action needed',
      };
    }
  }
}
