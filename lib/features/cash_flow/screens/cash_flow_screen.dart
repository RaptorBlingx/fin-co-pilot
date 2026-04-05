import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../services/predictive_cash_flow_service.dart';
import '../../../services/auth_service.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../services/preferences_service.dart';

/// Predictive Cash Flow Detail Screen
///
/// Week 5 Killer Feature #5: Overdraft prevention
/// - 30-day cash flow projection chart
/// - Recurring expenses timeline
/// - "Can I Afford?" calculator
/// - What-if scenarios
class CashFlowScreen extends ConsumerStatefulWidget {
  final CashFlowPrediction prediction;

  const CashFlowScreen({
    super.key,
    required this.prediction,
  });

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  final _cashFlowService = PredictiveCashFlowService();
  final _authService = AuthService();
  final _affordabilityController = TextEditingController();

  AffordabilityCheck? _affordabilityCheck;
  bool _isCheckingAffordability = false;

  @override
  void dispose() {
    _affordabilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prediction = widget.prediction;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Flow Projection'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context, prediction),
            SizedBox(height: DesignTokens.space24),
            _buildChartSection(context, prediction),
            SizedBox(height: DesignTokens.space24),
            _buildMetricsSection(context, prediction),
            SizedBox(height: DesignTokens.space24),
            if (prediction.recurringExpenses.isNotEmpty) ...[
              _buildRecurringExpensesSection(context, prediction),
              SizedBox(height: DesignTokens.space24),
            ],
            if (prediction.expectedIncome.isNotEmpty) ...[
              _buildExpectedIncomeSection(context, prediction),
              SizedBox(height: DesignTokens.space24),
            ],
            _buildAffordabilityCalculator(context),
            SizedBox(height: DesignTokens.space24),
            _buildTipsSection(context, prediction),
            SizedBox(height: DesignTokens.space16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, CashFlowPrediction prediction) {
    final statusColor = _getStatusColor(prediction.status);
    final statusIcon = _getStatusIcon(prediction.status);

    return GlassCard(
      padding: EdgeInsets.all(DesignTokens.space20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 28,
            ),
          ),
          SizedBox(width: DesignTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prediction.statusMessage,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                SizedBox(height: DesignTokens.space4),
                Text(
                  _getStatusDescription(prediction),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: DesignTokens.durationNormal);
  }

  Widget _buildChartSection(BuildContext context, CashFlowPrediction prediction) {
    return GlassCard(
      padding: EdgeInsets.all(DesignTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '30-Day Cash Flow Projection',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: DesignTokens.space8),
          Text(
            'Based on your spending patterns and upcoming bills',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: DesignTokens.space24),
          SizedBox(
            height: 250,
            child: _buildLineChart(context, prediction),
          ),
          SizedBox(height: DesignTokens.space16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(context, AppTheme.primaryIndigo, 'Projected Balance'),
              _buildLegendItem(context, AppTheme.rose500, 'Critical Zone'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, CashFlowPrediction prediction) {
    final projections = prediction.dailyProjections;

    final minBalance = projections.map((p) => p.balance).reduce(
      (a, b) => a < b ? a : b,
    );
    final maxBalance = projections.map((p) => p.balance).reduce(
      (a, b) => a > b ? a : b,
    );

    final yMin = (minBalance - 100).floorToDouble();
    final yMax = (maxBalance + 100).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (yMax - yMin) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: context.colors.outlineVariant.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: context.textTheme.bodySmall?.copyWith(fontSize: 10),
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
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(top: DesignTokens.space8),
                  child: Text(
                    'Day ${value.toInt()}',
                    style: context.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: projections.length.toDouble() - 1,
        minY: yMin,
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: projections.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value.balance,
              );
            }).toList(),
            isCurved: true,
            color: AppTheme.primaryIndigo,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryIndigo.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: [
              FlSpot(0, 0),
              FlSpot(projections.length.toDouble() - 1, 0),
            ],
            isCurved: false,
            color: AppTheme.rose500,
            barWidth: 2,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: DesignTokens.radiusSM,
            tooltipPadding: EdgeInsets.all(DesignTokens.space8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex == 0) {
                  final projection = projections[spot.x.toInt()];
                  return LineTooltipItem(
                    'Day ${spot.x.toInt()}\n\$${projection.balance.toStringAsFixed(2)}',
                    context.textTheme.bodySmall!.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: DesignTokens.space8),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsSection(BuildContext context, CashFlowPrediction prediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: DesignTokens.space16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Current Balance',
                '\$${prediction.currentBalance.toStringAsFixed(2)}',
                PhosphorIcons.wallet(),
                AppTheme.primaryIndigo,
              ),
            ),
            SizedBox(width: DesignTokens.space12),
            Expanded(
              child: _buildMetricCard(
                context,
                'Daily Burn Rate',
                '\$${prediction.dailyBurnRate.toStringAsFixed(2)}',
                PhosphorIcons.fire(),
                AppTheme.amber500,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.space12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Days Until \$0',
                prediction.daysUntilZero != null
                    ? '${prediction.daysUntilZero} days'
                    : 'Safe',
                PhosphorIcons.calendarBlank(),
                prediction.daysUntilZero != null && prediction.daysUntilZero! < 7
                    ? AppTheme.rose500
                    : AppTheme.accentEmerald,
              ),
            ),
            SizedBox(width: DesignTokens.space12),
            Expanded(
              child: _buildMetricCard(
                context,
                'Recurring Bills',
                '${prediction.recurringExpenses.length}',
                PhosphorIcons.repeat(),
                AppTheme.accentPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: DesignTokens.iconMD),
          SizedBox(height: DesignTokens.space12),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: DesignTokens.space4),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringExpensesSection(
    BuildContext context,
    CashFlowPrediction prediction,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Bills',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: DesignTokens.space8),
        Text(
          'Detected recurring expenses based on your transaction history',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: DesignTokens.space16),
        ...prediction.recurringExpenses.map((expense) {
          return Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.space8),
            child: _buildRecurringExpenseCard(context, expense),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecurringExpenseCard(
    BuildContext context,
    RecurringExpense expense,
  ) {
    final daysUntil = expense.nextDueDate.difference(DateTime.now()).inDays;
    final isUpcoming = daysUntil <= 7;

    return GlassCard(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isUpcoming
                ? AppTheme.amber500.withOpacity(0.1)
                : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
          child: Icon(
            PhosphorIcons.repeat(),
            color: isUpcoming ? AppTheme.amber500 : AppTheme.primaryIndigo,
            size: DesignTokens.iconMD,
          ),
        ),
        title: Text(
          expense.merchant,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          daysUntil > 0
              ? 'Due in $daysUntil days'
              : daysUntil == 0
                  ? 'Due today'
                  : 'Overdue',
          style: context.textTheme.bodySmall?.copyWith(
            color: isUpcoming ? AppTheme.amber500 : context.colors.onSurface.withOpacity(0.5),
            fontWeight: isUpcoming ? FontWeight.bold : null,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getFrequencyLabel(expense.intervalDays),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectedIncomeSection(
    BuildContext context,
    CashFlowPrediction prediction,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expected Income',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: DesignTokens.space8),
        Text(
          'Predicted income based on your transaction patterns',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: DesignTokens.space16),
        ...prediction.expectedIncome.map((income) {
          return Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.space8),
            child: _buildExpectedIncomeCard(context, income),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildExpectedIncomeCard(
    BuildContext context,
    ExpectedIncome income,
  ) {
    final daysUntil = income.nextDate.difference(DateTime.now()).inDays;

    return GlassCard(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accentEmerald.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
          child: Icon(
            PhosphorIcons.currencyDollar(),
            color: AppTheme.accentEmerald,
            size: DesignTokens.iconMD,
          ),
        ),
        title: Text(
          income.source,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          daysUntil > 0
              ? 'Expected in $daysUntil days'
              : 'Expected today',
          style: context.textTheme.bodySmall,
        ),
        trailing: Text(
          '\$${income.amount.toStringAsFixed(2)}',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentEmerald,
          ),
        ),
      ),
    );
  }

  Widget _buildAffordabilityCalculator(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(DesignTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.calculator(),
                color: AppTheme.primaryIndigo,
                size: DesignTokens.iconMD,
              ),
              SizedBox(width: DesignTokens.space12),
              Text(
                'Can I Afford It?',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space8),
          Text(
            'Check if you can afford a purchase without impacting your cash flow',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: DesignTokens.space16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _affordabilityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '${CurrencyUtils.getCurrencySymbol(PreferencesService.getCurrency() ?? 'USD')} ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                    ),
                    hintText: '0.00',
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.space12),
              PremiumButton(
                onPressed: _checkAffordability,
                child: _isCheckingAffordability
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Check'),
              ),
            ],
          ),
          if (_affordabilityCheck != null) ...[
            SizedBox(height: DesignTokens.space16),
            _buildAffordabilityResult(context, _affordabilityCheck!),
          ],
        ],
      ),
    );
  }

  Widget _buildAffordabilityResult(
    BuildContext context,
    AffordabilityCheck check,
  ) {
    final color = check.isAffordable ? AppTheme.accentEmerald : AppTheme.rose500;
    final icon = check.isAffordable ? PhosphorIcons.checkCircle() : PhosphorIcons.warning();

    return Container(
      padding: EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: DesignTokens.iconSM),
              SizedBox(width: DesignTokens.space8),
              Expanded(
                child: Text(
                  check.isAffordable
                      ? 'Yes, you can afford this!'
                      : 'Not recommended',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (check.recommendations.isNotEmpty) ...[
            SizedBox(height: DesignTokens.space8),
            ...check.recommendations.map((rec) => Padding(
              padding: EdgeInsets.only(top: DesignTokens.space4),
              child: Text(
                rec,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.8),
                ),
              ),
            )),
          ],
          SizedBox(height: DesignTokens.space12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Balance',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '\$${check.balanceAfterPurchase.toStringAsFixed(2)}',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (check.daysUntilZero != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Days Until \$0',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '${check.daysUntilZero} days',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: check.daysUntilZero! < 7
                              ? AppTheme.rose500
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context, CashFlowPrediction prediction) {
    final tips = _generateTips(prediction);
    if (tips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips to Improve Cash Flow',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: DesignTokens.space16),
        ...tips.map((tip) {
          return Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.space8),
            child: GlassCard(
              child: ListTile(
                leading: Icon(
                  PhosphorIcons.lightbulb(),
                  color: AppTheme.primaryIndigo,
                ),
                title: Text(
                  tip,
                  style: context.textTheme.bodyMedium,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _checkAffordability() async {
    final amountText = _affordabilityController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isCheckingAffordability = true);

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final check = await _cashFlowService.canAfford(
        userId: user.uid,
        amount: amount,
      );

      if (mounted) {
        setState(() {
          _affordabilityCheck = check;
          _isCheckingAffordability = false;
        });
      }
    } catch (e) {
      print('Error checking affordability: $e');
      if (mounted) {
        setState(() => _isCheckingAffordability = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to check affordability')),
        );
      }
    }
  }

  Color _getStatusColor(CashFlowStatus status) {
    switch (status) {
      case CashFlowStatus.critical:
        return AppTheme.rose500;
      case CashFlowStatus.warning:
        return AppTheme.amber500;
      case CashFlowStatus.healthy:
        return AppTheme.accentEmerald;
    }
  }

  IconData _getStatusIcon(CashFlowStatus status) {
    switch (status) {
      case CashFlowStatus.critical:
        return PhosphorIcons.warning();
      case CashFlowStatus.warning:
        return PhosphorIcons.info();
      case CashFlowStatus.healthy:
        return PhosphorIcons.checkCircle();
    }
  }

  String _getStatusDescription(CashFlowPrediction prediction) {
    switch (prediction.status) {
      case CashFlowStatus.critical:
        return 'Your balance is projected to hit \$0 soon. Review your spending and upcoming bills.';
      case CashFlowStatus.warning:
        return 'Your cash flow is tight. Consider reducing discretionary spending.';
      case CashFlowStatus.healthy:
        return 'Your cash flow looks healthy. Keep up the good work!';
    }
  }

  /* UNUSED - Kept for future category icon feature
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'subscriptions':
        return Icons.subscriptions;
      case 'utilities':
        return Icons.bolt;
      case 'insurance':
        return Icons.shield;
      case 'rent':
      case 'housing':
        return Icons.home;
      case 'transportation':
        return Icons.directions_car;
      case 'food':
      case 'dining':
        return Icons.restaurant;
      default:
        return Icons.receipt;
    }
  }
  */

  String _getFrequencyLabel(int intervalDays) {
    if (intervalDays <= 7) {
      return 'Weekly';
    } else if (intervalDays <= 16) {
      return 'Bi-weekly';
    } else if (intervalDays <= 35) {
      return 'Monthly';
    } else {
      return 'Every $intervalDays days';
    }
  }

  List<String> _generateTips(CashFlowPrediction prediction) {
    final tips = <String>[];

    if (prediction.status == CashFlowStatus.critical) {
      tips.add('Consider postponing non-essential purchases until your next income.');
      tips.add('Review your subscriptions and cancel unused services.');
    }

    if (prediction.dailyBurnRate > 50) {
      tips.add('Your daily spending is high. Try meal planning to reduce food costs.');
    }

    if (prediction.recurringExpenses.length > 5) {
      tips.add('You have ${prediction.recurringExpenses.length} recurring expenses. Consider consolidating or reducing services.');
    }

    if (prediction.daysUntilZero != null && prediction.daysUntilZero! < 14) {
      tips.add('Set up bill payment reminders to avoid overdraft fees.');
    }

    return tips;
  }
}
