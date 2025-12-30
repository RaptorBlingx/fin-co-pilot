import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/smart_nudge.dart';
import '../../../services/smart_nudge_service.dart';
import '../../../services/auth_service.dart';
import '../screens/nudges_screen.dart';

/// Smart Nudge Banner for Dashboard
///
/// Week 4 Killer Feature #4: In-app banner showing active nudges
/// - Shows highest priority nudge
/// - Swipe to dismiss
/// - Tap to view all nudges
/// - Auto-refresh on new nudges
class SmartNudgeBanner extends ConsumerStatefulWidget {
  const SmartNudgeBanner({super.key});

  @override
  ConsumerState<SmartNudgeBanner> createState() => _SmartNudgeBannerState();
}

class _SmartNudgeBannerState extends ConsumerState<SmartNudgeBanner> {
  final _nudgeService = SmartNudgeService();
  final _authService = AuthService();

  List<SmartNudge> _activeNudges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveNudges();
  }

  Future<void> _loadActiveNudges() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final nudges = await _nudgeService.getActiveNudges(user.uid);

      if (mounted) {
        setState(() {
          _activeNudges = nudges;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading nudges: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _dismissNudge(SmartNudge nudge) async {
    try {
      await _nudgeService.dismissNudge(nudge.id);

      if (mounted) {
        setState(() {
          _activeNudges.removeWhere((n) => n.id == nudge.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nudge dismissed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error dismissing nudge: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_activeNudges.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show highest priority nudge
    final topNudge = _getTopPriorityNudge(_activeNudges);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Dismissible(
        key: Key(topNudge.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _dismissNudge(topNudge),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
        ),
        child: _buildNudgeCard(context, topNudge),
      ),
    );
  }

  Widget _buildNudgeCard(BuildContext context, SmartNudge nudge) {
    final theme = Theme.of(context);
    final color = _getNudgeColor(nudge.priority);
    final icon = _getNudgeIcon(nudge.type);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NudgesScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nudge.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        if (_activeNudges.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${_activeNudges.length - 1}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nudge.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (nudge.action != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // Handle action
                              _handleAction(context, nudge);
                            },
                            icon: Icon(Icons.arrow_forward, size: 16),
                            label: Text(nudge.action!.label),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _dismissNudge(nudge),
                            child: const Text('Dismiss'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SmartNudge _getTopPriorityNudge(List<SmartNudge> nudges) {
    // Sort by priority (high > medium > low)
    nudges.sort((a, b) {
      final priorityOrder = {
        NudgePriority.high: 0,
        NudgePriority.medium: 1,
        NudgePriority.low: 2,
      };
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
    });
    return nudges.first;
  }

  Color _getNudgeColor(NudgePriority priority) {
    switch (priority) {
      case NudgePriority.high:
        return Colors.red;
      case NudgePriority.medium:
        return Colors.orange;
      case NudgePriority.low:
        return Colors.blue;
    }
  }

  IconData _getNudgeIcon(NudgeType type) {
    switch (type) {
      case NudgeType.budgetWarning:
        return Icons.warning_amber;
      case NudgeType.impulseAlert:
        return Icons.shopping_bag_outlined;
      case NudgeType.billReminder:
        return Icons.event;
      case NudgeType.savingsOpportunity:
        return Icons.lightbulb_outline;
    }
  }

  void _handleAction(BuildContext context, SmartNudge nudge) {
    if (nudge.action == null) return;

    switch (nudge.action!.type) {
      case NudgeActionType.viewBudget:
        // Navigate to budget screen
        Navigator.of(context).pushNamed('/budget');
        break;
      case NudgeActionType.viewTransactions:
        // Navigate to transactions screen
        Navigator.of(context).pushNamed('/transactions');
        break;
      case NudgeActionType.dismiss:
        _dismissNudge(nudge);
        break;
    }
  }
}
