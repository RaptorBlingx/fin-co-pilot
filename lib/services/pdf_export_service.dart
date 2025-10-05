import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfExportService {
  /// Generate PDF report from report data
  static Future<File> generatePdfReport(Map<String, dynamic> report) async {
    try {
      print('📄 PDFExport: Starting PDF generation');
      
      final pdf = pw.Document();

      final stats = report['statistics'] as Map<String, dynamic>;
      final period = report['period'] as Map<String, dynamic>;
      final currency = report['currency'] as String;
      final summary = report['summary'] as String;

      // Page 1: Summary
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue700,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Fin Co-Pilot',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Monthly Spending Report',
                        style: const pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Period
                pw.Text(
                  '${period['month_name']} ${period['year']}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 20),

                // Key metrics
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    children: [
                      _buildMetricRow(
                        'Total Spent',
                        '$currency ${stats['total_spent'].toStringAsFixed(2)}',
                      ),
                      pw.SizedBox(height: 8),
                      _buildMetricRow(
                        'Total Transactions',
                        '${stats['transaction_count']}',
                      ),
                      pw.SizedBox(height: 8),
                      _buildMetricRow(
                        'Average Transaction',
                        '$currency ${stats['average_transaction'].toStringAsFixed(2)}',
                      ),
                      pw.SizedBox(height: 8),
                      _buildMetricRow(
                        'Daily Average',
                        '$currency ${stats['daily_average'].toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // AI Summary
                pw.Text(
                  'Executive Summary',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  summary,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                  textAlign: pw.TextAlign.justify,
                ),

                pw.Spacer(),

                // Footer
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Generated on ${DateTime.now().toLocal().toString().split(' ')[0]}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Page 2: Category Breakdown
      final byCategory = stats['by_category'] as Map<String, Map<String, dynamic>>;
      final sortedCategories = byCategory.entries.toList()
        ..sort((a, b) => (b.value['total'] as double)
            .compareTo(a.value['total'] as double));

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Spending by Category',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Category table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildTableCell('Category', isHeader: true),
                        _buildTableCell('Amount', isHeader: true),
                        _buildTableCell('Count', isHeader: true),
                        _buildTableCell('Percentage', isHeader: true),
                      ],
                    ),
                    // Rows
                    ...sortedCategories.map((entry) {
                      return pw.TableRow(
                        children: [
                          _buildTableCell(
                            entry.key[0].toUpperCase() + entry.key.substring(1),
                          ),
                          _buildTableCell(
                            '$currency ${entry.value['total'].toStringAsFixed(2)}',
                          ),
                          _buildTableCell('${entry.value['count']}'),
                          _buildTableCell(
                            '${entry.value['percentage'].toStringAsFixed(1)}%',
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Top Merchants
                pw.Text(
                  'Top Merchants',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildTableCell('Merchant', isHeader: true),
                        _buildTableCell('Amount', isHeader: true),
                        _buildTableCell('Percentage', isHeader: true),
                      ],
                    ),
                    // Rows
                    ...(stats['top_merchants'] as List).take(10).map((merchant) {
                      return pw.TableRow(
                        children: [
                          _buildTableCell(merchant['merchant']),
                          _buildTableCell(
                            '$currency ${merchant['amount'].toStringAsFixed(2)}',
                          ),
                          _buildTableCell(
                            '${merchant['percentage'].toStringAsFixed(1)}%',
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                pw.Spacer(),

                // Payment Methods (if available)
                if (stats['by_payment_method'] != null) ...[
                  pw.Text(
                    'Payment Methods',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Wrap(
                    spacing: 15,
                    runSpacing: 10,
                    children: (stats['by_payment_method'] as Map<String, dynamic>)
                        .entries
                        .map((entry) => pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue50,
                                borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(12),
                                ),
                              ),
                              child: pw.Text(
                                '${entry.key}: $currency ${entry.value.toStringAsFixed(2)}',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            );
          },
        ),
      );

      // Page 3: Transaction Details
      final transactions = report['transactions'] as List;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Transaction Details',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildTableCell('Date', isHeader: true),
                        _buildTableCell('Merchant', isHeader: true),
                        _buildTableCell('Category', isHeader: true),
                        _buildTableCell('Amount', isHeader: true),
                      ],
                    ),
                    // Rows (first 50 transactions)
                    ...transactions.take(50).map((tx) {
                      final dateValue = tx['transaction_date'];
                      final date = dateValue is String 
                          ? DateTime.parse(dateValue)
                          : (dateValue as Timestamp).toDate();
                      return pw.TableRow(
                        children: [
                          _buildTableCell(
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                            fontSize: 9,
                          ),
                          _buildTableCell(
                            tx['merchant'] ?? 'Unknown',
                            fontSize: 9,
                          ),
                          _buildTableCell(
                            tx['category'] ?? '',
                            fontSize: 9,
                          ),
                          _buildTableCell(
                            '$currency ${tx['amount'].toStringAsFixed(2)}',
                            fontSize: 9,
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                pw.Spacer(),

                if (transactions.length > 50) ...[
                  pw.Text(
                    'Showing first 50 of ${transactions.length} transactions',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 5),
                ],

                // Summary footer
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Report generated by Fin Co-Pilot',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue700),
                      ),
                      pw.Text(
                        'Page 3 of 3',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'fin_copilot_report_${period['year']}_${period['month']}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      print('📄 PDFExport: PDF generated successfully at ${file.path}');
      return file;
    } catch (e) {
      print('📄 PDFExport ERROR: $e');
      rethrow;
    }
  }

  /// Generate weekly PDF report
  static Future<File> generateWeeklyPdfReport(Map<String, dynamic> report) async {
    try {
      print('📄 PDFExport: Starting weekly PDF generation');
      
      final pdf = pw.Document();
      final stats = report['statistics'] as Map<String, dynamic>;
      final period = report['period'] as Map<String, dynamic>;
      final currency = report['currency'] as String;
      final summary = report['summary'] as String;

      // Single page for weekly report
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green700,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Fin Co-Pilot',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Weekly Spending Report',
                        style: const pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Period
                pw.Text(
                  'Week ${period['week_number']} - ${DateTime.parse(period['start_date']).toLocal().toString().split(' ')[0]} to ${DateTime.parse(period['end_date']).toLocal().toString().split(' ')[0]}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 20),

                // Key metrics
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    children: [
                      _buildMetricRow(
                        'Total Spent',
                        '$currency ${stats['total_spent'].toStringAsFixed(2)}',
                      ),
                      pw.SizedBox(height: 8),
                      _buildMetricRow(
                        'Total Transactions',
                        '${stats['transaction_count']}',
                      ),
                      pw.SizedBox(height: 8),
                      _buildMetricRow(
                        'Daily Average',
                        '$currency ${((stats['total_spent'] as double) / 7).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // AI Summary
                pw.Text(
                  'Weekly Summary',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  summary,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                  textAlign: pw.TextAlign.justify,
                ),

                pw.Spacer(),

                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Generated on ${DateTime.now().toLocal().toString().split(' ')[0]}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final startDate = DateTime.parse(period['start_date']);
      final fileName = 'fin_copilot_weekly_report_${startDate.year}_W${period['week_number']}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      print('📄 PDFExport: Weekly PDF generated successfully at ${file.path}');
      return file;
    } catch (e) {
      print('📄 PDFExport Weekly ERROR: $e');
      rethrow;
    }
  }

  static pw.Widget _buildMetricRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    double fontSize = 10,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        maxLines: isHeader ? 1 : 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }
}