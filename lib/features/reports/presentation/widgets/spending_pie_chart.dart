import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';

class SpendingPieChart extends StatefulWidget {
  final Map<String, Map<String, dynamic>> byCategory;
  final String currency;

  const SpendingPieChart({
    super.key,
    required this.byCategory,
    required this.currency,
  });

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int _touchedIndex = -1;

  List<MapEntry<String, Map<String, dynamic>>> get _sorted =>
      widget.byCategory.entries.toList()
        ..sort((a, b) =>
            (b.value['total'] as double).compareTo(a.value['total'] as double));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: _buildSections(),
            ),
          ),
        ),
        SizedBox(height: DesignTokens.space16),
        _buildLegend(),
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    final entries = _sorted;
    return List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final entry = entries[i];
      final percentage = entry.value['percentage'] as double;
      final color = _categoryColor(i);

      return PieChartSectionData(
        color: color,
        value: percentage,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 60 : 50,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.55,
      );
    });
  }

  Widget _buildLegend() {
    final entries = _sorted;
    return Wrap(
      spacing: DesignTokens.space16,
      runSpacing: DesignTokens.space8,
      children: List.generate(entries.length.clamp(0, 6), (i) {
        final entry = entries[i];
        final name =
            entry.key[0].toUpperCase() + entry.key.substring(1);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _categoryColor(i),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: DesignTokens.space4),
            Text(
              name,
              style: context.textTheme.bodySmall,
            ),
          ],
        );
      }),
    );
  }

  Color _categoryColor(int index) {
    return AppTheme.chartPalette[index % AppTheme.chartPalette.length];
  }
}
