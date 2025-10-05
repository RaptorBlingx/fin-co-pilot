import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../services/report_generator_agent.dart';
import '../../../../services/pdf_export_service.dart';
import '../../../../services/csv_export_service.dart';
import '../../../../services/auth_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportGeneratorAgent _reportAgent = ReportGeneratorAgent();
  final AuthService _authService = AuthService();

  bool _isGenerating = false;
  Map<String, dynamic>? _currentReport;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: _currentReport == null
          ? _buildSelectPeriod()
          : _buildReportView(),
    );
  }

  Widget _buildSelectPeriod() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Generate Financial Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Export your spending data as PDF or CSV',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Current month button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : () => _generateReport(),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.calendar_today),
                label: Text(_isGenerating ? 'Generating...' : 'This Month'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Last month button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isGenerating
                    ? null
                    : () => _generateReport(previousMonth: true),
                icon: const Icon(Icons.history),
                label: const Text('Last Month'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportView() {
    final stats = _currentReport!['statistics'] as Map<String, dynamic>;
    final period = _currentReport!['period'] as Map<String, dynamic>;
    final currency = _currentReport!['currency'] as String;
    final summary = _currentReport!['summary'] as String;

    return Column(
      children: [
        // Header with export buttons
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _currentReport = null),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${period['month_name']} ${period['year']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${stats['transaction_count']} transactions',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportPdf(),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportCsv(),
                      icon: const Icon(Icons.table_chart, size: 18),
                      label: const Text('CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Report content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Key metrics
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildMetricRow(
                        'Total Spent',
                        '$currency ${stats['total_spent'].toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                      ),
                      const Divider(),
                      _buildMetricRow(
                        'Transactions',
                        '${stats['transaction_count']}',
                        Icons.receipt_long,
                      ),
                      const Divider(),
                      _buildMetricRow(
                        'Daily Average',
                        '$currency ${stats['daily_average'].toStringAsFixed(2)}',
                        Icons.trending_up,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // AI Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            'AI Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        summary,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Spending by Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildCategoryList(stats, currency),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Top merchants
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Merchants',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildMerchantList(stats, currency),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryList(
    Map<String, dynamic> stats,
    String currency,
  ) {
    final byCategory = stats['by_category'] as Map<String, Map<String, dynamic>>;
    final sortedCategories = byCategory.entries.toList()
      ..sort((a, b) => (b.value['total'] as double)
          .compareTo(a.value['total'] as double));

    return sortedCategories.map((entry) {
      final percentage = entry.value['percentage'] as double;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key[0].toUpperCase() + entry.key.substring(1),
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  '$currency ${entry.value['total'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildMerchantList(
    Map<String, dynamic> stats,
    String currency,
  ) {
    final topMerchants = stats['top_merchants'] as List;

    return topMerchants.take(5).map((merchant) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.store, size: 18, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                merchant['merchant'],
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              '$currency ${merchant['amount'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _generateReport({bool previousMonth = false}) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isGenerating = true);

    try {
      final now = DateTime.now();
      final targetDate = previousMonth
          ? DateTime(now.year, now.month - 1)
          : DateTime(now.year, now.month);

      // TODO: Get user's actual currency from profile
      final userCurrency = 'USD';

      final report = await _reportAgent.generateMonthlyReport(
        userId: user.uid,
        year: targetDate.year,
        month: targetDate.month,
        currency: userCurrency,
        language: 'en',
      );

      if (report['success'] == true) {
        setState(() {
          _currentReport = report;
          _isGenerating = false;
        });
      } else {
        throw Exception(report['error']);
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_currentReport == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      final file = await PdfExportService.generatePdfReport(_currentReport!);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Financial Report',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportCsv() async {
    if (_currentReport == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating CSV...')),
      );

      final file = await CsvExportService.generateCsvReport(_currentReport!);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Transaction Export',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV export failed: $e')),
        );
      }
    }
  }
}