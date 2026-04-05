import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../models/transaction.dart' as model;
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/constants/categories.dart';
import 'transaction_detail_screen.dart';
import '../../../../core/navigation/page_transitions.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/light_card.dart';
import '../../../../shared/widgets/glass_search_bar.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

import '../../../../shared/widgets/animated_counter.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _selectedCategory;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space20,
                DesignTokens.space12,
                DesignTokens.space20,
                DesignTokens.space8,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => ref.read(selectedIndexProvider.notifier).state = 0,
                      child: Icon(
                        PhosphorIcons.arrowLeft(),
                        size: DesignTokens.iconMD,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space12),
                    Text(
                      'Transactions',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const Spacer(),
                    _FilterButton(
                      selectedCategory: _selectedCategory,
                      onSelected: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Search bar
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space20,
              ),
              sliver: SliverToBoxAdapter(
                child: GlassSearchBar(
                  controller: _searchController,
                  hintText: 'Search transactions...',
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: DesignTokens.space16),
            ),

            // Content
            ...allTransactions.when(
              loading: () => [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space20,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: const _SpendingSummarySkeleton(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: DesignTokens.space8),
                        child: const TransactionTileSkeleton(),
                      ),
                      childCount: 6,
                    ),
                  ),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  child: _ErrorState(
                    onRetry: () => ref.invalidate(transactionsProvider),
                  ),
                ),
              ],
              data: (txnList) {
                var transactions = txnList;

                // Apply category filter
                if (_selectedCategory != null) {
                  transactions = transactions
                      .where((t) =>
                          t.category.toLowerCase() ==
                          _selectedCategory!.toLowerCase())
                      .toList();
                }

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  transactions = transactions.where((t) {
                    final merchant = t.merchant?.toLowerCase() ?? '';
                    final category = t.category.toLowerCase();
                    final notes = t.notes?.toLowerCase() ?? '';
                    return merchant.contains(_searchQuery) ||
                        category.contains(_searchQuery) ||
                        notes.contains(_searchQuery);
                  }).toList();
                }

                if (transactions.isEmpty) {
                  return [
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    ),
                  ];
                }

                final total = transactions.fold<double>(
                    0.0, (sum, t) => sum + t.amount);

                return [
                  // Spending summary card
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space20,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _SpendingSummaryCard(
                        total: total,
                        count: transactions.length,
                        label: _selectedCategory != null
                            ? '$_selectedCategory Spending'
                            : _searchQuery.isNotEmpty
                                ? 'Search Results'
                                : 'Total Spending',
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.space16),
                  ),

                  // Transaction list
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space20,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final transaction = transactions[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: DesignTokens.space8),
                            child: _TransactionTile(
                              transaction: transaction,
                            ),
                          );
                        },
                        childCount: transactions.length,
                      ),
                    ),
                  ),

                  // Bottom padding for nav bar
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          DesignTokens.bottomNavHeight + DesignTokens.space32,
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return NoSearchResultsEmpty(query: _searchQuery);
    }

    if (_selectedCategory != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.funnel(),
              size: 56,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: DesignTokens.space16),
            Text(
              'No $_selectedCategory transactions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              'Try a different category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
            ),
            const SizedBox(height: DesignTokens.space20),
            TextButton(
              onPressed: () => setState(() => _selectedCategory = null),
              child: const Text('Show All'),
            ),
          ],
        ),
      );
    }

    return const NoTransactionsEmpty();
  }
}

// ── Filter Button ─────────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  const _FilterButton({
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selectedCategory != null;

    return PopupMenuButton<String>(
      icon: Icon(
        isActive
            ? PhosphorIcons.funnel(PhosphorIconsStyle.fill)
            : PhosphorIcons.funnel(),
        size: DesignTokens.iconMD,
        color: isActive ? AppTheme.primaryIndigo : null,
      ),
      tooltip: 'Filter by category',
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusLG,
      ),
      onSelected: (String? value) {
        HapticUtils.light();
        onSelected(value == 'All' ? null : value);
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            value: 'All',
            child: Row(
              children: [
                Icon(PhosphorIcons.listDashes(), size: DesignTokens.iconSM),
                const SizedBox(width: DesignTokens.space12),
                const Text('All Categories'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          ...AppCategories.categories.map((category) {
            return PopupMenuItem<String>(
              value: category.name,
              child: Row(
                children: [
                  Icon(category.icon,
                      color: category.color, size: DesignTokens.iconSM),
                  const SizedBox(width: DesignTokens.space12),
                  Text(category.name),
                ],
              ),
            );
          }),
        ];
      },
    );
  }
}

// ── Spending Summary Card ─────────────────────────────────────────────

class _SpendingSummaryCard extends StatelessWidget {
  final double total;
  final int count;
  final String label;

  const _SpendingSummaryCard({
    required this.total,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: DesignTokens.cardPaddingLarge,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppTheme.primaryGradientDark
            : AppTheme.primaryGradient,
        borderRadius: DesignTokens.borderRadiusXL,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryIndigo.withOpacity(isDark ? 0.15 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: DesignTokens.borderRadiusMD,
            ),
            child: Icon(
              PhosphorIcons.wallet(PhosphorIconsStyle.fill),
              color: Colors.white,
              size: DesignTokens.iconMD,
            ),
          ),
          const SizedBox(width: DesignTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedCounter(
                  value: total,
                  prefix: '\$',
                  decimalPlaces: 2,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space12,
              vertical: DesignTokens.space4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: DesignTokens.borderRadiusFull,
            ),
            child: Text(
              '$count ${count == 1 ? 'item' : 'items'}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final model.Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final categoryData =
        AppCategories.getCategoryByName(transaction.category);
    final isIncome = transaction.type == model.TransactionType.income;
    final financeColors = context.financeColors;

    return LightCard(
      onTap: () {
        HapticUtils.light();
        context.pushWithSlideUp(
          TransactionDetailScreen(transaction: transaction),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space12,
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: DesignTokens.avatarMD,
              height: DesignTokens.avatarMD,
              decoration: BoxDecoration(
                color: categoryData.color.withOpacity(0.12),
                borderRadius: DesignTokens.borderRadiusMD,
              ),
              child: Center(
                child: Icon(
                  categoryData.icon,
                  color: categoryData.color,
                  size: DesignTokens.iconSM,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.space12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchant ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        transaction.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                      ),
                      if (transaction.notes != null &&
                          transaction.notes!.isNotEmpty) ...[
                        Text(
                          ' · ',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            transaction.notes!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: DesignTokens.space8),

            // Amount and date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyUtils.formatAmount(transaction.amount.abs(), transaction.currency)}',
                  style: AppTheme.monoAmountStyle(context).copyWith(
                        color: isIncome
                            ? financeColors.positive
                            : financeColors.negative,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.transactionDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) return 'Today';
    if (transactionDate == yesterday) return 'Yesterday';
    if (now.difference(date).inDays < 7) return _getDayName(date.weekday);
    return '${date.month}/${date.day}';
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }
}

// ── Skeletons ─────────────────────────────────────────────────────────

class _SpendingSummarySkeleton extends StatelessWidget {
  const _SpendingSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return const CardSkeleton();
  }
}

// ── Error State ───────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.warning(),
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            'Unable to load transactions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: DesignTokens.space12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
