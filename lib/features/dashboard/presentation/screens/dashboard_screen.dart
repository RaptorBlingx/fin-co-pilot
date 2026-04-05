import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../services/preferences_service.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/insights_service.dart';
import '../../../../models/transaction.dart' as model;

import '../../../transactions/presentation/screens/transactions_screen.dart';
import '../../../transactions/presentation/screens/transaction_detail_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../budget/presentation/screens/budget_screen.dart';

import '../../widgets/hero_spending_card.dart';
import '../../widgets/ai_insight_card.dart';
import '../../widgets/compact_transaction_card.dart';
import '../../widgets/smart_suggestions_section.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/navigation/page_transitions.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/staggered_animation.dart';
import '../../../cash_flow/widgets/cash_flow_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('dashboard');
  }

  List<InsightData> _generateSmartInsights(
      List<model.Transaction> allTransactions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);

    final thisMonthTransactions = allTransactions
        .where((t) => t.transactionDate
            .isAfter(startOfMonth.subtract(const Duration(days: 1))))
        .toList();

    final lastMonthTransactions = allTransactions
        .where((t) =>
            t.transactionDate
                .isAfter(startOfLastMonth.subtract(const Duration(days: 1))) &&
            t.transactionDate.isBefore(startOfMonth))
        .toList();

    final thisMonthInsights =
        InsightsService.generateInsights(thisMonthTransactions);
    final lastMonthInsights =
        InsightsService.generateInsights(lastMonthTransactions);

    final List<InsightData> insights = [];

    // Spending trend comparison
    if (lastMonthInsights.totalSpent > 0) {
      final change = thisMonthInsights.totalSpent - lastMonthInsights.totalSpent;
      final percentChange =
          (change / lastMonthInsights.totalSpent * 100).abs();

      if (change < 0) {
        insights.add(InsightData(
          message:
              "You're spending ${percentChange.toStringAsFixed(0)}% less this month. Keep it up!",
          type: InsightType.achievement,
          actionLabel: 'View details',
          onActionTap: () {
            HapticUtils.light();
            context.pushWithFade(const TransactionsScreen());
          },
        ));
      } else if (change > lastMonthInsights.totalSpent * 0.2) {
        insights.add(InsightData(
          message:
              'Spending is up ${percentChange.toStringAsFixed(0)}% this month. Consider reviewing your budget.',
          type: InsightType.warning,
          actionLabel: 'Review spending',
          onActionTap: () {
            HapticUtils.light();
            context.pushWithFade(const TransactionsScreen());
          },
        ));
      }
    }

    // Top category spending
    if (thisMonthInsights.topCategory.isNotEmpty) {
      final categorySpending =
          thisMonthInsights.byCategory[thisMonthInsights.topCategory] ?? 0;
      final percentage =
          (categorySpending / thisMonthInsights.totalSpent * 100);

      if (percentage > 40) {
        insights.add(InsightData(
          message:
              '${thisMonthInsights.topCategory} is ${percentage.toStringAsFixed(0)}% of your spending. Consider setting a budget.',
          type: InsightType.tip,
          actionLabel: 'Set budget',
          onActionTap: () {
            HapticUtils.light();
            context.pushWithFade(const BudgetScreen());
          },
        ));
      }
    }

    // Category comparison with last month
    if (lastMonthInsights.byCategory.isNotEmpty &&
        thisMonthInsights.byCategory.isNotEmpty) {
      for (final category in thisMonthInsights.byCategory.keys) {
        final thisMonthAmount =
            thisMonthInsights.byCategory[category] ?? 0;
        final lastMonthAmount =
            lastMonthInsights.byCategory[category] ?? 0;

        if (lastMonthAmount > 0) {
          final savings = lastMonthAmount - thisMonthAmount;
          if (savings > 50) {
            insights.add(InsightData(
              message:
                  "You've saved \$${savings.toStringAsFixed(0)} in $category this month!",
              type: InsightType.pattern,
              actionLabel: 'See savings',
              onActionTap: () {
                HapticUtils.light();
                context.pushWithFade(const TransactionsScreen());
              },
            ));
            break;
          }
        }
      }
    }

    // Transaction count pattern
    if (thisMonthInsights.transactionCount >
        lastMonthInsights.transactionCount + 10) {
      insights.add(InsightData(
        message:
            'You made ${thisMonthInsights.transactionCount - lastMonthInsights.transactionCount} more transactions this month. Consider consolidating purchases.',
        type: InsightType.tip,
        actionLabel: 'Learn more',
        onActionTap: () {
          HapticUtils.light();
          context.pushWithFade(const TransactionsScreen());
        },
      ));
    }

    // Default insight
    if (insights.isEmpty && thisMonthInsights.transactionCount > 0) {
      insights.add(InsightData(
        message:
            "You've made ${thisMonthInsights.transactionCount} transactions this month totaling \$${thisMonthInsights.totalSpent.toStringAsFixed(2)}",
        type: InsightType.pattern,
        actionLabel: 'View all',
        onActionTap: () {
          HapticUtils.light();
          context.pushWithFade(const TransactionsScreen());
        },
      ));
    }

    return insights.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currency = PreferencesService.getCurrency() ?? 'USD';
    final monthlyTransactions = ref.watch(currentMonthTransactionsProvider);
    final allTransactions = ref.watch(transactionsProvider);
    final monthlyBudget = ref.watch(monthlyBudgetProvider).valueOrNull ?? 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // App bar header
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
                    Text(
                      'Fin Co-Pilot',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.gearSix(),
                        size: DesignTokens.iconMD,
                      ),
                      onPressed: () {
                        HapticUtils.light();
                        context.pushWithFade(const SettingsScreen());
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Hero Spending Card
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space20,
              ),
              sliver: SliverToBoxAdapter(
                child: monthlyTransactions.when(
                  loading: () => const HeroCardSkeleton(),
                  error: (e, _) => _ErrorCard(
                    message: 'Unable to load spending data.',
                    onRetry: () =>
                        ref.invalidate(currentMonthTransactionsProvider),
                  ),
                  data: (transactions) {
                    final totalSpent = transactions.fold<double>(
                        0, (sum, t) => sum + t.amount);
                    final now = DateTime.now();
                    final weeklySpending = List.generate(7, (index) {
                      final day = now.subtract(Duration(days: 6 - index));
                      final dayStart =
                          DateTime(day.year, day.month, day.day);
                      final dayEnd =
                          dayStart.add(const Duration(days: 1));
                      return transactions
                          .where((t) =>
                              t.transactionDate.isAfter(
                                  dayStart.subtract(
                                      const Duration(seconds: 1))) &&
                              t.transactionDate.isBefore(dayEnd))
                          .fold<double>(0, (sum, t) => sum + t.amount);
                    });

                    final budget = monthlyBudget > 0
                        ? monthlyBudget
                        : (totalSpent > 0 ? totalSpent : 1.0);

                    return HeroSpendingCard(
                      monthlySpent: totalSpent,
                      monthlyBudget: budget,
                      currency: currency,
                      weeklySpending: weeklySpending,
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: DesignTokens.space16),
            ),

            // AI Insight Card
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space20,
              ),
              sliver: SliverToBoxAdapter(
                child: allTransactions.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (txns) {
                    if (txns.isEmpty) return const SizedBox.shrink();
                    final insights = _generateSmartInsights(txns);
                    return AIInsightCard(insights: insights);
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: DesignTokens.space16),
            ),

            // Cash Flow Card
            const SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.space20,
              ),
              sliver: SliverToBoxAdapter(child: CashFlowCard()),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: DesignTokens.space24),
            ),

            // Recent Transactions Section header
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space20,
              ),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Recent Transactions',
                  onViewAll: () {
                    HapticUtils.light();
                    context.pushWithFade(const TransactionsScreen());
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: DesignTokens.space12),
            ),

            // Recent Transactions List
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space20,
              ),
              sliver: allTransactions.when(
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: DesignTokens.space8),
                      child: const TransactionTileSkeleton(),
                    ),
                    childCount: 3,
                  ),
                ),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (txns) {
                  final transactions = txns.take(3).toList();
                  if (transactions.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: NoTransactionsEmpty(),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final transaction = transactions[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: DesignTokens.space8),
                          child: CompactTransactionCard(
                            transaction: transaction,
                            onTap: () {
                              HapticUtils.light();
                              context.pushWithSlideUp(
                                TransactionDetailScreen(
                                  transaction: transaction,
                                ),
                              );
                            },
                          ).staggered(index),
                        );
                      },
                      childCount: transactions.length,
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: DesignTokens.space24),
            ),

            // Suggested for You header
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space20,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Suggested for You',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: DesignTokens.space12),
            ),

            // Smart Suggestions
            const SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.space20,
              ),
              sliver: SliverToBoxAdapter(child: SmartSuggestionsSection()),
            ),

            // Bottom padding for nav bar
            SliverToBoxAdapter(
              child: SizedBox(
                height: DesignTokens.bottomNavHeight + DesignTokens.space32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
              ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryIndigo,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  PhosphorIcons.caretRight(),
                  size: 14,
                  color: AppTheme.primaryIndigo,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: DesignTokens.cardPaddingLarge,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: DesignTokens.borderRadiusXL,
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.warning(),
            size: DesignTokens.iconLG,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
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