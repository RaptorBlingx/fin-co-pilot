import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../shared/models/transaction.dart';
import '../shared/models/financial_insight.dart';

class FinancialAnalystAgent {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GenerativeModel _model;

  FinancialAnalystAgent()
      : _model = FirebaseVertexAI.instance.generativeModel(
          model: 'gemini-2.5-pro',
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 8192,
          ),
        );

  /// Analyze user's spending patterns and generate insights
  Future<List<FinancialInsight>> analyzeSpending({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // 1. Fetch transactions for period
      final transactions = await _fetchTransactions(userId, startDate, endDate);

      if (transactions.isEmpty) {
        return [
          FinancialInsight(
            id: 'empty_${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            type: 'info',
            severity: 'low',
            title: 'No transactions yet',
            description: 'Start logging expenses to see insights',
            createdAt: DateTime.now(),
          ),
        ];
      }

      // 2. Fetch user's budgets
      final budgets = await _fetchBudgets(userId);

      // 3. Calculate spending stats
      final stats = _calculateStats(transactions, budgets);

      // 4. Build prompt for Gemini Pro
      final prompt = _buildAnalysisPrompt(transactions, budgets, stats);

      // 5. Call Gemini 2.5 Pro
      final response = await _model.generateContent([Content.text(prompt)]);
      final analysisText = response.text ?? '';

      // 6. Parse AI response into structured insights
      final insights = _parseInsights(analysisText, userId, stats);

      // 7. Store in Firestore
      await _storeInsights(userId, insights);

      return insights;
    } catch (e) {
      print('Financial Analyst Agent error: $e');
      return [];
    }
  }

  /// Fetch transactions for date range
  Future<List<Transaction>> _fetchTransactions(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('transaction_date', isGreaterThanOrEqualTo: startDate)
        .where('transaction_date', isLessThanOrEqualTo: endDate)
        .orderBy('transaction_date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Transaction.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Fetch user's budget settings
  Future<Map<String, double>> _fetchBudgets(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    
    if (data != null && data['budgets'] != null) {
      final budgets = data['budgets'] as Map<String, dynamic>;
      return budgets.map((key, value) => 
        MapEntry(key, (value['monthly_limit'] as num).toDouble()));
    }
    
    return {};
  }

  /// Calculate spending statistics
  Map<String, dynamic> _calculateStats(
    List<Transaction> transactions,
    Map<String, double> budgets,
  ) {
    // Total spending
    final totalSpent = transactions.fold<double>(
      0,
      (sum, tx) => sum + tx.amount,
    );

    // By category
    final byCategory = <String, double>{};
    for (final tx in transactions) {
      byCategory[tx.category] = (byCategory[tx.category] ?? 0) + tx.amount;
    }

    // Top merchants
    final merchantSpending = <String, double>{};
    for (final tx in transactions) {
      final merchant = tx.merchant ?? 'Unknown';
      merchantSpending[merchant] =
          (merchantSpending[merchant] ?? 0) + tx.amount;
    }

    final topMerchants = merchantSpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Average transaction
    final avgTransaction = transactions.isEmpty 
      ? 0.0 
      : totalSpent / transactions.length;

    // Budget performance
    final budgetPerformance = <String, Map<String, dynamic>>{};
    for (final category in byCategory.keys) {
      if (budgets.containsKey(category)) {
        final spent = byCategory[category]!;
        final budget = budgets[category]!;
        final remaining = budget - spent;
        final percentUsed = (spent / budget * 100).clamp(0, 200);

        budgetPerformance[category] = {
          'budget': budget,
          'spent': spent,
          'remaining': remaining,
          'percent_used': percentUsed,
          'status': percentUsed < 80
              ? 'on_track'
              : percentUsed < 100
                  ? 'warning'
                  : 'over',
        };
      }
    }

    // Detect anomalies (transactions significantly above average)
    final anomalies = transactions.where((tx) {
      return tx.amount > avgTransaction * 2.5;
    }).toList();

    // Recurring patterns (same merchant multiple times)
    final recurringMerchants = merchantSpending.entries
        .where((e) => transactions.where((tx) => tx.merchant == e.key).length >= 3)
        .map((e) => e.key)
        .toList();

    return {
      'total_spent': totalSpent,
      'transaction_count': transactions.length,
      'avg_transaction': avgTransaction,
      'by_category': byCategory,
      'top_merchants': topMerchants.take(5).toList(),
      'budget_performance': budgetPerformance,
      'anomalies': anomalies,
      'recurring_merchants': recurringMerchants,
    };
  }

  /// Build comprehensive prompt for Gemini Pro
  String _buildAnalysisPrompt(
    List<Transaction> transactions,
    Map<String, double> budgets,
    Map<String, dynamic> stats,
  ) {
    final byCategory = stats['by_category'] as Map<String, double>;
    final budgetPerformance = stats['budget_performance'] as Map<String, Map<String, dynamic>>;
    final anomalies = stats['anomalies'] as List<Transaction>;
    final recurringMerchants = stats['recurring_merchants'] as List<String>;

    return '''
You are a financial analyst AI. Analyze the following spending data and generate 3-5 actionable insights.

SPENDING SUMMARY:
- Total spent: \$${stats['total_spent'].toStringAsFixed(2)}
- Number of transactions: ${stats['transaction_count']}
- Average transaction: \$${stats['avg_transaction'].toStringAsFixed(2)}

SPENDING BY CATEGORY:
${byCategory.entries.map((e) => '- ${e.key}: \$${e.value.toStringAsFixed(2)} (${(e.value / stats['total_spent'] * 100).toStringAsFixed(1)}%)').join('\n')}

BUDGET PERFORMANCE:
${budgetPerformance.isEmpty ? 'No budgets set' : budgetPerformance.entries.map((e) {
  final data = e.value;
  return '- ${e.key}: \$${data['spent'].toStringAsFixed(2)} / \$${data['budget'].toStringAsFixed(2)} (${data['percent_used'].toStringAsFixed(0)}% used) - Status: ${data['status']}';
}).join('\n')}

ANOMALIES (Unusually high transactions):
${anomalies.isEmpty ? 'None detected' : anomalies.map((tx) => '- ${tx.merchant ?? 'Unknown'}: \$${tx.amount.toStringAsFixed(2)} on ${tx.transactionDate.toString().split(' ')[0]}').join('\n')}

RECURRING MERCHANTS (3+ transactions):
${recurringMerchants.isEmpty ? 'None detected' : recurringMerchants.map((m) => '- $m').join('\n')}

Generate 3-5 insights in this EXACT format (one per line):

[TYPE]|[SEVERITY]|[TITLE]|[DESCRIPTION]|[SUGGESTION]|[POTENTIAL_SAVINGS]

Where:
- TYPE: pattern, achievement, warning, opportunity, anomaly
- SEVERITY: low, medium, high
- TITLE: Short title (5-8 words)
- DESCRIPTION: One sentence explanation
- SUGGESTION: Actionable advice (one sentence)
- POTENTIAL_SAVINGS: Dollar amount if applicable, or 0

Example:
pattern|medium|Dining spending increased 25%|You spent \$450 on dining this month, up from \$360 last month|Consider meal prepping twice a week to reduce restaurant visits|80

Focus on:
1. Budget adherence (praise if on track, warn if overspending)
2. Spending patterns (increases/decreases)
3. Anomalies that need attention
4. Recurring subscriptions or wasteful spending
5. Savings opportunities

Be specific with numbers. Be encouraging but honest. Make suggestions actionable.
''';
  }

  /// Parse AI response into structured insights
  List<FinancialInsight> _parseInsights(
    String aiResponse,
    String userId,
    Map<String, dynamic> stats,
  ) {
    final insights = <FinancialInsight>[];
    final lines = aiResponse.split('\n').where((line) => line.contains('|')).toList();

    for (final line in lines) {
      try {
        final parts = line.split('|').map((p) => p.trim()).toList();
        if (parts.length >= 6) {
          insights.add(FinancialInsight(
            id: 'insight_${DateTime.now().millisecondsSinceEpoch}_${insights.length}',
            userId: userId,
            type: parts[0],
            severity: parts[1],
            title: parts[2],
            description: parts[3],
            suggestion: parts[4],
            potentialSavings: double.tryParse(parts[5]) ?? 0,
            createdAt: DateTime.now(),
          ));
        }
      } catch (e) {
        print('Error parsing insight line: $line - $e');
      }
    }

    // Fallback: if parsing failed, create basic insights from stats
    if (insights.isEmpty) {
      insights.addAll(_generateFallbackInsights(userId, stats));
    }

    return insights;
  }

  /// Generate fallback insights if AI parsing fails
  List<FinancialInsight> _generateFallbackInsights(
    String userId,
    Map<String, dynamic> stats,
  ) {
    final insights = <FinancialInsight>[];
    final budgetPerformance = stats['budget_performance'] as Map<String, Map<String, dynamic>>;

    // Budget insights
    for (final entry in budgetPerformance.entries) {
      final category = entry.key;
      final data = entry.value;
      final status = data['status'] as String;
      
      if (status == 'over') {
        insights.add(FinancialInsight(
          id: 'fallback_${DateTime.now().millisecondsSinceEpoch}_${insights.length}',
          userId: userId,
          type: 'warning',
          severity: 'high',
          title: '$category budget exceeded',
          description: 'You\'ve spent \$${data['spent'].toStringAsFixed(2)} of \$${data['budget'].toStringAsFixed(2)} budget',
          suggestion: 'Review your $category expenses and adjust spending',
          potentialSavings: (data['spent'] - data['budget']).toDouble(),
          createdAt: DateTime.now(),
        ));
      } else if (status == 'on_track') {
        insights.add(FinancialInsight(
          id: 'fallback_${DateTime.now().millisecondsSinceEpoch}_${insights.length}',
          userId: userId,
          type: 'achievement',
          severity: 'low',
          title: '$category budget on track',
          description: 'You\'re at ${data['percent_used'].toStringAsFixed(0)}% of your budget',
          suggestion: 'Keep up the great spending habits!',
          potentialSavings: 0,
          createdAt: DateTime.now(),
        ));
      }
    }

    return insights;
  }

  /// Store insights in Firestore
  Future<void> _storeInsights(
    String userId,
    List<FinancialInsight> insights,
  ) async {
    final batch = _firestore.batch();

    for (final insight in insights) {
      final docRef = _firestore.collection('insights').doc(insight.id);
      batch.set(docRef, insight.toMap());
    }

    await batch.commit();
  }
}