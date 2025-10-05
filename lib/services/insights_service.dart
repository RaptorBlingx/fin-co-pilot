import '../shared/models/transaction.dart' as model;
import '../shared/models/spending_insights.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'dart:convert';

class InsightsService {
  /// Generate insights from transactions
  static SpendingInsights generateInsights(List<model.Transaction> transactions) {
    if (transactions.isEmpty) {
      return SpendingInsights(
        totalSpent: 0,
        transactionCount: 0,
        byCategory: {},
        byMerchant: {},
        dailySpending: [],
        averagePerDay: 0,
        averagePerTransaction: 0,
        topCategory: '',
        topMerchant: '',
        aiInsights: [],
      );
    }

    // Calculate total
    final totalSpent = transactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    // Group by category
    final Map<String, double> byCategory = {};
    for (final transaction in transactions) {
      byCategory[transaction.category] = 
          (byCategory[transaction.category] ?? 0) + transaction.amount;
    }

    // Group by merchant
    final Map<String, double> byMerchant = {};
    for (final transaction in transactions) {
      final merchant = transaction.merchant ?? 'Unknown';
      byMerchant[merchant] = (byMerchant[merchant] ?? 0) + transaction.amount;
    }

    // Group by day
    final Map<String, DailySpending> dailyMap = {};
    for (final transaction in transactions) {
      final dateKey = '${transaction.transactionDate.year}-${transaction.transactionDate.month}-${transaction.transactionDate.day}';
      
      if (dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = DailySpending(
          date: transaction.transactionDate,
          amount: dailyMap[dateKey]!.amount + transaction.amount,
          count: dailyMap[dateKey]!.count + 1,
        );
      } else {
        dailyMap[dateKey] = DailySpending(
          date: transaction.transactionDate,
          amount: transaction.amount,
          count: 1,
        );
      }
    }

    final dailySpending = dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate averages
    final dayCount = dailySpending.length;
    final averagePerDay = dayCount > 0 ? totalSpent / dayCount : 0.0;
    final averagePerTransaction = totalSpent / transactions.length;

    // Find top category
    String topCategory = '';
    double topCategoryAmount = 0;
    byCategory.forEach((category, amount) {
      if (amount > topCategoryAmount) {
        topCategory = category;
        topCategoryAmount = amount;
      }
    });

    // Find top merchant
    String topMerchant = '';
    double topMerchantAmount = 0;
    byMerchant.forEach((merchant, amount) {
      if (amount > topMerchantAmount) {
        topMerchant = merchant;
        topMerchantAmount = amount;
      }
    });

    return SpendingInsights(
      totalSpent: totalSpent,
      transactionCount: transactions.length,
      byCategory: byCategory,
      byMerchant: byMerchant,
      dailySpending: dailySpending,
      averagePerDay: averagePerDay,
      averagePerTransaction: averagePerTransaction,
      topCategory: topCategory,
      topMerchant: topMerchant,
      aiInsights: [],
    );
  }

  /// Generate AI-powered insights using Financial Analyst Agent
  static Future<List<String>> generateAIInsights(
    List<model.Transaction> transactions,
    SpendingInsights insights,
  ) async {
    if (transactions.isEmpty) return [];

    try {
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.5-pro', // Use Pro for deep analysis
      );

      final prompt = '''
You are a personal financial analyst. Analyze this user's spending data and provide 3-5 actionable insights.

SPENDING SUMMARY:
- Total spent: \$${insights.totalSpent.toStringAsFixed(2)}
- Number of transactions: ${insights.transactionCount}
- Average per transaction: \$${insights.averagePerTransaction.toStringAsFixed(2)}
- Top category: ${insights.topCategory} (\$${insights.byCategory[insights.topCategory]?.toStringAsFixed(2)})
- Top merchant: ${insights.topMerchant}

CATEGORY BREAKDOWN:
${insights.byCategory.entries.map((e) => '- ${e.key}: \$${e.value.toStringAsFixed(2)}').join('\n')}

TOP MERCHANTS:
${insights.byMerchant.entries.take(5).map((e) => '- ${e.key}: \$${e.value.toStringAsFixed(2)}').join('\n')}

Provide insights as a JSON array of strings. Each insight should be:
- Specific and actionable
- Based on the data provided
- Helpful for improving financial health
- Concise (1-2 sentences)

Respond with ONLY a JSON array like:
["Insight 1", "Insight 2", "Insight 3"]

Do not include markdown formatting or any other text.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      // Parse JSON response
      try {
        String cleaned = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final List<dynamic> insights = jsonDecode(cleaned);
        return insights.map((i) => i.toString()).toList();
      } catch (e) {
        print('AI insights parsing error: $e');
        return [
          'Your top spending category is ${insights.topCategory}',
          'You made ${insights.transactionCount} transactions this month',
          'Your average transaction is \$${insights.averagePerTransaction.toStringAsFixed(2)}',
        ];
      }
    } catch (e) {
      print('AI insights generation error: $e');
      return [];
    }
  }

  /// Generate insights for a specific time period
  static SpendingInsights generateInsightsForPeriod(
    List<model.Transaction> allTransactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final filteredTransactions = allTransactions.where((transaction) {
      return transaction.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             transaction.transactionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    return generateInsights(filteredTransactions);
  }

  /// Get this month's insights
  static SpendingInsights getThisMonthInsights(List<model.Transaction> transactions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return generateInsightsForPeriod(transactions, startOfMonth, endOfMonth);
  }

  /// Get last month's insights for comparison
  static SpendingInsights getLastMonthInsights(List<model.Transaction> transactions) {
    final now = DateTime.now();
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);
    
    return generateInsightsForPeriod(transactions, startOfLastMonth, endOfLastMonth);
  }

  /// Get spending trend comparison between this month and last month
  static double getSpendingTrend(List<model.Transaction> transactions) {
    final thisMonth = getThisMonthInsights(transactions);
    final lastMonth = getLastMonthInsights(transactions);
    
    return thisMonth.getTrendPercentage(lastMonth);
  }

  /// Generate comprehensive insights with AI analysis
  static Future<SpendingInsights> generateComprehensiveInsights(
    List<model.Transaction> transactions,
  ) async {
    final basicInsights = generateInsights(transactions);
    
    // Generate AI insights asynchronously
    final aiInsights = await generateAIInsights(transactions, basicInsights);
    
    return SpendingInsights(
      totalSpent: basicInsights.totalSpent,
      transactionCount: basicInsights.transactionCount,
      byCategory: basicInsights.byCategory,
      byMerchant: basicInsights.byMerchant,
      dailySpending: basicInsights.dailySpending,
      averagePerDay: basicInsights.averagePerDay,
      averagePerTransaction: basicInsights.averagePerTransaction,
      topCategory: basicInsights.topCategory,
      topMerchant: basicInsights.topMerchant,
      aiInsights: aiInsights,
    );
  }
}