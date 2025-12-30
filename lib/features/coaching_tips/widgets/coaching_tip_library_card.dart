import 'package:flutter/material.dart';
import '../../../models/coaching_tip.dart' as library_model;
import '../../../services/coaching_tips_library_service.dart';

/// Card widget for displaying a coaching tip from the library
///
/// Features:
/// - Shows tip content with category badge
/// - Bookmark button
/// - Star rating (0-5)
/// - Usage count and effectiveness display
/// - Expandable for long-form content
class CoachingTipLibraryCard extends StatefulWidget {
  final library_model.CoachingTip tip;
  final String userId;
  final VoidCallback onBookmark;
  final Function(double) onRate;

  const CoachingTipLibraryCard({
    super.key,
    required this.tip,
    required this.userId,
    required this.onBookmark,
    required this.onRate,
  });

  @override
  State<CoachingTipLibraryCard> createState() => _CoachingTipLibraryCardState();
}

class _CoachingTipLibraryCardState extends State<CoachingTipLibraryCard> {
  final CoachingTipsLibraryService _libraryService = CoachingTipsLibraryService();
  bool _isExpanded = false;
  bool _isBookmarked = false;
  double? _userRating;

  @override
  void initState() {
    super.initState();
    _loadBookmarkStatus();
    _loadUserRating();
  }

  Future<void> _loadBookmarkStatus() async {
    final isBookmarked = await _libraryService.isTipBookmarked(widget.userId, widget.tip.id);
    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
      });
    }
  }

  Future<void> _loadUserRating() async {
    final rating = await _libraryService.getUserRating(widget.userId, widget.tip.id);
    if (mounted) {
      setState(() {
        _userRating = rating;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category badge + Bookmark button
              Row(
                children: [
                  _buildCategoryBadge(theme),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: _isBookmarked ? theme.colorScheme.primary : null,
                    ),
                    onPressed: () {
                      widget.onBookmark();
                      setState(() {
                        _isBookmarked = !_isBookmarked;
                      });
                    },
                    tooltip: _isBookmarked ? 'Remove bookmark' : 'Bookmark',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Tip content
              Text(
                widget.tip.tip,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Long-form content (expandable)
              if (widget.tip.longForm != null) ...[
                const SizedBox(height: 12),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Text(
                    widget.tip.longForm!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _isExpanded ? 'Show less' : 'Read more',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Tags
              if (widget.tip.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.tip.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Divider
              Divider(color: theme.colorScheme.outlineVariant),

              const SizedBox(height: 12),

              // Rating section
              Row(
                children: [
                  // Star rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate this tip:',
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        _buildStarRating(theme),
                      ],
                    ),
                  ),

                  // Statistics
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.tip.effectiveness != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.tip.effectiveness!.toStringAsFixed(1),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.tip.usageCount} views',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(ThemeData theme) {
    final categoryColors = {
      'budgeting': Colors.blue,
      'impulse': Colors.orange,
      'savings': Colors.green,
      'debt': Colors.red,
      'stress': Colors.purple,
    };

    final color = categoryColors[widget.tip.category] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(widget.tip.category),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            widget.tip.category.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'budgeting':
        return Icons.account_balance_wallet;
      case 'impulse':
        return Icons.shopping_bag;
      case 'savings':
        return Icons.savings;
      case 'debt':
        return Icons.credit_card;
      case 'stress':
        return Icons.self_improvement;
      default:
        return Icons.lightbulb;
    }
  }

  Widget _buildStarRating(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final isSelected = _userRating != null && _userRating! >= starValue;

        return GestureDetector(
          onTap: () {
            setState(() {
              _userRating = starValue;
            });
            widget.onRate(starValue);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              size: 24,
              color: isSelected ? Colors.amber : theme.colorScheme.outline,
            ),
          ),
        );
      }),
    );
  }
}
