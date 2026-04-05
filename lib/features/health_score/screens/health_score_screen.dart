import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../models/financial_health_score.dart';
import '../../../services/financial_health_score_service.dart';
import '../../../services/auth_service.dart';
import 'health_score_breakdown_screen.dart';

class HealthScoreScreen extends StatefulWidget {
  const HealthScoreScreen({super.key});

  @override
  State<HealthScoreScreen> createState() => _HealthScoreScreenState();
}

class _HealthScoreScreenState extends State<HealthScoreScreen> {
  final _healthScoreService = FinancialHealthScoreService();
  final _authService = AuthService();

  FinancialHealthScore? _score;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Please sign in to view your health score';
          _isLoading = false;
        });
        return;
      }

      final score = await _healthScoreService.calculateScore(user.uid);
      if (mounted) {
        setState(() {
          _score = score;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not calculate your health score. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Health Score')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CardSkeleton(),
              SizedBox(height: DesignTokens.space16),
              const CardSkeleton(),
            ],
          ),
        ),
      );
    }

    if (_error != null || _score == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Health Score')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.warningCircle(),
                  size: 48,
                  color: AppTheme.rose500,
                ),
                SizedBox(height: DesignTokens.space16),
                Text(
                  _error ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge,
                ),
                SizedBox(height: DesignTokens.space16),
                PremiumButton(
                  onPressed: _loadScore,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.arrowClockwise(), size: DesignTokens.iconSM),
                      SizedBox(width: DesignTokens.space8),
                      const Text('Try Again'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return HealthScoreBreakdownScreen(score: _score!);
  }
}
