import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/light_card.dart';
import '../../../../shared/widgets/markdown_text.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../services/report_generator_agent.dart';
import '../../../../services/pdf_export_service.dart';
import '../../../../services/csv_export_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/preferences_service.dart';
import '../widgets/spending_pie_chart.dart';
import '../widgets/trend_line_chart.dart';
import '../widgets/merchant_bar_chart.dart';
import '../widgets/weekday_chart.dart';

enum _ReportPeriod { thisMonth, lastMonth, last3Months }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportGeneratorAgent _reportAgent = ReportGeneratorAgent();
  final AuthService _authService = AuthService();

  _ReportPeriod _selectedPeriod = _ReportPeriod.thisMonth;
  bool _isGenerating = false;
  Map<String, dynamic>? _currentReport;
  Map<String, dynamic>? _chartData;
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _currency = PreferencesService.getCurrency() ?? 'USD';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentReport == null ? _buildGenerateView() : _buildReportView(),
    );
  }

  // ─────────────────── Generate View ───────────────────

  Widget _buildGenerateView() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.space24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SizedBox(height: DesignTokens.space24),
              _buildPeriodChips(),
              SizedBox(height: DesignTokens.space32),
              _buildEmptyState(),
              SizedBox(height: DesignTokens.space32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: DesignTokens.space24,
          bottom: DesignTokens.space16,
        ),
        title: Text(
          'Reports',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChips() {
    return Row(
      children: _ReportPeriod.values.map((period) {
        final selected = period == _selectedPeriod;
        return Padding(
          padding: EdgeInsets.only(right: DesignTokens.space8),
          child: ChoiceChip(
            label: Text(_periodLabel(period)),
            selected: selected,
            onSelected: _isGenerating
                ? null
                : (val) {
                    if (val) setState(() => _selectedPeriod = period);
                  },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        SizedBox(height: DesignTokens.space32),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryIndigo.withOpacity(0.12),
                AppTheme.accentPurple.withOpacity(0.08),
              ],
            ),
          ),
          child: Icon(
            PhosphorIcons.chartPieSlice(PhosphorIconsStyle.fill),
            size: 40,
            color: AppTheme.primaryIndigo,
          ),
        ),
        SizedBox(height: DesignTokens.space24),
        Text(
          'Generate Financial Report',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DesignTokens.space8),
        Text(
          'Visualize your spending with interactive charts,\nAI-powered insights, and exportable reports.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.onSurface.withOpacity(0.5),
            height: 1.5,
          ),
        ),
        SizedBox(height: DesignTokens.space32),
        SizedBox(
          width: double.infinity,
          child: PremiumButton(
            onPressed: _isGenerating ? null : _handleGenerate,
            isLoading: _isGenerating,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.sparkle(), size: DesignTokens.iconSM),
                SizedBox(width: DesignTokens.space8),
                Text(_isGenerating ? 'Analyzing…' : 'Generate Report'),
              ],
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: DesignTokens.durationNormal)
        .slideY(begin: 0.04, end: 0);
  }

  // ─────────────────── Report View ───────────────────

  Widget _buildReportView() {
    final stats = _currentReport!['statistics'] as Map<String, dynamic>;
    final period = _currentReport!['period'] as Map<String, dynamic>;
    final summary = _currentReport!['summary'] as String;

    final byCategory =
        stats['by_category'] as Map<String, Map<String, dynamic>>;
    final topMerchants = stats['top_merchants'] as List;
    final byDayOfWeek =
        (stats['by_day_of_week'] as Map<dynamic, dynamic>).map((k, v) =>
            MapEntry(
                k is int ? k : int.parse(k.toString()), (v as num).toDouble()));

    final dailySpending = _buildDailySpending();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: context.colors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(PhosphorIcons.arrowLeft()),
            onPressed: () => setState(() {
              _currentReport = null;
              _chartData = null;
            }),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${period['month_name']} ${period['year']}',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${stats['transaction_count']} transactions',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(PhosphorIcons.filePdf(), size: DesignTokens.iconSM),
              onPressed: _exportPdf,
              tooltip: 'Export PDF',
            ),
            IconButton(
              icon: Icon(PhosphorIcons.table(), size: DesignTokens.iconSM),
              onPressed: _exportCsv,
              tooltip: 'Export CSV',
            ),
            SizedBox(width: DesignTokens.space4),
          ],
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.space16),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              _buildReportSections(
                stats: stats,
                summary: summary,
                byCategory: byCategory,
                topMerchants: topMerchants,
                byDayOfWeek: byDayOfWeek,
                dailySpending: dailySpending,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildReportSections({
    required Map<String, dynamic> stats,
    required String summary,
    required Map<String, Map<String, dynamic>> byCategory,
    required List<dynamic> topMerchants,
    required Map<int, double> byDayOfWeek,
    required Map<String, double> dailySpending,
  }) {
    int sectionIdx = 0;

    Widget animatedSection(Widget child) {
      return child
          .animate(delay: DesignTokens.staggerFor(sectionIdx++))
          .fadeIn(duration: DesignTokens.durationNormal)
          .slideY(begin: 0.03, end: 0);
    }

    return [
      SizedBox(height: DesignTokens.space8),

      // Hero metrics
      animatedSection(_buildHeroMetrics(stats)),
      SizedBox(height: DesignTokens.space16),

      // Spending Pie Chart
      animatedSection(_buildSection(
        icon: PhosphorIcons.chartPieSlice(),
        title: 'Spending by Category',
        child: SpendingPieChart(byCategory: byCategory, currency: _currency),
      )),
      SizedBox(height: DesignTokens.space16),

      // Daily Trend
      if (dailySpending.isNotEmpty)
        animatedSection(_buildSection(
          icon: PhosphorIcons.trendUp(),
          title: 'Daily Spending Trend',
          child: TrendLineChart(
              dailySpending: dailySpending, currency: _currency),
        )),
      if (dailySpending.isNotEmpty) SizedBox(height: DesignTokens.space16),

      // Top Merchants
      if (topMerchants.isNotEmpty)
        animatedSection(_buildSection(
          icon: PhosphorIcons.storefront(),
          title: 'Top Merchants',
          child: MerchantBarChart(
              topMerchants: topMerchants, currency: _currency),
        )),
      if (topMerchants.isNotEmpty) SizedBox(height: DesignTokens.space16),

      // Weekday Spending
      if (byDayOfWeek.isNotEmpty)
        animatedSection(_buildSection(
          icon: PhosphorIcons.calendarBlank(),
          title: 'Spending by Day of Week',
          child:
              WeekdayChart(byDayOfWeek: byDayOfWeek, currency: _currency),
        )),
      if (byDayOfWeek.isNotEmpty) SizedBox(height: DesignTokens.space16),

      // Category Breakdown
      animatedSection(_buildSection(
        icon: PhosphorIcons.listBullets(),
        title: 'Category Breakdown',
        child: _buildCategoryList(byCategory),
      )),
      SizedBox(height: DesignTokens.space16),

      // AI Summary
      animatedSection(_buildSection(
        icon: PhosphorIcons.sparkle(),
        iconColor: AppTheme.accentPurple,
        title: 'AI Insights',
        child: MarkdownText(
          data: summary,
          style: context.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
      )),
      SizedBox(height: DesignTokens.space16),

      // Detailed Metrics
      animatedSection(_buildSection(
        icon: PhosphorIcons.info(),
        title: 'Detailed Metrics',
        child: _buildDetailedMetrics(stats),
      )),

      SizedBox(height: DesignTokens.space48),
    ];
  }

  // ─────────────────── Widget Builders ───────────────────

  Widget _buildHeroMetrics(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'Total Spent',
            value:
                '$_currency ${(stats['total_spent'] as double).toStringAsFixed(2)}',
            icon: PhosphorIcons.wallet(PhosphorIconsStyle.fill),
            color: AppTheme.primaryIndigo,
          ),
        ),
        SizedBox(width: DesignTokens.space12),
        Expanded(
          child: _buildMetricCard(
            label: 'Daily Avg',
            value:
                '$_currency ${(stats['daily_average'] as double).toStringAsFixed(2)}',
            icon: PhosphorIcons.calendarBlank(PhosphorIconsStyle.fill),
            color: AppTheme.accentEmerald,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return LightCard(
      padding: EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.space6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: DesignTokens.borderRadiusSM,
            ),
            child: Icon(icon, size: DesignTokens.iconSM, color: color),
          ),
          SizedBox(height: DesignTokens.space12),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: DesignTokens.space2),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
    Color? iconColor,
  }) {
    return LightCard(
      padding: EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: DesignTokens.iconSM,
                  color: iconColor ?? AppTheme.primaryIndigo),
              SizedBox(width: DesignTokens.space8),
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space16),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryList(Map<String, Map<String, dynamic>> byCategory) {
    final sorted = byCategory.entries.toList()
      ..sort((a, b) =>
          (b.value['total'] as double).compareTo(a.value['total'] as double));

    return Column(
      children: sorted.map((entry) {
        final percentage = entry.value['percentage'] as double;
        final total = entry.value['total'] as double;
        final count = entry.value['count'] as int;
        final idx = sorted.indexOf(entry);
        final color =
            AppTheme.chartPalette[idx % AppTheme.chartPalette.length];

        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.space12),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: DesignTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key[0].toUpperCase() + entry.key.substring(1),
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$_currency ${total.toStringAsFixed(2)}',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.space4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: DesignTokens.borderRadiusFull,
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor:
                                  context.colors.onSurface.withOpacity(0.06),
                              valueColor: AlwaysStoppedAnimation(color),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        SizedBox(width: DesignTokens.space8),
                        SizedBox(
                          width: 56,
                          child: Text(
                            '${percentage.toStringAsFixed(1)}% · $count',
                            style: context.textTheme.bodySmall?.copyWith(
                              color:
                                  context.colors.onSurface.withOpacity(0.45),
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailedMetrics(Map<String, dynamic> stats) {
    final largest = stats['largest_transaction'] as Map<String, dynamic>;
    final smallest = stats['smallest_transaction'] as Map<String, dynamic>;

    return Column(
      children: [
        _buildDetailRow(
          'Transactions',
          '${stats['transaction_count']}',
          PhosphorIcons.receipt(),
        ),
        _buildDetailRow(
          'Average Transaction',
          '$_currency ${(stats['average_transaction'] as double).toStringAsFixed(2)}',
          PhosphorIcons.equals(),
        ),
        if (largest.isNotEmpty)
          _buildDetailRow(
            'Largest',
            '$_currency ${(largest['amount'] as num).toStringAsFixed(2)} — ${largest['merchant'] ?? largest['category'] ?? ''}',
            PhosphorIcons.arrowUp(),
          ),
        if (smallest.isNotEmpty)
          _buildDetailRow(
            'Smallest',
            '$_currency ${(smallest['amount'] as num).toStringAsFixed(2)} — ${smallest['merchant'] ?? smallest['category'] ?? ''}',
            PhosphorIcons.arrowDown(),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.space6),
      child: Row(
        children: [
          Icon(icon,
              size: DesignTokens.iconSM,
              color: context.colors.onSurface.withOpacity(0.4)),
          SizedBox(width: DesignTokens.space12),
          Expanded(
            child: Text(label, style: context.textTheme.bodyMedium),
          ),
          Flexible(
            child: Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── Data Helpers ───────────────────

  Map<String, double> _buildDailySpending() {
    if (_chartData != null && _chartData!['daily_line_chart'] != null) {
      final raw = _chartData!['daily_line_chart'] as List;
      return {
        for (final item in raw)
          (item['date'] as String): (item['amount'] as num).toDouble(),
      };
    }
    if (_currentReport == null) return {};
    final transactions = _currentReport!['transactions'] as List?;
    if (transactions == null) return {};

    final daily = <String, double>{};
    for (final tx in transactions) {
      final dateVal = tx['transaction_date'];
      DateTime date;
      if (dateVal is String) {
        date = DateTime.parse(dateVal);
      } else {
        date = (dateVal as dynamic).toDate();
      }
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      daily[key] = (daily[key] ?? 0) + (tx['amount'] as num).toDouble();
    }
    return daily;
  }

  String _periodLabel(_ReportPeriod period) {
    switch (period) {
      case _ReportPeriod.thisMonth:
        return 'This Month';
      case _ReportPeriod.lastMonth:
        return 'Last Month';
      case _ReportPeriod.last3Months:
        return 'Last 3 Months';
    }
  }

  // ─────────────────── Actions ───────────────────

  Future<void> _handleGenerate() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isGenerating = true);

    try {
      final now = DateTime.now();
      late DateTime targetDate;

      switch (_selectedPeriod) {
        case _ReportPeriod.thisMonth:
          targetDate = DateTime(now.year, now.month);
          break;
        case _ReportPeriod.lastMonth:
          targetDate = DateTime(now.year, now.month - 1);
          break;
        case _ReportPeriod.last3Months:
          targetDate = DateTime(now.year, now.month);
          break;
      }

      final report = await _reportAgent.generateMonthlyReport(
        userId: user.uid,
        year: targetDate.year,
        month: targetDate.month,
        currency: _currency,
        language: PreferencesService.getLanguage() ?? 'en',
      );

      if (report['success'] == true) {
        final charts = _reportAgent.generateChartData(report);
        setState(() {
          _currentReport = report;
          _chartData = charts;
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
        const SnackBar(content: Text('Generating PDF…')),
      );

      final file =
          await PdfExportService.generatePdfReport(_currentReport!);

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
        const SnackBar(content: Text('Generating CSV…')),
      );

      final file =
          await CsvExportService.generateCsvReport(_currentReport!);

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