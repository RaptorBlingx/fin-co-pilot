import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Consistent fl_chart styling helper that reads from the design system.
class ChartStyles {
  final BuildContext context;
  late final ColorScheme _colors;
  late final bool _isDark;

  ChartStyles(this.context) {
    _colors = Theme.of(context).colorScheme;
    _isDark = Theme.of(context).brightness == Brightness.dark;
  }

  // ─────────────── Axis / Grid ──────────────────────────────────

  FlGridData get defaultGrid => FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (_) => FlLine(
          color: _colors.outlineVariant.withOpacity(_isDark ? 0.15 : 0.25),
          strokeWidth: 0.5,
        ),
      );

  FlGridData get noGrid => const FlGridData(show: false);

  FlBorderData get noBorder => FlBorderData(show: false);

  SideTitles get bottomAxisLabels => SideTitles(
        showTitles: true,
        reservedSize: 28,
        getTitlesWidget: (value, meta) => Padding(
          padding: const EdgeInsets.only(top: DesignTokens.space8),
          child: Text(
            meta.formattedValue,
            style: _axisLabelStyle,
          ),
        ),
      );

  SideTitles get leftAxisLabels => SideTitles(
        showTitles: true,
        reservedSize: 42,
        getTitlesWidget: (value, meta) => Text(
          meta.formattedValue,
          style: _axisLabelStyle,
        ),
      );

  SideTitles get noTitles => const SideTitles(showTitles: false);

  TextStyle get _axisLabelStyle => TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _isDark ? AppTheme.slate400 : AppTheme.slate500,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ─────────────── Tooltip ──────────────────────────────────────

  LineTouchData lineTooltip({String Function(double)? formatter}) =>
      LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => _tooltipBg,
          tooltipRoundedRadius: DesignTokens.radiusSM,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space12,
            vertical: DesignTokens.space6,
          ),
          getTooltipItems: (spots) => spots
              .map((spot) => LineTooltipItem(
                    formatter?.call(spot.y) ?? spot.y.toStringAsFixed(1),
                    _tooltipTextStyle,
                  ))
              .toList(),
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (data, spots) => spots
            .map((_) => TouchedSpotIndicatorData(
                  FlLine(color: _colors.primary.withOpacity(0.3), strokeWidth: 1),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: DesignTokens.chartDotRadius,
                      color: _colors.primary,
                      strokeWidth: 2,
                      strokeColor: _isDark ? AppTheme.darkSurface : Colors.white,
                    ),
                  ),
                ))
            .toList(),
      );

  BarTouchData barTooltip({String Function(double)? formatter}) =>
      BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => _tooltipBg,
          tooltipRoundedRadius: DesignTokens.radiusSM,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space12,
            vertical: DesignTokens.space6,
          ),
          getTooltipItem: (group, gIndex, rod, rIndex) => BarTooltipItem(
            formatter?.call(rod.toY) ?? rod.toY.toStringAsFixed(0),
            _tooltipTextStyle,
          ),
        ),
      );

  PieTouchData pieTooltip() => PieTouchData(
        touchCallback: (event, response) {},
        enabled: true,
      );

  Color get _tooltipBg => _isDark
      ? AppTheme.darkSurfaceHigh.withOpacity(0.95)
      : Colors.white.withOpacity(0.95);

  TextStyle get _tooltipTextStyle => TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _colors.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ─────────────── Line Chart Helpers ───────────────────────────

  /// Creates a primary gradient line with area fill underneath.
  LineChartBarData gradientLine({
    required List<FlSpot> spots,
    Color? color,
    double strokeWidth = DesignTokens.chartStrokeWidth,
    bool showArea = true,
  }) {
    final c = color ?? _colors.primary;
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: c,
      barWidth: strokeWidth,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: showArea
          ? BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.withOpacity(_isDark ? 0.2 : 0.15),
                  c.withOpacity(0.0),
                ],
              ),
            )
          : BarAreaData(show: false),
    );
  }

  // ─────────────── Bar Chart Helpers ────────────────────────────

  /// Gradient bar with rounded top caps.
  BarChartGroupData gradientBar({
    required int x,
    required double y,
    double width = 18,
    Color? color,
  }) {
    final c = color ?? _colors.primary;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: width,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DesignTokens.radiusSM),
            topRight: Radius.circular(DesignTokens.radiusSM),
          ),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [c.withOpacity(0.6), c],
          ),
        ),
      ],
    );
  }

  // ─────────────── Pie Chart Helpers ────────────────────────────

  /// Creates a pie section with category color.
  PieChartSectionData categorySection({
    required double value,
    required double percentage,
    required Color color,
    required String title,
    bool isTouched = false,
  }) {
    final radius = isTouched ? 55.0 : 45.0;
    return PieChartSectionData(
      value: value,
      color: color,
      radius: radius,
      title: '${percentage.toStringAsFixed(0)}%',
      titleStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: isTouched ? 14 : 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFeatures: const [FontFeature.tabularFigures()],
        shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
      ),
      titlePositionPercentageOffset: 0.6,
    );
  }

  // ─────────────── Colors ───────────────────────────────────────

  /// Returns a color from the chart palette for the given index.
  Color paletteColor(int index) =>
      AppTheme.chartPalette[index % AppTheme.chartPalette.length];

  /// Returns a color from the category colors for the given index.
  Color categoryColor(int index) =>
      AppTheme.categoryColors[index % AppTheme.categoryColors.length];
}
