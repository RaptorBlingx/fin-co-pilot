import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/proactive_coach_agent.dart';
import '../../../../services/coaching_tips_library_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../shared/models/coaching_tip.dart';
import '../../../../models/coaching_tip.dart' as library_model;
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/page_transitions.dart';
import '../../../../shared/widgets/light_card.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../coaching_tips/widgets/coaching_tip_library_card.dart';

/// Unified Coach Screen — merges AI coaching + tips library into one tabbed view.
class UnifiedCoachScreen extends StatefulWidget {
  const UnifiedCoachScreen({super.key});

  @override
  State<UnifiedCoachScreen> createState() => _UnifiedCoachScreenState();
}

class _UnifiedCoachScreenState extends State<UnifiedCoachScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProactiveCoachAgent _coach = ProactiveCoachAgent();
  final CoachingTipsLibraryService _libraryService =
      CoachingTipsLibraryService();
  final AuthService _authService = AuthService();
  bool _isGenerating = false;

  String _selectedLibraryCategory = 'All';

  static const List<String> _libraryCategories = [
    'All',
    'budgeting',
    'savings',
    'spending',
    'debt',
    'stress',
    'shopping',
    'income',
    'investing',
    'habits',
  ];

  static const Map<String, String> _categoryLabels = {
    'All': 'All',
    'budgeting': 'Budgeting',
    'savings': 'Savings',
    'spending': 'Spending',
    'debt': 'Debt',
    'stress': 'Wellness',
    'shopping': 'Shopping',
    'income': 'Income',
    'investing': 'Investing',
    'habits': 'Habits',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _libraryService.seedIfEmpty();
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
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.bookmarkSimple()),
            onPressed: () => _showBookmarks(user.uid),
            tooltip: 'Bookmarks',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.duotone)),
              text: 'Your Tips',
            ),
            Tab(
              icon: Icon(PhosphorIcons.bookOpen(PhosphorIconsStyle.duotone)),
              text: 'Tip Library',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAITipsTab(user.uid, theme),
          _buildLibraryTab(user.uid, theme),
        ],
      ),
    );
  }

  // ===== TAB 1: AI-Generated Tips =====

  Widget _buildAITipsTab(String userId, ThemeData theme) {
    return Column(
      children: [
        // Generate button bar
        Padding(
          padding: EdgeInsets.fromLTRB(
            DesignTokens.space16, DesignTokens.space12,
            DesignTokens.space16, DesignTokens.space4,
          ),
          child: Row(
            children: [
              Icon(PhosphorIcons.brain(PhosphorIconsStyle.duotone),
                  color: AppTheme.primaryIndigo),
              SizedBox(width: DesignTokens.space8),
              Expanded(
                child: Text(
                  'Personalized tips based on your spending',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              PremiumButton(
                onPressed: _isGenerating ? null : () => _generateCoaching(userId),
                variant: PremiumButtonVariant.secondary,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isGenerating
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryIndigo,
                            ),
                          )
                        : Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                            size: 18, color: AppTheme.primaryIndigo),
                    SizedBox(width: DesignTokens.space6),
                    Text(_isGenerating ? 'Generating...' : 'New Tips'),
                  ],
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.3)),

        // Tips stream
        Expanded(
          child: StreamBuilder<List<CoachingTip>>(
            stream: _coach.getAllTips(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.all(DesignTokens.space16),
                  child: Column(
                    children: List.generate(3, (_) => Padding(
                      padding: EdgeInsets.only(bottom: DesignTokens.space12),
                      child: const CardSkeleton(),
                    )),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
                          size: 48, color: theme.colorScheme.error),
                      SizedBox(height: DesignTokens.space16),
                      Text('Error loading tips',
                          style: theme.textTheme.titleMedium),
                      SizedBox(height: DesignTokens.space8),
                      PremiumButton(
                        onPressed: () => setState(() {}),
                        variant: PremiumButtonVariant.secondary,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final tips = snapshot.data ?? [];

              if (tips.isEmpty) {
                return _buildAIEmptyState(userId, theme);
              }

              return ListView.builder(
                padding: EdgeInsets.all(DesignTokens.space16),
                itemCount: tips.length,
                itemBuilder: (context, index) => _buildAITipCard(tips[index], theme)
                    .animate()
                    .fadeIn(
                      duration: DesignTokens.durationNormal,
                      delay: Duration(milliseconds: index * 50),
                    )
                    .slideY(begin: 0.05, end: 0),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAIEmptyState(String userId, ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.brain(PhosphorIconsStyle.duotone),
                size: 80, color: theme.colorScheme.outlineVariant),
            SizedBox(height: DesignTokens.space24),
            Text('No coaching tips yet',
                style: theme.textTheme.titleLarge),
            SizedBox(height: DesignTokens.space8),
            Text(
              'Tap "New Tips" above to generate personalized\nfinancial coaching based on your spending habits',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: DesignTokens.durationSlow)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
      ),
    );
  }

  Widget _buildAITipCard(CoachingTip tip, ThemeData theme) {
    return LightCard(
      padding: EdgeInsets.all(DesignTokens.space16),
      onTap: () => _markAsRead(tip),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tip.typeIcon, style: const TextStyle(fontSize: 28)),
              SizedBox(width: DesignTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tip.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (tip.isNew)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: DesignTokens.space8,
                                vertical: DesignTokens.space2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryIndigo,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                            ),
                            child: Text(
                              'NEW',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.space2),
                    Text(
                      tip.timeAgo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(PhosphorIcons.x(), size: 18),
                onPressed: () => _dismissTip(tip),
                visualDensity: VisualDensity.compact,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space12),
          Text(
            tip.message,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (tip.hasAction) ...[
            SizedBox(height: DesignTokens.space12),
            PremiumButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tip.actionText!)),
                );
              },
              variant: PremiumButtonVariant.secondary,
              child: Text(tip.actionText!),
            ),
          ],
          SizedBox(height: DesignTokens.space8),
          _buildPriorityChip(tip.priority, theme),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String priority, ThemeData theme) {
    final Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        color = AppTheme.rose500;
      case 'medium':
        color = AppTheme.amber500;
      case 'low':
        color = AppTheme.accentEmerald;
      default:
        color = theme.colorScheme.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${priority.toUpperCase()} PRIORITY',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ===== TAB 2: Tips Library =====

  Widget _buildLibraryTab(String userId, ThemeData theme) {
    return Column(
      children: [
        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(
            DesignTokens.space16, DesignTokens.space12,
            DesignTokens.space16, DesignTokens.space4,
          ),
          child: Row(
            children: _libraryCategories.map((cat) {
              final isSelected = _selectedLibraryCategory == cat;
              return Padding(
                padding: EdgeInsets.only(right: DesignTokens.space8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(_categoryLabels[cat] ?? cat),
                  onSelected: (_) {
                    HapticUtils.light();
                    setState(() => _selectedLibraryCategory = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(),

        // Tips list
        Expanded(
          child: _buildLibraryList(userId, theme),
        ),
      ],
    );
  }

  Widget _buildLibraryList(String userId, ThemeData theme) {
    final Stream<List<library_model.CoachingTip>> stream =
        _selectedLibraryCategory == 'All'
            ? _libraryService.getAllTips()
            : _libraryService.getTipsByCategory(_selectedLibraryCategory);

    return StreamBuilder<List<library_model.CoachingTip>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.all(DesignTokens.space16),
            child: Column(
              children: List.generate(3, (_) => Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.space12),
                child: const CardSkeleton(),
              )),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
                    size: 48, color: theme.colorScheme.error),
                SizedBox(height: DesignTokens.space16),
                Text('Error loading tips',
                    style: theme.textTheme.titleMedium),
                SizedBox(height: DesignTokens.space8),
                PremiumButton(
                  onPressed: () => setState(() {}),
                  variant: PremiumButtonVariant.secondary,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final tips = snapshot.data ?? [];

        if (tips.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.space32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.bookOpen(PhosphorIconsStyle.duotone),
                      size: 80, color: theme.colorScheme.outlineVariant),
                  SizedBox(height: DesignTokens.space24),
                  Text('No tips available',
                      style: theme.textTheme.titleLarge),
                  SizedBox(height: DesignTokens.space8),
                  Text(
                    'Tips will appear here once loaded into the library.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(DesignTokens.space16),
          itemCount: tips.length,
          itemBuilder: (context, index) {
            final tip = tips[index];
            return CoachingTipLibraryCard(
              tip: tip,
              userId: userId,
              onBookmark: () => _handleBookmark(tip.id, userId),
              onRate: (rating) => _handleRating(tip.id, userId, rating),
            );
          },
        );
      },
    );
  }

  // ===== Bookmarks overlay =====

  void _showBookmarks(String userId) {
    context.pushWithFade(
      _BookmarksPage(userId: userId),
    );
  }

  // ===== Actions =====

  Future<void> _generateCoaching(String userId) async {
    setState(() => _isGenerating = true);
    HapticUtils.medium();

    try {
      await _coach.generateWeeklyCoaching(userId: userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New coaching tips generated!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _markAsRead(CoachingTip tip) async {
    if (tip.isNew) await _coach.markAsRead(tip.id);
  }

  Future<void> _dismissTip(CoachingTip tip) async {
    await _coach.dismissTip(tip.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tip dismissed')),
      );
    }
  }

  Future<void> _handleBookmark(String tipId, String userId) async {
    try {
      final isBookmarked =
          await _libraryService.isTipBookmarked(userId, tipId);
      if (isBookmarked) {
        await _libraryService.unbookmarkTip(userId, tipId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bookmark removed')),
          );
        }
      } else {
        await _libraryService.bookmarkTip(userId, tipId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tip bookmarked!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleRating(
      String tipId, String userId, double rating) async {
    try {
      await _libraryService.rateTip(userId, tipId, rating);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Rated ${rating.toStringAsFixed(1)} stars')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ===== Bookmarks Page =====

class _BookmarksPage extends StatelessWidget {
  final String userId;
  const _BookmarksPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    final libraryService = CoachingTipsLibraryService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarked Tips'), centerTitle: true),
      body: StreamBuilder<List<library_model.CoachingTip>>(
        stream: libraryService.getBookmarkedTips(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: EdgeInsets.all(DesignTokens.space16),
              child: Column(
                children: List.generate(3, (_) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.space12),
                  child: const CardSkeleton(),
                )),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final tips = snapshot.data ?? [];
          if (tips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.duotone),
                      size: 80, color: theme.colorScheme.outlineVariant),
                  SizedBox(height: DesignTokens.space16),
                  Text('No bookmarks yet',
                      style: theme.textTheme.titleLarge),
                  SizedBox(height: DesignTokens.space8),
                  Text(
                    'Bookmark tips you want to reference later',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(DesignTokens.space16),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return CoachingTipLibraryCard(
                tip: tip,
                userId: userId,
                onBookmark: () async {
                  await libraryService.unbookmarkTip(userId, tip.id);
                },
                onRate: (rating) async {
                  await libraryService.rateTip(userId, tip.id, rating);
                },
              );
            },
          );
        },
      ),
    );
  }
}
