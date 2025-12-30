import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/money_story.dart';
import '../../../services/money_story_service.dart';
import '../../../services/auth_service.dart';
import 'package:share_plus/share_plus.dart';

/// Money Stories Screen
///
/// Week 7: Daily Money Story (Killer Feature #6)
/// Browse past money stories with calendar view
class MoneyStoriesScreen extends StatefulWidget {
  const MoneyStoriesScreen({super.key});

  @override
  State<MoneyStoriesScreen> createState() => _MoneyStoriesScreenState();
}

class _MoneyStoriesScreenState extends State<MoneyStoriesScreen> {
  final _moneyStoryService = MoneyStoryService();
  final _authService = AuthService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  MoneyStory? _selectedStory;
  bool _isLoadingStory = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadStoryForDate(_selectedDay!);
  }

  Future<void> _loadStoryForDate(DateTime date) async {
    setState(() => _isLoadingStory = true);

    final user = _authService.currentUser;
    if (user == null) return;

    final story = await _moneyStoryService.getStoryForDate(user.uid, date);

    if (mounted) {
      setState(() {
        _selectedStory = story;
        _isLoadingStory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Money Stories')),
        body: const Center(child: Text('Please log in to view stories')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Stories'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _generateTodaysStory(user.uid),
            tooltip: 'Generate Today\'s Story',
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          _buildCalendar(theme, user.uid),
          const Divider(height: 1),
          // Story Display
          Expanded(
            child: _isLoadingStory
                ? const Center(child: CircularProgressIndicator())
                : _selectedStory != null
                    ? _buildStoryView(theme, _selectedStory!)
                    : _buildEmptyState(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme, String userId) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<List<MoneyStory>>(
        stream: _moneyStoryService.getRecentStoriesStream(userId),
        builder: (context, snapshot) {
          final stories = snapshot.data ?? [];
          final storyDates = stories.map((s) => DateTime(
            s.date.year,
            s.date.month,
            s.date.day,
          )).toSet();

          return TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: theme.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadStoryForDate(selectedDay);
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) {
              // Show marker for days with stories
              final normalizedDay = DateTime(day.year, day.month, day.day);
              return storyDates.contains(normalizedDay) ? ['story'] : [];
            },
          );
        },
      ),
    );
  }

  Widget _buildStoryView(ThemeData theme, MoneyStory story) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Story Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Story Text
                  Text(
                    story.story,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Highlights Summary
                  _buildHighlightsSummary(theme, story.highlights),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () => _shareStory(story),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              OutlinedButton.icon(
                onPressed: () => _viewTransactions(story),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Transactions'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Timestamp
          Center(
            child: Text(
              'Generated ${_formatTimestamp(story.generatedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSummary(ThemeData theme, MoneyStoryHighlights highlights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  theme,
                  'Spent',
                  '\$${highlights.totalSpent.toStringAsFixed(2)}',
                  Icons.arrow_upward,
                  Colors.red,
                ),
              ),
              if (highlights.totalIncome > 0)
                Expanded(
                  child: _buildStat(
                    theme,
                    'Earned',
                    '\$${highlights.totalIncome.toStringAsFixed(2)}',
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  theme,
                  'Transactions',
                  '${highlights.transactionCount}',
                  Icons.receipt,
                  theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildStat(
                  theme,
                  'Top Category',
                  highlights.topCategory,
                  Icons.category,
                  theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Story for This Day',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Stories are generated daily at 9 PM when you have transactions',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            if (isSameDay(_selectedDay, DateTime.now()))
              FilledButton.icon(
                onPressed: () {
                  final user = _authService.currentUser;
                  if (user != null) {
                    _generateTodaysStory(user.uid);
                  }
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Today\'s Story'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'on ${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  void _shareStory(MoneyStory story) {
    Share.share(
      story.story,
      subject: 'My Money Story - ${story.date.month}/${story.date.day}/${story.date.year}',
    );
  }

  void _viewTransactions(MoneyStory story) {
    // Navigate to transactions screen filtered by date
    Navigator.pushNamed(
      context,
      '/transactions',
      arguments: {'date': story.date},
    );
  }

  Future<void> _generateTodaysStory(String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final story = await _moneyStoryService.generateTodaysStory(userId);
      if (mounted) {
        Navigator.pop(context);
        if (story != null) {
          setState(() {
            _selectedStory = story;
            _selectedDay = story.date;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story generated!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No transactions today to generate a story')),
          );
        }
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
