import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../models/financial_health_score.dart';
import '../../../services/financial_health_score_service.dart';
import '../../../services/auth_service.dart';
import '../../health_score/screens/health_score_breakdown_screen.dart';

/// Financial Health Score Dashboard Card
///
/// Week 3 Killer Feature #3: Shows 0-100 health score
/// - Circular progress indicator
/// - Trend indicator (up/down arrow)
/// - Grade (A-F)
/// - Tap to see detailed breakdown
class FinancialHealthScoreCard extends ConsumerStatefulWidget {
  const FinancialHealthScoreCard({super.key});

  @override
  ConsumerState<FinancialHealthScoreCard> createState() =>
      _FinancialHealthScoreCardState();
}

class _FinancialHealthScoreCardState
    extends ConsumerState<FinancialHealthScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final _healthScoreService = FinancialHealthScoreService();
  final _authService = AuthService();

  FinancialHealthScore? _latestScore;
  bool _isLoading = true;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _loadLatestScore();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestScore() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final score = await _healthScoreService.getLatestScore(user.uid);

      if (mounted) {
        setState(() {
          _latestScore = score;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading health score: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _calculateNewScore() async {
    if (_isCalculating) return;

    setState(() => _isCalculating = true);

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final newScore = await _healthScoreService.calculateScore(user.uid);

      if (mounted) {
        setState(() {
          _latestScore = newScore;
          _isCalculating = false;
        });
        _animationController.reset();
        _animationController.forward();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Health Score updated: ${newScore.score}/100'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error calculating health score: $e');
      if (mounted) {
        setState(() => _isCalculating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to calculate health score'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return _buildLoadingCard(theme);
    }

    if (_latestScore == null) {
      return _buildEmptyCard(theme);
    }

    return _buildScoreCard(theme, _latestScore!);
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _calculateNewScore,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_outline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Financial Health Score',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to calculate your score',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isCalculating ? null : _calculateNewScore,
                icon: _isCalculating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calculate),
                label: Text(_isCalculating ? 'Calculating...' : 'Calculate'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(ThemeData theme, FinancialHealthScore score) {
    final scoreColor = _getScoreColor(score.score);
    final trendIcon = _getTrendIcon(score.trend);
    final trendColor = _getTrendColor(score.trend);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => HealthScoreBreakdownScreen(score: score),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Left: Circular Progress with Score
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        // Background circle
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 12,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        // Animated progress
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Transform.rotate(
                            angle: -math.pi / 2,
                            child: CircularProgressIndicator(
                              value: (score.score / 100) * _animation.value,
                              strokeWidth: 12,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation(scoreColor),
                            ),
                          ),
                        ),
                        // Score number in center
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(score.score * _animation.value).round()}',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                              ),
                              Text(
                                score.grade,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: scoreColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 24),
              // Right: Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Financial Health',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          trendIcon,
                          color: trendColor,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      score.statusMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (score.scoreChange != null) ...[
                      Text(
                        score.scoreChange! > 0
                            ? '+${score.scoreChange} points this week'
                            : '${score.scoreChange} points this week',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: score.scoreChange! > 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    HealthScoreBreakdownScreen(score: score),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('View Details'),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _isCalculating ? null : _calculateNewScore,
                          icon: _isCalculating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                          tooltip: 'Recalculate',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 70) return Colors.lightGreen;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getTrendIcon(ScoreTrend trend) {
    switch (trend) {
      case ScoreTrend.improving:
        return Icons.trending_up;
      case ScoreTrend.declining:
        return Icons.trending_down;
      case ScoreTrend.stable:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(ScoreTrend trend) {
    switch (trend) {
      case ScoreTrend.improving:
        return Colors.green;
      case ScoreTrend.declining:
        return Colors.red;
      case ScoreTrend.stable:
        return Colors.grey;
    }
  }
}
