import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';

class TrendLineChart extends StatelessWidget {
  final Map<String, double> dailySpending;
  final String currency;

  const TrendLineChart({
    super.key,
    required this.dailySpending,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (dailySpending.isEmpty) return const SizedBox.shrink();

    final sorted = dailySpending.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxY = sorted.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    final gridMax = (maxY * 1.2).ceilToDouble();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: gridMax > 0 ? gridMax / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: context.colors.onSurface.withOpacity(0.06),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _formatAmount(value),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (sorted.length / 5).ceilToDouble().clamp(1, 7),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  final date = sorted[idx].key; // yyyy-mm-dd
                  final day = date.split('-').last;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      day,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (sorted.length - 1).toDouble(),
          minY: 0,
          maxY: gridMax,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.primaryIndigo,
              tooltipRoundedRadius: DesignTokens.radiusSM,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final idx = spot.x.toInt();
                  final date = idx < sorted.length ? sorted[idx].key : '';
                  return LineTooltipItem(
                    '$date\n$currency ${spot.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(sorted.length, (i) {
                return FlSpot(i.toDouble(), sorted[i].value);
              }),
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppTheme.primaryIndigo,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: AppTheme.primaryIndigo,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryIndigo.withOpacity(0.25),
                    AppTheme.primaryIndigo.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
