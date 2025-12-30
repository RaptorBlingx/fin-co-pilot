import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/smart_nudge.dart';
import '../../../services/smart_nudge_service.dart';
import '../../../services/auth_service.dart';

/// Smart Nudges History Screen
///
/// Week 4 Killer Feature #4: View all nudges (active, dismissed, expired)
/// - Tabbed interface (Active / History)
/// - Swipe to dismiss
/// - Action buttons
/// - Real-time updates
class NudgesScreen extends ConsumerStatefulWidget {
  const NudgesScreen({super.key});

  @override
  ConsumerState<NudgesScreen> createState() => _NudgesScreenState();
}

class _NudgesScreenState extends ConsumerState<NudgesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nudgeService = SmartNudgeService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Smart Nudges')),
        body: const Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Nudges'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveNudges(user.uid),
          _buildNudgeHistory(user.uid),
        ],
      ),
    );
  }

  Widget _buildActiveNudges(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('smart_nudges')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('generatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Active Nudges',
            message: 'You\'re all caught up! We\'ll notify you of any important alerts.',
          );
        }

        final nudges = snapshot.data!.docs
            .map((doc) => SmartNudge.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: nudges.length,
          itemBuilder: (context, index) {
            final nudge = nudges[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNudgeCard(context, nudge, dismissible: true),
            );
          },
        );
      },
    );
  }

  Widget _buildNudgeHistory(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('smart_nudges')
          .where('user_id', isEqualTo: userId)
          .where('status', whereIn: ['dismissed', 'expired'])
          .orderBy('generatedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'No History Yet',
            message: 'Past nudges will appear here.',
          );
        }

        final nudges = snapshot.data!.docs
            .map((doc) => SmartNudge.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: nudges.length,
          itemBuilder: (context, index) {
            final nudge = nudges[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNudgeCard(context, nudge, dismissible: false),
            );
          },
        );
      },
    );
  }

  Widget _buildNudgeCard(
    BuildContext context,
    SmartNudge nudge, {
    required bool dismissible,
  }) {
    final theme = Theme.of(context);
    final color = _getNudgeColor(nudge.priority);
    final icon = _getNudgeIcon(nudge.type);

    final card = Card(
      elevation: dismissible ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: dismissible
              ? color.withOpacity(0.3)
              : theme.colorScheme.outlineVariant,
          width: dismissible ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: dismissible
                        ? color.withOpacity(0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: dismissible ? color : theme.colorScheme.onSurface.withOpacity(0.5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nudge.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dismissible ? color : null,
                        ),
                      ),
                      Text(
                        _formatTimestamp(nudge.generatedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPriorityBadge(theme, nudge.priority),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              nudge.message,
              style: theme.textTheme.bodyMedium,
            ),
            if (dismissible && nudge.action != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _handleAction(context, nudge),
                    icon: const Icon(Icons.arrow_forward, size: 16),
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
            if (!dismissible) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      nudge.status == NudgeStatus.dismissed
                          ? Icons.check
                          : Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      nudge.status == NudgeStatus.dismissed
                          ? 'Dismissed ${_formatTimestamp(nudge.dismissedAt!)}'
                          : 'Expired ${_formatTimestamp(nudge.expiresAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (dismissible) {
      return Dismissible(
        key: Key(nudge.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _dismissNudge(nudge),
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
        child: card,
      );
    }

    return card;
  }

  Widget _buildPriorityBadge(ThemeData theme, NudgePriority priority) {
    final color = _getNudgeColor(priority);
    final label = priority.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
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

  Future<void> _dismissNudge(SmartNudge nudge) async {
    try {
      await _nudgeService.dismissNudge(nudge.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nudge dismissed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error dismissing nudge: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to dismiss nudge'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleAction(BuildContext context, SmartNudge nudge) {
    if (nudge.action == null) return;

    switch (nudge.action!.type) {
      case NudgeActionType.viewBudget:
        Navigator.of(context).pushNamed('/budget');
        break;
      case NudgeActionType.viewTransactions:
        Navigator.of(context).pushNamed('/transactions');
        break;
      case NudgeActionType.dismiss:
        _dismissNudge(nudge);
        break;
    }
  }
}
