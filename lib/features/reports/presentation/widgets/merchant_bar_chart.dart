import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';

class MerchantBarChart extends StatelessWidget {
  final List<dynamic> topMerchants;
  final String currency;

  const MerchantBarChart({
    super.key,
    required this.topMerchants,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (topMerchants.isEmpty) return const SizedBox.shrink();

    final items = topMerchants.take(6).toList();
    final maxVal =
        items.fold<double>(0, (m, e) => (e['amount'] as double) > m ? (e['amount'] as double) : m);

    return SizedBox(
      height: items.length * 44.0 + 16,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.15,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTheme.primaryIndigo,
              tooltipRoundedRadius: DesignTokens.radiusSM,
              getTooltipItem: (group, gIdx, rod, rIdx) {
                final merchant = items[group.x.toInt()];
                return BarTooltipItem(
                  '${merchant['merchant']}\n$currency ${merchant['amount'].toStringAsFixed(2)}',
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
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= items.length) {
                    return const SizedBox.shrink();
                  }
                  final label = items[idx]['merchant'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label.length > 8 ? '${label.substring(0, 7)}…' : label,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: context.colors.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? maxVal / 3 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: context.colors.onSurface.withOpacity(0.06),
              strokeWidth: 1,
            ),
          ),
          barGroups: List.generate(items.length, (i) {
            final amount = items[i]['amount'] as double;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  width: 24,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(DesignTokens.radiusSM),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppTheme.chartPalette[i % AppTheme.chartPalette.length]
                          .withOpacity(0.7),
                      AppTheme.chartPalette[i % AppTheme.chartPalette.length],
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
