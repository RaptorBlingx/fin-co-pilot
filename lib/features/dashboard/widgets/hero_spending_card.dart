import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';

class HeroSpendingCard extends StatelessWidget {
  final double monthlySpent;
  final double monthlyBudget;
  final String currency;
  final List<double> weeklySpending; // Last 7 days for sparkline

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
    final percentage = (monthlySpent / monthlyBudget * 100).clamp(0, 100);
    final isOverBudget = monthlySpent > monthlyBudget;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.35, // 35% of screen
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryIndigo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Month',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getMonthName(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Big spending number
          Text(
            CurrencyUtils.formatAmount(monthlySpent, currency),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Budget gauge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // Background bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Progress bar
                  FractionallySizedBox(
                    widthFactor: (percentage / 100).clamp(0, 1),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOverBudget 
                            ? AppTheme.error 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOverBudget
                        ? '${CurrencyUtils.formatAmount(remaining.abs(), currency)} over budget'
                        : '${CurrencyUtils.formatAmount(remaining, currency)} left',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'SF Mono',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isOverBudget 
                        ? Icons.warning_rounded 
                        : Icons.check_circle_rounded,
                    size: 16,
                    color: isOverBudget 
                        ? AppTheme.error 
                        : AppTheme.accentEmerald,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOverBudget ? 'Over budget' : 'On track',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isOverBudget 
                          ? AppTheme.error 
                          : AppTheme.accentEmerald,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const Spacer(),
          
          // Sparkline chart
          if (weeklySpending.isNotEmpty)
            SizedBox(
              height: 40,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (weeklySpending.length - 1).toDouble(),
                  minY: 0,
                  maxY: weeklySpending.reduce((a, b) => a > b ? a : b) * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklySpending.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.white,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.white.withOpacity(0.2),
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
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[DateTime.now().month - 1];
  }
}