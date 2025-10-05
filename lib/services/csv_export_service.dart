import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CsvExportService {
  /// Generate CSV export from report data
  static Future<File> generateCsvReport(Map<String, dynamic> report) async {
    final transactions = report['transactions'] as List;
    final period = report['period'] as Map<String, dynamic>;

    // Build CSV rows
    final List<List<dynamic>> rows = [];

    // Header row
    rows.add([
      'Date',
      'Merchant',
      'Category',
      'Amount',
      'Currency',
      'Payment Method',
      'Description',
    ]);

    // Transaction rows
    for (final tx in transactions) {
      final dateValue = tx['transaction_date'];
      final date = dateValue is String 
          ? DateTime.parse(dateValue)
          : (dateValue as Timestamp).toDate();
      rows.add([
        '${date.day}/${date.month}/${date.year}',
        tx['merchant'] ?? 'Unknown',
        tx['category'] ?? '',
        tx['amount'].toStringAsFixed(2),
        tx['currency'] ?? '',
        tx['payment_method'] ?? '',
        tx['description'] ?? '',
      ]);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(rows);

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'fin_copilot_transactions_${period['year']}_${period['month']}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);

    return file;
  }

  /// Generate summary CSV with category breakdown
  static Future<File> generateSummaryCsv(Map<String, dynamic> report) async {
    final stats = report['statistics'] as Map<String, dynamic>;
    final byCategory = stats['by_category'] as Map<String, Map<String, dynamic>>;
    final period = report['period'] as Map<String, dynamic>;

    final List<List<dynamic>> rows = [];

    // Summary section
    rows.add(['Fin Co-Pilot Monthly Report']);
    rows.add(['Period', '${period['month_name']} ${period['year']}']);
    rows.add([]);

    rows.add(['Overall Statistics']);
    rows.add(['Total Spent', stats['total_spent'].toStringAsFixed(2)]);
    rows.add(['Total Transactions', stats['transaction_count']]);
    rows.add(['Average Transaction', stats['average_transaction'].toStringAsFixed(2)]);
    rows.add(['Daily Average', stats['daily_average'].toStringAsFixed(2)]);
    rows.add([]);

    // Category breakdown
    rows.add(['Category', 'Amount', 'Count', 'Percentage']);
    final sortedCategories = byCategory.entries.toList()
      ..sort((a, b) => (b.value['total'] as double)
          .compareTo(a.value['total'] as double));

    for (final entry in sortedCategories) {
      rows.add([
        entry.key,
        entry.value['total'].toStringAsFixed(2),
        entry.value['count'],
        '${entry.value['percentage'].toStringAsFixed(1)}%',
      ]);
    }
    rows.add([]);

    // Top merchants
    rows.add(['Top Merchants']);
    rows.add(['Merchant', 'Amount', 'Percentage']);
    for (final merchant in (stats['top_merchants'] as List).take(10)) {
      rows.add([
        merchant['merchant'],
        merchant['amount'].toStringAsFixed(2),
        '${merchant['percentage'].toStringAsFixed(1)}%',
      ]);
    }

    // Convert to CSV
    final csvString = const ListToCsvConverter().convert(rows);

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'fin_copilot_summary_${period['year']}_${period['month']}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);

    return file;
  }
}