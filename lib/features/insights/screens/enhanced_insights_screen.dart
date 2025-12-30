import 'package:flutter/material.dart';
import '../../../models/insight.dart';
import '../../../services/enhanced_insights_service.dart';
import '../../../services/auth_service.dart';

/// Enhanced Insights Screen
///
/// Week 6: Enhanced Insights
/// Full screen view of all insights with filtering and actions
class EnhancedInsightsScreen extends StatefulWidget {
  const EnhancedInsightsScreen({super.key});

  @override
  State<EnhancedInsightsScreen> createState() => _EnhancedInsightsScreenState();
}

class _EnhancedInsightsScreenState extends State<EnhancedInsightsScreen>
    with SingleTickerProviderStateMixin {
  final _insightsService = EnhancedInsightsService();
  final _authService = AuthService();
  late TabController _tabController;

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
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Insights')),
        body: const Center(child: Text('Please log in to view insights')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Insights'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: StreamBuilder<List<Insight>>(
        stream: _insightsService.getInsightsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(theme);
          }

          final allInsights = snapshot.data!;
          final activeInsights = allInsights
              .where((i) => i.status == InsightStatus.active && !i.isExpired)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Active Tab
              activeInsights.isEmpty
                  ? _buildEmptyState(theme, isActive: true)
                  : _buildInsightsList(theme, activeInsights, isActive: true),
              // All Tab
              _buildInsightsList(theme, allInsights, isActive: false),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateNewInsights(user.uid),
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh Insights'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, {bool isActive = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              isActive ? 'No Active Insights' : 'No Insights Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isActive
                  ? 'Check back soon for new insights based on your spending patterns'
                  : 'Start tracking transactions to get personalized insights',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsList(
    ThemeData theme,
    List<Insight> insights,
    {required bool isActive}
  ) {
    // Group by priority
    final highPriority = insights.where((i) => i.priority == InsightPriority.high).toList();
    final mediumPriority = insights.where((i) => i.priority == InsightPriority.medium).toList();
    final lowPriority = insights.where((i) => i.priority == InsightPriority.low).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (highPriority.isNotEmpty) ...[
          _buildPrioritySection(theme, 'High Priority', highPriority, isActive),
          const SizedBox(height: 16),
        ],
        if (mediumPriority.isNotEmpty) ...[
          _buildPrioritySection(theme, 'Medium Priority', mediumPriority, isActive),
          const SizedBox(height: 16),
        ],
        if (lowPriority.isNotEmpty) ...[
          _buildPrioritySection(theme, 'Low Priority', lowPriority, isActive),
        ],
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildPrioritySection(
    ThemeData theme,
    String title,
    List<Insight> insights,
    bool isActive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        ...insights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildInsightCard(theme, insight, isActive),
        )),
      ],
    );
  }

  Widget _buildInsightCard(ThemeData theme, Insight insight, bool isActive) {
    final icon = _getInsightIcon(insight.type);
    final color = _getInsightColor(insight.type);

    return Dismissible(
      key: Key(insight.id),
      direction: isActive ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: isActive
          ? (_) => _dismissInsight(insight.id)
          : null,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: insight.status != InsightStatus.active
              ? BorderSide(color: theme.colorScheme.outlineVariant)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                insight.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (insight.status != InsightStatus.active)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  insight.status.name,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          insight.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (insight.action != null && isActive) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _handleAction(insight),
                      child: Text(insight.action!.label),
                    ),
                    if (isActive)
                      TextButton(
                        onPressed: () => _dismissInsight(insight.id),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        child: const Text('Dismiss'),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(insight.generatedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (insight.category != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.label_outline,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      insight.category!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.achievement:
        return Icons.celebration;
      case InsightType.alert:
        return Icons.warning_amber_rounded;
      case InsightType.recommendation:
        return Icons.tips_and_updates;
      case InsightType.trend:
        return Icons.trending_up;
      case InsightType.anomaly:
        return Icons.error_outline;
    }
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.achievement:
        return Colors.green;
      case InsightType.alert:
        return Colors.orange;
      case InsightType.recommendation:
        return Colors.blue;
      case InsightType.trend:
        return Colors.purple;
      case InsightType.anomaly:
        return Colors.red;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  void _handleAction(Insight insight) {
    if (insight.action == null) return;

    final action = insight.action!;
    if (action.type == InsightActionType.navigate && action.target != null) {
      // Navigate to target screen
      Navigator.pushNamed(context, action.target!);
    }
  }

  Future<void> _dismissInsight(String insightId) async {
    await _insightsService.dismissInsight(insightId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insight dismissed')),
      );
    }
  }

  Future<void> _generateNewInsights(String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _insightsService.generateWeeklyInsights(userId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insights refreshed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
