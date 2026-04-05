import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/constants/categories.dart';
import '../../../../services/insights_service.dart';
import '../../../../models/transaction.dart' as model;
import '../../../../shared/models/spending_insights.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/chart_theme.dart';
import '../../../../shared/widgets/animated_counter.dart';
import '../../../../shared/widgets/premium_refresh_indicator.dart';
import '../../../../core/utils/haptic_utils.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  String _getPeriodDisplayText(String period) {
    switch (period) {
      case 'week':
        return 'This Week';
      case 'year':
        return 'This Year';
      default:
        return 'This Month';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final transactionsAsync = ref.watch(periodTransactionsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: transactionsAsync.when(
          loading: () => _InsightsShimmer(),
          error: (e, _) => _ErrorState(
            onRetry: () => ref.invalidate(periodTransactionsProvider),
          ),
          data: (transactions) {
            if (transactions.isEmpty) return const NoInsightsEmpty();

            final insights =
                InsightsService.generateInsights(transactions);
            final currency = transactions.first.currency;

            return PremiumRefreshIndicator(
              onRefresh: () async {
                ref.invalidate(periodTransactionsProvider);
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Header
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.space20,
                      DesignTokens.space12,
                      DesignTokens.space20,
                      DesignTokens.space8,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => ref.read(selectedIndexProvider.notifier).state = 0,
                            child: Icon(
                              PhosphorIcons.arrowLeft(),
                              size: DesignTokens.iconMD,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.space12),
                          Text(
                            'Insights',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Period selector
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space20,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _PeriodSelector(
                        selectedPeriod: selectedPeriod,
                        onPeriodChanged: (period) {
                          HapticUtils.light();
                          ref
                              .read(selectedPeriodProvider.notifier)
                              .state = period;
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.space16),
                  ),

                  // Summary card
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space20,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _SummaryCard(
                        insights: insights,
                        currency: currency,
                        periodText:
                            _getPeriodDisplayText(selectedPeriod),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.space20),
                  ),

                  // Category breakdown
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space20,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _CategoryBreakdownChart(
                        insights: insights,
                        currency: currency,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.space20),
                  ),

                  // Spending trend
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space20,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _SpendingTrendChart(
                        transactions: transactions,
                        currency: currency,
                      ),
                    ),
                  ),

                  // Bottom padding for nav bar
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: DesignTokens.bottomNavHeight +
                          DesignTokens.space32,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final SpendingInsights insights;
  final String currency;
  final String periodText;

  const _SummaryCard({
    required this.insights,
    required this.currency,
    required this.periodText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: DesignTokens.cardPaddingLarge,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppTheme.primaryGradientDark
            : AppTheme.primaryGradient,
        borderRadius: DesignTokens.borderRadiusXXL,
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.primaryIndigo.withOpacity(isDark ? 0.15 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            periodText,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          AnimatedCounter(
            value: insights.totalSpent,
            prefix: CurrencyUtils.getCurrencySymbol(currency),
            decimalPlaces: 2,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: DesignTokens.space20),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  icon: PhosphorIcons.receipt(),
                  label: 'Transactions',
                  value: '${insights.transactionCount}',
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: _StatPill(
                  icon: PhosphorIcons.trendUp(),
                  label: 'Avg/Day',
                  value: CurrencyUtils.formatAmount(
                      insights.averagePerDay, currency),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space12,
        vertical: DesignTokens.space8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: DesignTokens.borderRadiusMD,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: DesignTokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Breakdown ────────────────────────────────────────────────

class _CategoryBreakdownChart extends StatelessWidget {
  final SpendingInsights insights;
  final String currency;

  const _CategoryBreakdownChart({
    required this.insights,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final sortedCategories = insights.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      child: Padding(
        padding: DesignTokens.cardPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: DesignTokens.space20),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Pie chart
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: sortedCategories
                            .asMap()
                            .entries
                            .map((entry) {
                          final cat = entry.value;
                          final percentage =
                              (cat.value / insights.totalSpent) * 100;
                          final categoryData =
                              AppCategories.getCategoryByName(cat.key);

                          return PieChartSectionData(
                            color: categoryData.color,
                            value: cat.value,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 48,
                            titleStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space16),
                  // Legend
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sortedCategories.take(5).map((entry) {
                        final categoryData =
                            AppCategories.getCategoryByName(entry.key);
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: categoryData.color,
                                  borderRadius:
                                      DesignTokens.borderRadiusXS,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space16),
            // Category breakdown list
            ...sortedCategories.map((entry) {
              final percentage =
                  (entry.value / insights.totalSpent) * 100;
              final categoryData =
                  AppCategories.getCategoryByName(entry.key);

              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.space4),
                child: Row(
                  children: [
                    Icon(
                      categoryData.icon,
                      size: 16,
                      color: categoryData.color,
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    Expanded(
                      child: Text(
                        entry.key[0].toUpperCase() +
                            entry.key.substring(1),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                    ),
                    const SizedBox(width: DesignTokens.space12),
                    Text(
                      CurrencyUtils.formatAmount(entry.value, currency),
                      style: AppTheme.monoAmountStyle(context).copyWith(
                            fontFeatures: [
                              const FontFeature.tabularFigures()
                            ],
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Spending Trend ────────────────────────────────────────────────────

class _SpendingTrendChart extends StatelessWidget {
  final List<model.Transaction> transactions;
  final String currency;

  const _SpendingTrendChart({
    required this.transactions,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, double> dailySpending = {};

    for (final transaction in transactions) {
      if (transaction.amount > 0) {
        final date = DateTime(
          transaction.transactionDate.year,
          transaction.transactionDate.month,
          transaction.transactionDate.day,
        );
        dailySpending[date] = (dailySpending[date] ?? 0) + transaction.amount;
      }
    }

    final sortedDates = dailySpending.keys.toList()..sort();

    return GlassCard(
      child: Padding(
        padding: DesignTokens.cardPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: DesignTokens.space20),
            if (sortedDates.isEmpty)
              SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'No expense data available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                ),
              )
            else
              _buildChart(context, sortedDates, dailySpending),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<DateTime> sortedDates,
    Map<DateTime, double> dailySpending,
  ) {
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailySpending[sortedDates[i]]!));
    }

    final maxY = dailySpending.values.reduce((a, b) => a > b ? a : b);
    final chartStyles = ChartStyles(context);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY * 1.2,
          lineBarsData: [
            chartStyles.gradientLine(spots: spots),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  return Text(
                    CurrencyUtils.formatAmount(value, currency),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval:
                    (sortedDates.length / 4).ceilToDouble().clamp(1, 100),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedDates.length) {
                    return const SizedBox.shrink();
                  }
                  final date = sortedDates[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: chartStyles.defaultGrid,
          borderData: FlBorderData(show: false),
          lineTouchData: chartStyles.lineTooltip(),
        ),
      ),
    );
  }
}

/* COMMENTED OUT - Income tracking not yet implemented in V1.0
/// Income vs Expenses Chart - Simple bar chart comparing income to expenses
class _IncomeVsExpensesChart extends StatelessWidget {
  final SpendingInsights insights;
  final String currency;

  const _IncomeVsExpensesChart({
    required this.insights,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final income = insights.totalIncome;
    final expenses = insights.totalSpent;
    final maxValue = income > expenses ? income : expenses;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Income vs Expenses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxValue * 1.2,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: Colors.green,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: expenses,
                          color: Colors.red,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            CurrencyUtils.formatAmount(value, currency),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Income', style: TextStyle(fontSize: 12));
                            case 1:
                              return const Text('Expenses', style: TextStyle(fontSize: 12));
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Income', income, Colors.green, currency),
                _buildSummaryItem('Expenses', expenses, Colors.red, currency),
                _buildSummaryItem(
                  'Net',
                  income - expenses,
                  income > expenses ? Colors.green : Colors.red,
                  currency,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, String currency) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyUtils.formatAmount(amount, currency),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
END COMMENTED OUT */

// REMOVED for V1.0 simplification:
// - class _TopMerchants (defer to V2.0)
// - class _AIInsightsSection (Tier 2 feature)
// - class _FinancialAnalystSection (Tier 2 feature)

/* COMMENTED OUT - TIER 2/3 FEATURES FOR V2.0

class _TopMerchants extends StatelessWidget {
  final SpendingInsights insights;
  final String currency;

  const _TopMerchants({required this.insights, required this.currency});

  @override
  Widget build(BuildContext context) {
    final topMerchants = insights.byMerchant.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Merchants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...topMerchants.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.store, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      CurrencyUtils.formatAmount(entry.value, currency),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AIInsightsSection extends StatelessWidget {
  final SpendingInsights insights;
  final List<model.Transaction> transactions;
  final List<String> aiInsights;
  final bool isLoading;
  final VoidCallback onGenerate;

  const _AIInsightsSection({
    required this.insights,
    required this.transactions,
    required this.aiInsights,
    required this.isLoading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'AI Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!isLoading && aiInsights.isEmpty)
                  TextButton.icon(
                    onPressed: onGenerate,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Generate'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Analyzing your spending patterns...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (aiInsights.isEmpty)
              const Text(
                'Tap "Generate" to get personalized financial insights powered by AI',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...aiInsights.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Financial Analyst Agent Insights Section with rich categorized insights
class _FinancialAnalystSection extends StatelessWidget {
  final List<FinancialInsight> insights;
  final bool isLoading;
  final VoidCallback onGenerate;

  const _FinancialAnalystSection({
    required this.insights,
    required this.isLoading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.indigo.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome, 
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Financial Analyst',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        Text(
                          'Deep spending analysis & actionable insights',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLoading && insights.isEmpty)
                    ElevatedButton.icon(
                      onPressed: onGenerate,
                      icon: const Icon(Icons.analytics, size: 18),
                      label: const Text('Analyze'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              if (isLoading)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Running deep financial analysis...',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Analyzing spending patterns, detecting anomalies, and generating actionable insights',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else if (insights.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Get AI-Powered Financial Insights',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Tap "Analyze" for deep spending analysis, anomaly detection, and personalized recommendations',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    // Insights summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _buildInsightsSummaryItem(
                            'Total Insights',
                            '${insights.length}',
                            Icons.lightbulb,
                            Colors.orange,
                          ),
                          const SizedBox(width: 16),
                          _buildInsightsSummaryItem(
                            'High Priority',
                            '${insights.where((i) => i.severity == 'high').length}',
                            Icons.priority_high,
                            Colors.red,
                          ),
                          const SizedBox(width: 16),
                          _buildInsightsSummaryItem(
                            'Savings Potential',
                            insights.fold<double>(0, (sum, i) => sum + i.potentialSavings) > 0
                                ? '\$${insights.fold<double>(0, (sum, i) => sum + i.potentialSavings).toStringAsFixed(0)}'
                                : '-',
                            Icons.savings,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Insights list
                    ...insights.map((insight) => _buildInsightCard(insight)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsSummaryItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(FinancialInsight insight) {
    final backgroundColor = _getBackgroundColor(insight.type);
    final borderColor = _getBorderColor(insight.severity);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon, title, and severity
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.typeIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              insight.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getSeverityChipColor(insight.severity),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              insight.severity.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight.timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              insight.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            
            // Suggestion (if available)
            if (insight.hasActionableSuggestion) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.tips_and_updates,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.suggestion!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Potential savings (if available)
            if (insight.hasSavingsOpportunity) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.savings,
                      size: 14,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Potential savings: ${insight.formattedSavings}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(String type) {
    switch (type.toLowerCase()) {
      case 'achievement':
        return Colors.green.shade50;
      case 'warning':
        return Colors.orange.shade50;
      case 'opportunity':
        return Colors.blue.shade50;
      case 'anomaly':
        return Colors.red.shade50;
      case 'pattern':
        return Colors.purple.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getBorderColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red.shade300;
      case 'medium':
        return Colors.orange.shade300;
      case 'low':
        return Colors.green.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getSeverityChipColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

END OF COMMENTED OUT TIER 2/3 FEATURES */

/// Improved Period Selector Widget with glass styling
class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: DesignTokens.borderRadiusMD,
        border: Border.all(
          color:
              Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildPeriodButton(
              context, 'week', 'Week', PhosphorIcons.calendarBlank()),
          _buildPeriodButton(
              context, 'month', 'Month', PhosphorIcons.calendar()),
          _buildPeriodButton(
              context, 'year', 'Year', PhosphorIcons.calendarDots()),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(
      BuildContext context, String value, String label, IconData icon) {
    final isSelected = selectedPeriod == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => onPeriodChanged(value),
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.space12,
              horizontal: DesignTokens.space8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryIndigo
                : Colors.transparent,
            borderRadius: DesignTokens.borderRadiusSM,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryIndigo.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Insights Shimmer ──────────────────────────────────────────────────

class _InsightsShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        children: const [
          SizedBox(height: DesignTokens.space48),
          CardSkeleton(),
          SizedBox(height: DesignTokens.space20),
          ChartSkeleton(),
          SizedBox(height: DesignTokens.space20),
          ChartSkeleton(),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.warning(),
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            'Unable to load insights',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: DesignTokens.space12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}