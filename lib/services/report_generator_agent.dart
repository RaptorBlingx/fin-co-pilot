import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../shared/models/transaction.dart' as model;

class ReportGeneratorAgent {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GenerativeModel _model;

  ReportGeneratorAgent()
      : _model = FirebaseVertexAI.instance.generativeModel(
          model: 'gemini-2.5-flash',
          generationConfig: GenerationConfig(
            temperature: 0.3,
            topK: 40,
            topP: 0.8,
            maxOutputTokens: 4096,
          ),
        );

  /// Generate monthly spending report
  Future<Map<String, dynamic>> generateMonthlyReport({
    required String userId,
    required int year,
    required int month,
    required String currency,
    String language = 'en',
  }) async {
    try {
      print('📊 ReportGenerator: Generating monthly report for $year-$month');
      
      // 1. Fetch transactions for the month
      final transactions = await _fetchMonthlyTransactions(userId, year, month);

      if (transactions.isEmpty) {
        print('📊 ReportGenerator: No transactions found for period');
        return {
          'success': false,
          'error': 'No transactions found for this period',
        };
      }

      print('📊 ReportGenerator: Found ${transactions.length} transactions');

      // 2. Calculate statistics
      final stats = _calculateStats(transactions);

      // 3. Generate AI summary
      final aiSummary = await _generateAISummary(
        transactions,
        stats,
        currency,
        language,
      );

      // 4. Build report structure
      final report = {
        'success': true,
        'report_id': 'report_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': userId,
        'period': {
          'year': year,
          'month': month,
          'month_name': _getMonthName(month, language),
        },
        'generated_at': DateTime.now().toIso8601String(),
        'currency': currency,
        'language': language,
        'summary': aiSummary,
        'statistics': stats,
        'transactions': transactions.map((t) => t.toFirestore()).toList(),
      };

      print('📊 ReportGenerator: Report generated successfully');
      return report;
    } catch (e) {
      print('📊 ReportGenerator ERROR: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Fetch transactions for a specific month
  Future<List<model.Transaction>> _fetchMonthlyTransactions(
    String userId,
    int year,
    int month,
  ) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    print('📊 ReportGenerator: Fetching transactions from $startDate to $endDate');

    final snapshot = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('transaction_date', isGreaterThanOrEqualTo: startDate)
        .where('transaction_date', isLessThanOrEqualTo: endDate)
        .orderBy('transaction_date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => model.Transaction.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Calculate comprehensive statistics
  Map<String, dynamic> _calculateStats(List<model.Transaction> transactions) {
    print('📊 ReportGenerator: Calculating statistics for ${transactions.length} transactions');
    
    final totalSpent = transactions.fold<double>(
      0,
      (sum, tx) => sum + tx.amount,
    );

    // By category
    final byCategory = <String, Map<String, dynamic>>{};
    for (final tx in transactions) {
      if (!byCategory.containsKey(tx.category)) {
        byCategory[tx.category] = {
          'total': 0.0,
          'count': 0,
          'percentage': 0.0,
        };
      }
      byCategory[tx.category]!['total'] = 
          (byCategory[tx.category]!['total'] as double) + tx.amount;
      byCategory[tx.category]!['count'] = 
          (byCategory[tx.category]!['count'] as int) + 1;
    }

    // Calculate percentages
    for (final category in byCategory.keys) {
      byCategory[category]!['percentage'] = 
          totalSpent > 0 ? (byCategory[category]!['total'] as double) / totalSpent * 100 : 0.0;
    }

    // By merchant
    final byMerchant = <String, double>{};
    for (final tx in transactions) {
      final merchant = tx.merchant ?? 'Unknown';
      byMerchant[merchant] = (byMerchant[merchant] ?? 0) + tx.amount;
    }

    // Top merchants
    final topMerchants = byMerchant.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // By day of week
    final byDayOfWeek = <int, double>{};
    for (final tx in transactions) {
      final day = tx.transactionDate.weekday;
      byDayOfWeek[day] = (byDayOfWeek[day] ?? 0) + tx.amount;
    }

    // By payment method
    final byPaymentMethod = <String, double>{};
    for (final tx in transactions) {
      final method = tx.paymentMethod.isEmpty ? 'unknown' : tx.paymentMethod;
      byPaymentMethod[method] = (byPaymentMethod[method] ?? 0) + tx.amount;
    }

    // Daily average
    final daysInMonth = transactions.isNotEmpty
        ? DateTime(
            transactions.first.transactionDate.year,
            transactions.first.transactionDate.month + 1,
            0,
          ).day
        : 30;

    final stats = {
      'total_spent': totalSpent,
      'transaction_count': transactions.length,
      'average_transaction': transactions.isNotEmpty ? totalSpent / transactions.length : 0.0,
      'daily_average': totalSpent / daysInMonth,
      'by_category': byCategory,
      'top_merchants': topMerchants.take(10).map((e) => {
        'merchant': e.key,
        'amount': e.value,
        'percentage': totalSpent > 0 ? (e.value / totalSpent * 100) : 0.0,
      }).toList(),
      'by_day_of_week': byDayOfWeek,
      'by_payment_method': byPaymentMethod,
      'largest_transaction': transactions.isNotEmpty 
          ? transactions.reduce((a, b) => a.amount > b.amount ? a : b).toFirestore()
          : {},
      'smallest_transaction': transactions.isNotEmpty
          ? transactions.reduce((a, b) => a.amount < b.amount ? a : b).toFirestore()
          : {},
    };

    print('📊 ReportGenerator: Statistics calculated - Total: \$${totalSpent.toStringAsFixed(2)}');
    return stats;
  }

  /// Generate AI-powered summary
  Future<String> _generateAISummary(
    List<model.Transaction> transactions,
    Map<String, dynamic> stats,
    String currency,
    String language,
  ) async {
    try {
      print('📊 ReportGenerator: Generating AI summary in $language');
      
      final byCategory = stats['by_category'] as Map<String, Map<String, dynamic>>;
      final topMerchants = stats['top_merchants'] as List;

      final prompt = '''
Generate a concise financial summary report in $language.

PERIOD OVERVIEW:
- Total Spent: $currency ${stats['total_spent'].toStringAsFixed(2)}
- Total Transactions: ${stats['transaction_count']}
- Average Transaction: $currency ${stats['average_transaction'].toStringAsFixed(2)}
- Daily Average: $currency ${stats['daily_average'].toStringAsFixed(2)}

SPENDING BY CATEGORY:
${byCategory.entries.map((e) => '- ${e.key}: $currency ${e.value['total'].toStringAsFixed(2)} (${e.value['percentage'].toStringAsFixed(1)}%)').join('\n')}

TOP MERCHANTS:
${topMerchants.take(5).map((m) => '- ${m['merchant']}: $currency ${m['amount'].toStringAsFixed(2)}').join('\n')}

Write a 3-4 paragraph executive summary that:
1. Opens with the total spending and key highlights
2. Analyzes spending patterns and notable trends
3. Identifies the top spending categories
4. Provides actionable insights or observations

Keep it professional, concise, and data-driven. Write in $language.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final summary = response.text ?? 'Summary generation failed';
      
      print('📊 ReportGenerator: AI summary generated (${summary.length} characters)');
      return summary;
    } catch (e) {
      print('📊 ReportGenerator: AI summary generation failed: $e');
      return 'AI summary generation temporarily unavailable. Please check the detailed statistics below.';
    }
  }

  /// Get month name in specified language
  String _getMonthName(int month, String language) {
    final monthNames = {
      'en': ['January', 'February', 'March', 'April', 'May', 'June',
             'July', 'August', 'September', 'October', 'November', 'December'],
      'tr': ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
             'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'],
      'de': ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
             'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'],
      'fr': ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
             'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'],
      'es': ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
             'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'],
    };

    final names = monthNames[language] ?? monthNames['en']!;
    return names[month - 1];
  }

  /// Generate chart data for visualizations
  Map<String, dynamic> generateChartData(Map<String, dynamic> report) {
    final stats = report['statistics'] as Map<String, dynamic>;
    final byCategory = stats['by_category'] as Map<String, Map<String, dynamic>>;

    // Category pie chart data
    final categoryChartData = byCategory.entries.map((e) => {
      'label': e.key,
      'value': e.value['total'],
      'percentage': e.value['percentage'],
    }).toList()
      ..sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

    // Daily spending line chart data
    final transactions = (report['transactions'] as List)
        .map((t) => model.Transaction.fromMap(t as Map<String, dynamic>, t['id'] ?? ''))
        .toList();

    final dailySpending = <String, double>{};
    for (final tx in transactions) {
      final date = tx.transactionDate.toIso8601String().split('T')[0];
      dailySpending[date] = (dailySpending[date] ?? 0) + tx.amount;
    }

    final lineChartData = dailySpending.entries
        .map((e) => {
          'date': e.key,
          'amount': e.value,
        })
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    print('📊 ReportGenerator: Chart data generated - ${categoryChartData.length} categories, ${lineChartData.length} days');

    return {
      'category_pie_chart': categoryChartData,
      'daily_line_chart': lineChartData,
      'top_merchants_bar_chart': stats['top_merchants'],
    };
  }

  /// Generate weekly report
  Future<Map<String, dynamic>> generateWeeklyReport({
    required String userId,
    required DateTime startDate,
    required String currency,
    String language = 'en',
  }) async {
    try {
      final endDate = startDate.add(const Duration(days: 6));
      print('📊 ReportGenerator: Generating weekly report from $startDate to $endDate');

      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .where('transaction_date', isGreaterThanOrEqualTo: startDate)
          .where('transaction_date', isLessThanOrEqualTo: endDate)
          .orderBy('transaction_date', descending: true)
          .get();

      final transactions = snapshot.docs
          .map((doc) => model.Transaction.fromFirestore(doc))
          .toList();

      if (transactions.isEmpty) {
        return {
          'success': false,
          'error': 'No transactions found for this week',
        };
      }

      final stats = _calculateStats(transactions);
      final aiSummary = await _generateWeeklyAISummary(
        transactions,
        stats,
        currency,
        language,
      );

      return {
        'success': true,
        'report_id': 'weekly_report_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': userId,
        'period': {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'week_number': _getWeekNumber(startDate),
        },
        'generated_at': DateTime.now().toIso8601String(),
        'currency': currency,
        'language': language,
        'summary': aiSummary,
        'statistics': stats,
        'transactions': transactions.map((t) => t.toFirestore()).toList(),
      };
    } catch (e) {
      print('📊 ReportGenerator Weekly ERROR: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Generate AI-powered weekly summary
  Future<String> _generateWeeklyAISummary(
    List<model.Transaction> transactions,
    Map<String, dynamic> stats,
    String currency,
    String language,
  ) async {
    try {
      final byCategory = stats['by_category'] as Map<String, Map<String, dynamic>>;
      final topMerchants = stats['top_merchants'] as List;

      final prompt = '''
Generate a concise weekly financial summary in $language.

WEEK OVERVIEW:
- Total Spent: $currency ${stats['total_spent'].toStringAsFixed(2)}
- Total Transactions: ${stats['transaction_count']}
- Average Transaction: $currency ${stats['average_transaction'].toStringAsFixed(2)}
- Daily Average: $currency ${((stats['total_spent'] as double) / 7).toStringAsFixed(2)}

SPENDING BY CATEGORY:
${byCategory.entries.map((e) => '- ${e.key}: $currency ${e.value['total'].toStringAsFixed(2)} (${e.value['percentage'].toStringAsFixed(1)}%)').join('\n')}

TOP MERCHANTS:
${topMerchants.take(3).map((m) => '- ${m['merchant']}: $currency ${m['amount'].toStringAsFixed(2)}').join('\n')}

Write a 2-3 paragraph weekly spending summary that:
1. Highlights the key spending metrics for the week
2. Identifies main spending patterns and top categories
3. Provides brief insights or observations

Keep it concise and focused on weekly trends. Write in $language.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Weekly summary generation failed';
    } catch (e) {
      print('📊 ReportGenerator: Weekly AI summary generation failed: $e');
      return 'Weekly AI summary generation temporarily unavailable.';
    }
  }

  /// Get week number of the year
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }
}