import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';

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
    
    // Auto-rotate insights every 8 seconds if more than one
    if (widget.insights.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
        if (mounted) {
          final nextIndex = (_currentIndex + 1) % widget.insights.length;
          _pageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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
    if (widget.insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryIndigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.primaryIndigo,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Smart Insight',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                if (widget.insights.length > 1)
                  Text(
                    '${_currentIndex + 1}/${widget.insights.length}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Insights display
            if (widget.insights.length == 1)
              _buildInsightContent(widget.insights[0])
            else
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 80,
                  maxHeight: 140,
                ),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.insights.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Insight text
          Flexible(
            child: Text(
              insight.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Action button (if available)
          if (insight.actionLabel != null)
            TextButton.icon(
              onPressed: insight.onActionTap,
              icon: Icon(
                _getIconForType(insight.type),
                size: 18,
              ),
              label: Text(
                insight.actionLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(InsightType type) {
    switch (type) {
      case InsightType.achievement:
        return Icons.celebration;
      case InsightType.warning:
        return Icons.warning_amber_rounded;
      case InsightType.tip:
        return Icons.arrow_forward;
      case InsightType.pattern:
        return Icons.trending_up;
    }
  }
}

// Data models
enum InsightType {
  achievement,
  warning,
  tip,
  pattern,
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