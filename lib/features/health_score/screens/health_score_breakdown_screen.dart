import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../models/financial_health_score.dart';
import '../../../services/financial_health_score_service.dart';
import '../../../services/auth_service.dart';

/// Health Score Breakdown Screen
///
/// Week 3 Killer Feature #3: Detailed breakdown of Financial Health Score
/// - Shows 4 components with individual scores
/// - Historical chart (last 12 weeks)
/// - Personalized recommendations
/// - Positive and negative factors
class HealthScoreBreakdownScreen extends StatefulWidget {
  final FinancialHealthScore score;

  const HealthScoreBreakdownScreen({
    super.key,
    required this.score,
  });

  @override
  State<HealthScoreBreakdownScreen> createState() =>
      _HealthScoreBreakdownScreenState();
}

class _HealthScoreBreakdownScreenState
    extends State<HealthScoreBreakdownScreen> {
  final _healthScoreService = FinancialHealthScoreService();
  final _authService = AuthService();

  List<FinancialHealthScore> _history = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final history = await _healthScoreService.getScoreHistory(user.uid);

      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      print('Error loading score history: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Health Score'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreSummary(context),
            SizedBox(height: DesignTokens.space24),
            _buildScoreBreakdown(context),
            SizedBox(height: DesignTokens.space24),
            _buildHistoryChart(context),
            SizedBox(height: DesignTokens.space24),
            _buildFactors(context),
            SizedBox(height: DesignTokens.space24),
            _buildRecommendations(context),
          ]
              .animate(interval: DesignTokens.staggerDelay)
              .fadeIn(duration: DesignTokens.durationNormal)
              .slideY(begin: 0.03, end: 0),
        ),
      ),
    );
  }

  Widget _buildScoreSummary(BuildContext context) {
    final scoreColor = _getScoreColor(widget.score.score);

    return GlassCard(
      padding: EdgeInsets.all(DesignTokens.space24),
      child: Column(
        children: [
          Text(
            'Your Score',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: DesignTokens.space8),
          Text(
            '${widget.score.score}',
            style: context.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          Text(
            'Grade ${widget.score.grade}',
            style: context.textTheme.titleLarge?.copyWith(
              color: scoreColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: DesignTokens.space16),
          Text(
            widget.score.statusMessage,
            style: context.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (widget.score.scoreChange != null) ...[
            SizedBox(height: DesignTokens.space12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.space16,
                vertical: DesignTokens.space8,
              ),
              decoration: BoxDecoration(
                color: (widget.score.scoreChange! > 0
                        ? AppTheme.accentEmerald
                        : AppTheme.rose500)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.score.scoreChange! > 0
                        ? PhosphorIcons.arrowUp()
                        : PhosphorIcons.arrowDown(),
                    color: widget.score.scoreChange! > 0
                        ? AppTheme.accentEmerald
                        : AppTheme.rose500,
                    size: 16,
                  ),
                  SizedBox(width: DesignTokens.space4),
                  Text(
                    '${widget.score.scoreChange!.abs()} points from last week',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: widget.score.scoreChange! > 0
                          ? AppTheme.accentEmerald
                          : AppTheme.rose500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(BuildContext context) {
    final breakdown = widget.score.breakdown;

    return GlassCard(
      padding: EdgeInsets.all(DesignTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Breakdown',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: DesignTokens.space16),
          _buildComponentBar(
            context,
            'Budget Adherence',
            breakdown.budgetAdherence,
            25,
            PhosphorIcons.wallet(),
            AppTheme.primaryIndigo,
          ),
          SizedBox(height: DesignTokens.space16),
          _buildComponentBar(
            context,
            'Savings Rate',
            breakdown.savingsRate,
            25,
            PhosphorIcons.piggyBank(),
            AppTheme.accentEmerald,
          ),
          SizedBox(height: DesignTokens.space16),
          _buildComponentBar(
            context,
            'Debt Management',
            breakdown.debtManagement,
            25,
            PhosphorIcons.creditCard(),
            AppTheme.amber500,
          ),
          SizedBox(height: DesignTokens.space16),
          _buildComponentBar(
            context,
            'Spending Stability',
            breakdown.spendingStability,
            25,
            PhosphorIcons.chartLine(),
            AppTheme.accentPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildComponentBar(
    BuildContext context,
    String label,
    int score,
    int maxScore,
    IconData icon,
    Color color,
  ) {
    final percentage = (score / maxScore * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: DesignTokens.iconSM, color: color),
            SizedBox(width: DesignTokens.space8),
            Expanded(
              child: Text(
                label,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$score/$maxScore',
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.space8),
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
          child: LinearProgressIndicator(
            value: score / maxScore,
            minHeight: 8,
            backgroundColor: context.colors.onSurface.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        SizedBox(height: DesignTokens.space4),
        Text(
          '$percentage%',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryChart(BuildContext context) {
    if (_isLoadingHistory) {
      return GlassCard(
        child: Container(
          height: 200,
          padding: EdgeInsets.all(DesignTokens.space24),
          child: const Center(child: CardSkeleton()),
        ),
      );
    }

    if (_history.isEmpty || _history.length < 2) {
      return GlassCard(
        padding: EdgeInsets.all(DesignTokens.space24),
        child: Column(
          children: [
            Icon(
              PhosphorIcons.chartLine(),
              size: 48,
              color: AppTheme.primaryIndigo.withOpacity(0.5),
            ),
            SizedBox(height: DesignTokens.space16),
            Text(
              'Score History',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: DesignTokens.space8),
            Text(
              'Not enough data yet. Check back next week!',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: EdgeInsets.all(DesignTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score History',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: DesignTokens.space16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: context.colors.outlineVariant,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: context.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < _history.length) {
                          final weekLabel =
                              'W${_history.length - value.toInt()}';
                          return Padding(
                            padding: EdgeInsets.only(top: DesignTokens.space8),
                            child: Text(
                              weekLabel,
                              style: context.textTheme.bodySmall,
                            ),
                          );
                        }
                        return const Text('');
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
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _history.reversed
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) => FlSpot(
                              entry.key.toDouble(),
                              entry.value.score.toDouble(),
                            ))
                        .toList(),
                    isCurved: true,
                    color: AppTheme.primaryIndigo,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.primaryIndigo,
                          strokeWidth: 2,
                          strokeColor: context.colors.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryIndigo.withOpacity(0.1),
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

  Widget _buildFactors(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(DesignTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s Affecting Your Score',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: DesignTokens.space16),
          if (widget.score.factors.positives.isNotEmpty) ...[
            _buildFactorSection(
              context,
              'Positive Factors',
              widget.score.factors.positives,
              PhosphorIcons.checkCircle(),
              AppTheme.accentEmerald,
            ),
            SizedBox(height: DesignTokens.space16),
          ],
          if (widget.score.factors.negatives.isNotEmpty) ...[
            _buildFactorSection(
              context,
              'Areas to Improve',
              widget.score.factors.negatives,
              PhosphorIcons.warning(),
              AppTheme.amber500,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFactorSection(
    BuildContext context,
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: DesignTokens.iconSM, color: color),
            SizedBox(width: DesignTokens.space8),
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.space12),
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(left: 28, bottom: DesignTokens.space8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(top: 6, right: DesignTokens.space12),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(DesignTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.lightbulb(),
                color: AppTheme.primaryIndigo,
              ),
              SizedBox(width: DesignTokens.space8),
              Text(
                'Recommendations',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space16),
          ...widget.score.factors.recommendations
              .asMap()
              .entries
              .map((entry) => Padding(
                    padding: EdgeInsets.only(bottom: DesignTokens.space12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryIndigo.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryIndigo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: DesignTokens.space12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: context.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppTheme.accentEmerald;
    if (score >= 70) return AppTheme.accentEmerald.withOpacity(0.7);
    if (score >= 60) return AppTheme.amber500;
    return AppTheme.rose500;
  }
}
