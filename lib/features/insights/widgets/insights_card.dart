import 'package:flutter/material.dart';
import '../../../models/insight.dart';
import '../../../services/enhanced_insights_service.dart';
import '../../../services/auth_service.dart';
import '../screens/enhanced_insights_screen.dart';

/// Insights Card Widget for Dashboard
///
/// Week 6: Enhanced Insights
/// Shows the top 2-3 active insights with priority-based display
class InsightsCard extends StatefulWidget {
  const InsightsCard({super.key});

  @override
  State<InsightsCard> createState() => _InsightsCardState();
}

class _InsightsCardState extends State<InsightsCard> {
  final _insightsService = EnhancedInsightsService();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Insight>>(
      future: _insightsService.getActiveInsights(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final insights = snapshot.data!.take(3).toList();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnhancedInsightsScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Insights for You',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...insights.map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildInsightItem(theme, insight),
                  )),
                  if (insights.length < 3)
                    const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightItem(ThemeData theme, Insight insight) {
    final icon = _getInsightIcon(insight.type);
    final color = _getInsightColor(insight.type);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                insight.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
}
