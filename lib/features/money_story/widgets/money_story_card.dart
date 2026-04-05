import 'package:flutter/material.dart';
import '../../../core/navigation/page_transitions.dart';
import '../../../models/money_story.dart';
import '../../../services/money_story_service.dart';
import '../../../services/auth_service.dart';
import '../screens/money_stories_screen.dart';

/// Money Story Card for Dashboard
///
/// Week 7: Daily Money Story (Killer Feature #6)
/// Shows today's money story on the dashboard
class MoneyStoryCard extends StatefulWidget {
  const MoneyStoryCard({super.key});

  @override
  State<MoneyStoryCard> createState() => _MoneyStoryCardState();
}

class _MoneyStoryCardState extends State<MoneyStoryCard> {
  final _moneyStoryService = MoneyStoryService();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<MoneyStory?>(
      future: _moneyStoryService.getStoryForDate(user.uid, DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(theme);
        }

        final story = snapshot.data;
        if (story == null) {
          return _buildEmptyCard(theme, user.uid);
        }

        return _buildStoryCard(theme, story);
      },
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Today\'s Money Story',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(ThemeData theme, String userId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _generateStory(userId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_stories,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Today\'s Money Story',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No story yet today. Tap to generate!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard(ThemeData theme, MoneyStory story) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          context.pushWithFade(const MoneyStoriesScreen());
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
                    Icons.auto_stories,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Today\'s Money Story 📖',
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
              // Story Preview (first 2 lines)
              Text(
                _getStoryPreview(story.story),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // Quick Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickStat(
                    theme,
                    'Spent',
                    '\$${story.highlights.totalSpent.toStringAsFixed(2)}',
                    Colors.red,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _buildQuickStat(
                    theme,
                    'Transactions',
                    '${story.highlights.transactionCount}',
                    theme.colorScheme.primary,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _buildQuickStat(
                    theme,
                    'Top',
                    story.highlights.topCategory,
                    theme.colorScheme.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getStoryPreview(String story) {
    // Get first meaningful lines (skip title and date line)
    final lines = story.split('\n');
    final meaningfulLines = lines.where((line) =>
      line.trim().isNotEmpty &&
      !line.contains('Today\'s Money Story') &&
      !line.contains('day,') // Skip date line
    ).toList();

    return meaningfulLines.take(2).join('\n');
  }

  Future<void> _generateStory(String userId) async {
    try {
      final story = await _moneyStoryService.generateTodaysStory(userId);
      if (mounted) {
        if (story != null) {
          // Navigate to the stories screen to view the generated story
          context.pushWithFade(const MoneyStoriesScreen());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No transactions today to generate a story')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating story: $e')),
        );
      }
    }
  }
}
