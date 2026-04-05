import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/animated_counter.dart';

class HeroSpendingCard extends StatelessWidget {
  final double monthlySpent;
  final double monthlyBudget;
  final String currency;
  final List<double> weeklySpending;

  const HeroSpendingCard({
    super.key,
    required this.monthlySpent,
    required this.monthlyBudget,
    required this.currency,
    required this.weeklySpending,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = monthlyBudget - monthlySpent;
    final percentage = (monthlySpent / monthlyBudget * 100).clamp(0.0, 100.0);
    final isOverBudget = monthlySpent > monthlyBudget;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppTheme.primaryGradientDark : AppTheme.primaryGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: DesignTokens.borderRadiusXXL,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryIndigo.withOpacity(isDark ? 0.2 : 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: DesignTokens.cardPaddingLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'This Month',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space12,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: DesignTokens.borderRadiusFull,
                ),
                child: Text(
                  _getMonthName(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space16),

          // Big animated spending number
          AnimatedCounter(
            value: monthlySpent,
            prefix: CurrencyUtils.getCurrencySymbol(currency),
            decimalPlaces: 2,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -1.0,
            ),
          ),

          const SizedBox(height: DesignTokens.space20),

          // Budget gauge
          _BudgetGauge(
            percentage: percentage,
            remaining: remaining,
            isOverBudget: isOverBudget,
            currency: currency,
          ),

          const SizedBox(height: DesignTokens.space16),

          // Sparkline chart
          if (weeklySpending.isNotEmpty)
            SizedBox(
              height: 40,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (weeklySpending.length - 1).toDouble(),
                  minY: 0,
                  maxY: weeklySpending.reduce((a, b) => a > b ? a : b) * 1.3,
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklySpending.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value);
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: Colors.white,
                      barWidth: DesignTokens.chartStrokeWidth,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getMonthName() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[DateTime.now().month - 1];
  }
}

class _BudgetGauge extends StatelessWidget {
  final double percentage;
  final double remaining;
  final bool isOverBudget;
  final String currency;

  const _BudgetGauge({
    required this.percentage,
    required this.remaining,
    required this.isOverBudget,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: DesignTokens.borderRadiusFull,
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: DesignTokens.borderRadiusFull,
                ),
              ),
              AnimatedFractionallySizedBox(
                duration: DesignTokens.durationNormal,
                curve: DesignTokens.curveDecelerate,
                widthFactor: (percentage / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOverBudget ? AppTheme.rose400 : Colors.white,
                    borderRadius: DesignTokens.borderRadiusFull,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.space8),

        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isOverBudget
                  ? '${CurrencyUtils.formatAmount(remaining.abs(), currency)} over budget'
                  : '${CurrencyUtils.formatAmount(remaining, currency)} left',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Animated version of FractionallySizedBox width
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final double widthFactor;
  final Widget child;

  const AnimatedFractionallySizedBox({
    super.key,
    required super.duration,
    super.curve = Curves.linear,
    required this.widthFactor,
    required this.child,
  });

  @override
  AnimatedWidgetBaseState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      child: widget.child,
    );
  }
}