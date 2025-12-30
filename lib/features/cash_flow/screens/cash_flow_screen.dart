import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/predictive_cash_flow_service.dart';
import '../../../services/auth_service.dart';

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
    final theme = Theme.of(context);
    final prediction = widget.prediction;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Flow Projection'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(theme, prediction),
            const SizedBox(height: 24),

            // Cash Flow Chart
            _buildChartSection(theme, prediction),
            const SizedBox(height: 24),

            // Key Metrics
            _buildMetricsSection(theme, prediction),
            const SizedBox(height: 24),

            // Recurring Expenses
            if (prediction.recurringExpenses.isNotEmpty) ...[
              _buildRecurringExpensesSection(theme, prediction),
              const SizedBox(height: 24),
            ],

            // Expected Income
            if (prediction.expectedIncome.isNotEmpty) ...[
              _buildExpectedIncomeSection(theme, prediction),
              const SizedBox(height: 24),
            ],

            // Affordability Calculator
            _buildAffordabilityCalculator(theme),
            const SizedBox(height: 24),

            // Tips Section
            _buildTipsSection(theme, prediction),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, CashFlowPrediction prediction) {
    final statusColor = _getStatusColor(prediction.status);
    final statusIcon = _getStatusIcon(prediction.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.statusMessage,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(prediction),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(ThemeData theme, CashFlowPrediction prediction) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '30-Day Cash Flow Projection',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Based on your spending patterns and upcoming bills',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: _buildLineChart(theme, prediction),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(theme, Colors.blue, 'Projected Balance'),
                _buildLegendItem(theme, Colors.red, 'Critical Zone'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(ThemeData theme, CashFlowPrediction prediction) {
    final projections = prediction.dailyProjections;

    // Find min and max for Y-axis
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
              color: theme.colorScheme.outlineVariant.withOpacity(0.2),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
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
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Day ${value.toInt()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
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
          // Projected balance line
          LineChartBarData(
            spots: projections.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value.balance,
              );
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
          // Zero line (critical zone)
          LineChartBarData(
            spots: [
              FlSpot(0, 0),
              FlSpot(projections.length.toDouble() - 1, 0),
            ],
            isCurved: false,
            color: Colors.red,
            barWidth: 2,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex == 0) {
                  final projection = projections[spot.x.toInt()];
                  return LineTooltipItem(
                    'Day ${spot.x.toInt()}\n\$${projection.balance.toStringAsFixed(2)}',
                    theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurface,
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

  Widget _buildLegendItem(ThemeData theme, Color color, String label) {
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
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsSection(ThemeData theme, CashFlowPrediction prediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Current Balance',
                '\$${prediction.currentBalance.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Daily Burn Rate',
                '\$${prediction.dailyBurnRate.toStringAsFixed(2)}',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Days Until \$0',
                prediction.daysUntilZero != null
                    ? '${prediction.daysUntilZero} days'
                    : 'Safe',
                Icons.calendar_today,
                prediction.daysUntilZero != null && prediction.daysUntilZero! < 7
                    ? Colors.red
                    : Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Recurring Bills',
                '${prediction.recurringExpenses.length}',
                Icons.repeat,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringExpensesSection(
    ThemeData theme,
    CashFlowPrediction prediction,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Bills',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Detected recurring expenses based on your transaction history',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        ...prediction.recurringExpenses.map((expense) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildRecurringExpenseCard(theme, expense),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecurringExpenseCard(
    ThemeData theme,
    RecurringExpense expense,
  ) {
    final daysUntil = expense.nextDueDate.difference(DateTime.now()).inDays;
    final isUpcoming = daysUntil <= 7;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUpcoming
            ? BorderSide(color: Colors.orange.withOpacity(0.3), width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isUpcoming
                ? Colors.orange.withOpacity(0.1)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.repeat,
            color: isUpcoming ? Colors.orange : theme.colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          expense.merchant,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          daysUntil > 0
              ? 'Due in $daysUntil days'
              : daysUntil == 0
                  ? 'Due today'
                  : 'Overdue',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isUpcoming ? Colors.orange : Colors.grey,
            fontWeight: isUpcoming ? FontWeight.bold : null,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getFrequencyLabel(expense.intervalDays),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectedIncomeSection(
    ThemeData theme,
    CashFlowPrediction prediction,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expected Income',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Predicted income based on your transaction patterns',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        ...prediction.expectedIncome.map((income) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildExpectedIncomeCard(theme, income),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildExpectedIncomeCard(
    ThemeData theme,
    ExpectedIncome income,
  ) {
    final daysUntil = income.nextDate.difference(DateTime.now()).inDays;

    return Card(
      elevation: 1,
      color: Colors.green.withOpacity(0.05),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.attach_money,
            color: Colors.green,
            size: 24,
          ),
        ),
        title: Text(
          income.source,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          daysUntil > 0
              ? 'Expected in $daysUntil days'
              : 'Expected today',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          '\$${income.amount.toStringAsFixed(2)}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildAffordabilityCalculator(ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Can I Afford It?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Check if you can afford a purchase without impacting your cash flow',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _affordabilityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: '0.00',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _checkAffordability,
                  child: _isCheckingAffordability
                      ? const SizedBox(
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
              const SizedBox(height: 16),
              _buildAffordabilityResult(theme, _affordabilityCheck!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAffordabilityResult(
    ThemeData theme,
    AffordabilityCheck check,
  ) {
    final color = check.isAffordable ? Colors.green : Colors.red;
    final icon = check.isAffordable ? Icons.check_circle : Icons.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  check.isAffordable
                      ? 'Yes, you can afford this!'
                      : 'Not recommended',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (check.recommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...check.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                rec,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            )),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Balance',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '\$${check.balanceAfterPurchase.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '${check.daysUntilZero} days',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: check.daysUntilZero! < 7
                              ? Colors.red
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

  Widget _buildTipsSection(ThemeData theme, CashFlowPrediction prediction) {
    final tips = _generateTips(prediction);
    if (tips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips to Improve Cash Flow',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...tips.map((tip) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              elevation: 1,
              color: Colors.blue.withOpacity(0.05),
              child: ListTile(
                leading: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue,
                ),
                title: Text(
                  tip,
                  style: theme.textTheme.bodyMedium,
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
        return Colors.red;
      case CashFlowStatus.warning:
        return Colors.orange;
      case CashFlowStatus.healthy:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(CashFlowStatus status) {
    switch (status) {
      case CashFlowStatus.critical:
        return Icons.warning;
      case CashFlowStatus.warning:
        return Icons.info_outline;
      case CashFlowStatus.healthy:
        return Icons.check_circle_outline;
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
