import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/coaching_tips_library_service.dart';
import '../../../models/coaching_tip.dart' as library_model;
import '../widgets/coaching_tip_library_card.dart';

/// Coaching Tips Library Screen (Week 9 Feature)
///
/// Browse 100+ pre-written coaching tips organized by:
/// - All Tips
/// - By Category (Budgeting, Impulse, Savings, Debt, Stress)
/// - Bookmarked
/// - Highly Rated
///
/// Features:
/// - Bookmark tips for later
/// - Rate tip effectiveness (0-5 stars)
/// - Search/filter tips
/// - Category-based browsing
class CoachingTipsLibraryScreen extends StatefulWidget {
  const CoachingTipsLibraryScreen({super.key});

  @override
  State<CoachingTipsLibraryScreen> createState() => _CoachingTipsLibraryScreenState();
}

class _CoachingTipsLibraryScreenState extends State<CoachingTipsLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CoachingTipsLibraryService _libraryService = CoachingTipsLibraryService();
  final AuthService _authService = AuthService();

  final List<String> _categories = [
    'All',
    'budgeting',
    'impulse',
    'savings',
    'debt',
    'stress',
  ];

  final Map<String, String> _categoryLabels = {
    'All': 'All Tips',
    'budgeting': 'Budgeting',
    'impulse': 'Impulse Control',
    'savings': 'Savings',
    'debt': 'Debt Management',
    'stress': 'Emotional Spending',
  };

  final Map<String, IconData> _categoryIcons = {
    'All': Icons.library_books,
    'budgeting': Icons.account_balance_wallet,
    'impulse': Icons.shopping_bag,
    'savings': Icons.savings,
    'debt': Icons.credit_card,
    'stress': Icons.self_improvement,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
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
      return const Scaffold(
        body: Center(child: Text('Please log in to access coaching tips')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coaching Tips Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => _showBookmarkedTips(context, user.uid),
            tooltip: 'My Bookmarks',
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () => _showHighlyRatedTips(context),
            tooltip: 'Highly Rated',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) {
            return Tab(
              icon: Icon(_categoryIcons[category]),
              text: _categoryLabels[category],
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          return _buildCategoryView(category, user.uid);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryView(String category, String userId) {
    final theme = Theme.of(context);

    // Get appropriate stream based on category
    final Stream<List<library_model.CoachingTip>> tipsStream = category == 'All'
        ? _libraryService.getAllTips()
        : _libraryService.getTipsByCategory(category);

    return StreamBuilder<List<library_model.CoachingTip>>(
      stream: tipsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Error loading tips: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final tips = snapshot.data ?? [];

        if (tips.isEmpty) {
          return _buildEmptyState(category);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
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

  Widget _buildEmptyState(String category) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              category == 'All'
                  ? 'No Tips Available'
                  : 'No ${_categoryLabels[category]} Tips',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tips will appear here once they\'re loaded into the library.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarkedTips(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _BookmarkedTipsScreen(userId: userId),
      ),
    );
  }

  void _showHighlyRatedTips(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _HighlyRatedTipsScreen(),
      ),
    );
  }

  Future<void> _handleBookmark(String tipId, String userId) async {
    try {
      final isBookmarked = await _libraryService.isTipBookmarked(userId, tipId);

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

  Future<void> _handleRating(String tipId, String userId, double rating) async {
    try {
      await _libraryService.rateTip(userId, tipId, rating);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rated ${rating.toStringAsFixed(1)} stars')),
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

// =================================================================
// BOOKMARKED TIPS SCREEN
// =================================================================

class _BookmarkedTipsScreen extends StatelessWidget {
  final String userId;

  const _BookmarkedTipsScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    final libraryService = CoachingTipsLibraryService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarks'),
      ),
      body: StreamBuilder<List<library_model.CoachingTip>>(
        stream: libraryService.getBookmarkedTips(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tips = snapshot.data ?? [];

          if (tips.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 80,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Bookmarks Yet',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bookmark tips you want to reference later',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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

// =================================================================
// HIGHLY RATED TIPS SCREEN
// =================================================================

class _HighlyRatedTipsScreen extends StatelessWidget {
  const _HighlyRatedTipsScreen();

  @override
  Widget build(BuildContext context) {
    final libraryService = CoachingTipsLibraryService();
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Highly Rated Tips'),
      ),
      body: StreamBuilder<List<library_model.CoachingTip>>(
        stream: libraryService.getHighlyRatedTips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tips = snapshot.data ?? [];

          if (tips.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No highly rated tips yet. Be the first to rate!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return CoachingTipLibraryCard(
                tip: tip,
                userId: user.uid,
                onBookmark: () async {
                  final isBookmarked = await libraryService.isTipBookmarked(user.uid, tip.id);
                  if (isBookmarked) {
                    await libraryService.unbookmarkTip(user.uid, tip.id);
                  } else {
                    await libraryService.bookmarkTip(user.uid, tip.id);
                  }
                },
                onRate: (rating) async {
                  await libraryService.rateTip(user.uid, tip.id, rating);
                },
              );
            },
          );
        },
      ),
    );
  }
}
