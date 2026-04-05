import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/glass_card.dart';

class AIInsightCard extends StatefulWidget {
  final List<InsightData> insights;

  const AIInsightCard({
    super.key,
    required this.insights,
  });

  @override
  State<AIInsightCard> createState() => _AIInsightCardState();
}

class _AIInsightCardState extends State<AIInsightCard> {
  int _currentIndex = 0;
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (widget.insights.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
        if (mounted) {
          final nextIndex = (_currentIndex + 1) % widget.insights.length;
          _pageController.animateToPage(
            nextIndex,
            duration: DesignTokens.durationNormal,
            curve: DesignTokens.curveDecelerate,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.insights.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.space8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryIndigo.withOpacity(0.12),
                    borderRadius: DesignTokens.borderRadiusSM,
                  ),
                  child: Icon(
                    PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                    color: AppTheme.primaryIndigo,
                    size: DesignTokens.iconSM,
                  ),
                ),
                const SizedBox(width: DesignTokens.space12),
                Text(
                  'Smart Insight',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                // Page dots
                if (widget.insights.length > 1)
                  Row(
                    children: List.generate(widget.insights.length, (i) {
                      final isActive = i == _currentIndex;
                      return AnimatedContainer(
                        duration: DesignTokens.durationFast,
                        margin: const EdgeInsets.only(left: 4),
                        width: isActive ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryIndigo
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.2),
                          borderRadius: DesignTokens.borderRadiusFull,
                        ),
                      );
                    }),
                  ),
              ],
            ),

            const SizedBox(height: DesignTokens.space16),

            // Insight content
            if (widget.insights.length == 1)
              _buildInsightContent(widget.insights[0])
            else
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 80,
                  maxHeight: 120,
                ),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.insights.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return _buildInsightContent(widget.insights[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightContent(InsightData insight) {
    final iconData = _getIconForType(insight.type);
    final color = _getColorForType(insight.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Type badge
          Row(
            children: [
              Icon(iconData, size: 16, color: color),
              const SizedBox(width: DesignTokens.space4),
              Text(
                insight.type.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space8),

          // Insight message
          Flexible(
            child: Text(
              insight.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: DesignTokens.space8),

          // Action
          if (insight.actionLabel != null)
            GestureDetector(
              onTap: insight.onActionTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    insight.actionLabel!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryIndigo,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space4),
                  Icon(
                    PhosphorIcons.arrowRight(),
                    size: 14,
                    color: AppTheme.primaryIndigo,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(InsightType type) {
    switch (type) {
      case InsightType.achievement:
        return PhosphorIcons.trophy(PhosphorIconsStyle.fill);
      case InsightType.warning:
        return PhosphorIcons.warning(PhosphorIconsStyle.fill);
      case InsightType.tip:
        return PhosphorIcons.lightbulb(PhosphorIconsStyle.fill);
      case InsightType.pattern:
        return PhosphorIcons.trendUp(PhosphorIconsStyle.fill);
    }
  }

  Color _getColorForType(InsightType type) {
    switch (type) {
      case InsightType.achievement:
        return AppTheme.accentEmerald;
      case InsightType.warning:
        return AppTheme.amber500;
      case InsightType.tip:
        return AppTheme.primaryIndigo;
      case InsightType.pattern:
        return AppTheme.accentPurple;
    }
  }
}

// Data models
enum InsightType {
  achievement,
  warning,
  tip,
  pattern;

  String get label {
    switch (this) {
      case InsightType.achievement:
        return 'Achievement';
      case InsightType.warning:
        return 'Heads up';
      case InsightType.tip:
        return 'Smart tip';
      case InsightType.pattern:
        return 'Pattern';
    }
  }
}

class InsightData {
  final String message;
  final InsightType type;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const InsightData({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onActionTap,
  });
}