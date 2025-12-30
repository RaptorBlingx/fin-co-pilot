import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/predictive_cash_flow_service.dart';
import '../../../services/auth_service.dart';
import '../screens/cash_flow_screen.dart';

/// Predictive Cash Flow Dashboard Card
///
/// Week 5 Killer Feature #5: Overdraft prevention
/// - Shows "X days until $0" or "On track" message
/// - Color-coded: Red (<7 days), Yellow (<14 days), Green (healthy)
/// - Tap to see detailed chart and projections
class CashFlowCard extends ConsumerStatefulWidget {
  const CashFlowCard({super.key});

  @override
  ConsumerState<CashFlowCard> createState() => _CashFlowCardState();
}

class _CashFlowCardState extends ConsumerState<CashFlowCard> {
  final _cashFlowService = PredictiveCashFlowService();
  final _authService = AuthService();

  CashFlowPrediction? _prediction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCashFlowPrediction();
  }

  Future<void> _loadCashFlowPrediction() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final prediction = await _cashFlowService.predictCashFlow(user.uid);

      if (mounted) {
        setState(() {
          _prediction = prediction;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cash flow prediction: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return _buildLoadingCard(theme);
    }

    if (_prediction == null) {
      return const SizedBox.shrink();
    }

    return _buildPredictionCard(theme, _prediction!);
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionCard(ThemeData theme, CashFlowPrediction prediction) {
    final statusColor = _getStatusColor(prediction.status);
    final statusIcon = _getStatusIcon(prediction.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CashFlowScreen(prediction: prediction),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash Flow',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getUpdateTime(prediction.lastUpdated),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadCashFlowPrediction,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Status Message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getMessageIcon(prediction.status),
                      color: statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        prediction.statusMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStat(
                      theme,
                      'Balance',
                      '\$${prediction.currentBalance.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      theme,
                      'Daily Burn',
                      '\$${prediction.dailyBurnRate.toStringAsFixed(2)}',
                      Icons.local_fire_department,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // View Details Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (prediction.recurringExpenses.isNotEmpty)
                    Text(
                      '${prediction.recurringExpenses.length} bills upcoming',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              CashFlowScreen(prediction: prediction),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(CashFlowStatus status) {
    switch (status) {
      case CashFlowStatus.critical:
        return Colors.red;
      case CashFlowStatus.warning:
        return Colors.orange;
      case CashFlowStatus.healthy:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(CashFlowStatus status) {
    switch (status) {
      case CashFlowStatus.critical:
        return Icons.warning;
      case CashFlowStatus.warning:
        return Icons.info_outline;
      case CashFlowStatus.healthy:
        return Icons.check_circle_outline;
    }
  }

  IconData _getMessageIcon(CashFlowStatus status) {
    switch (status) {
      case CashFlowStatus.critical:
        return Icons.error_outline;
      case CashFlowStatus.warning:
        return Icons.warning_amber;
      case CashFlowStatus.healthy:
        return Icons.trending_up;
    }
  }

  String _getUpdateTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just updated';
    } else if (difference.inHours < 1) {
      return 'Updated ${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return 'Updated ${difference.inHours}h ago';
    } else {
      return 'Updated ${difference.inDays}d ago';
    }
  }
}
