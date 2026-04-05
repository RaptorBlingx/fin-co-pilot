import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';

class WeekdayChart extends StatelessWidget {
  final Map<int, double> byDayOfWeek;
  final String currency;

  const WeekdayChart({
    super.key,
    required this.byDayOfWeek,
    required this.currency,
  });

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final maxVal = byDayOfWeek.values.fold<double>(0, (m, v) => v > m ? v : m);

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTheme.primaryIndigo,
              tooltipRoundedRadius: DesignTokens.radiusSM,
              getTooltipItem: (group, gIdx, rod, rIdx) {
                return BarTooltipItem(
                  '${_dayLabels[group.x]}\n$currency ${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= 7) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _dayLabels[idx],
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: context.colors.onSurface.withOpacity(0.5),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(7, (i) {
            // Dart DateTime weekday: 1=Mon .. 7=Sun → chart index 0..6
            final amount = byDayOfWeek[i + 1] ?? 0;
            final isMax = amount == maxVal && maxVal > 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  width: 28,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(DesignTokens.radiusSM),
                  ),
                  color: isMax
                      ? AppTheme.accentEmerald
                      : AppTheme.primaryIndigo.withOpacity(0.6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
