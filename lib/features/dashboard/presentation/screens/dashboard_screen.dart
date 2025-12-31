import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/preferences_service.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/transaction_service.dart';
import '../../../../services/insights_service.dart';
import '../../../../shared/models/transaction.dart' as model;

import '../../../transactions/presentation/screens/transactions_screen.dart';
import '../../../transactions/presentation/screens/transaction_detail_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../budget/presentation/screens/budget_screen.dart';

import '../../widgets/hero_spending_card.dart';
import '../../widgets/ai_insight_card.dart';
import '../../widgets/compact_transaction_card.dart';
import '../../widgets/quick_action_button.dart';
// REMOVED for V1.0 simplification:
// import '../../widgets/financial_health_score_card.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/navigation/page_transitions.dart';
import '../../../cash_flow/widgets/cash_flow_card.dart';
// REMOVED: Smart nudge, SMS, insights cards (Tier 2/3)
// REMOVED: Money story, subscriptions, coaching cards (V2.0 features)

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Track dashboard screen view
    AnalyticsService.logScreenView('dashboard');
  }

  /// Generate smart insights based on user's real transaction data
  List<InsightData> _generateSmartInsights(List<model.Transaction> allTransactions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);

    // Get this month's and last month's transactions
    final thisMonthTransactions = allTransactions.where((t) =>
      t.transactionDate.isAfter(startOfMonth.subtract(const Duration(days: 1)))
    ).toList();

    final lastMonthTransactions = allTransactions.where((t) =>
      t.transactionDate.isAfter(startOfLastMonth.subtract(const Duration(days: 1))) &&
      t.transactionDate.isBefore(startOfMonth)
    ).toList();

    final thisMonthInsights = InsightsService.generateInsights(thisMonthTransactions);
    final lastMonthInsights = InsightsService.generateInsights(lastMonthTransactions);

    final List<InsightData> insights = [];

    // Insight 1: Spending trend comparison
    if (lastMonthInsights.totalSpent > 0) {
      final change = thisMonthInsights.totalSpent - lastMonthInsights.totalSpent;
      final percentChange = (change / lastMonthInsights.totalSpent * 100).abs();

      if (change < 0) {
        insights.add(InsightData(
          message: "You're spending ${percentChange.toStringAsFixed(0)}% less this month. Keep it up! 🎉",
          type: InsightType.achievement,
          actionLabel: "View details",
          onActionTap: () {
            HapticUtils.light();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionsScreen()),
            );
          },
        ));
      } else if (change > lastMonthInsights.totalSpent * 0.2) {
        insights.add(InsightData(
          message: "Spending is up ${percentChange.toStringAsFixed(0)}% this month. Consider reviewing your budget.",
          type: InsightType.warning,
          actionLabel: "Review spending",
          onActionTap: () {
            HapticUtils.light();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionsScreen()),
            );
          },
        ));
      }
    }

    // Insight 2: Top category spending
    if (thisMonthInsights.topCategory.isNotEmpty) {
      final categorySpending = thisMonthInsights.byCategory[thisMonthInsights.topCategory] ?? 0;
      final percentage = (categorySpending / thisMonthInsights.totalSpent * 100);

      if (percentage > 40) {
        insights.add(InsightData(
          message: "${thisMonthInsights.topCategory} is ${percentage.toStringAsFixed(0)}% of your spending. Consider setting a budget for this category.",
          type: InsightType.tip,
          actionLabel: "Set budget",
          onActionTap: () {
            HapticUtils.light();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BudgetScreen()),
            );
          },
        ));
      }
    }

    // Insight 3: Category comparison with last month
    if (lastMonthInsights.byCategory.isNotEmpty && thisMonthInsights.byCategory.isNotEmpty) {
      for (final category in thisMonthInsights.byCategory.keys) {
        final thisMonthAmount = thisMonthInsights.byCategory[category] ?? 0;
        final lastMonthAmount = lastMonthInsights.byCategory[category] ?? 0;

        if (lastMonthAmount > 0) {
          final savings = lastMonthAmount - thisMonthAmount;
          if (savings > 50) {
            insights.add(InsightData(
              message: "You've saved \$${savings.toStringAsFixed(0)} in $category this month! 💰",
              type: InsightType.pattern,
              actionLabel: "See savings",
              onActionTap: () {
                HapticUtils.light();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionsScreen()),
                );
              },
            ));
            break;
          }
        }
      }
    }

    // Insight 4: Transaction count pattern
    if (thisMonthInsights.transactionCount > lastMonthInsights.transactionCount + 10) {
      insights.add(InsightData(
        message: "You made ${thisMonthInsights.transactionCount - lastMonthInsights.transactionCount} more transactions this month. Consider consolidating purchases.",
        type: InsightType.tip,
        actionLabel: "Learn more",
        onActionTap: () {
          HapticUtils.light();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionsScreen()),
          );
        },
      ));
    }

    // Default insight if no specific patterns found
    if (insights.isEmpty && thisMonthInsights.transactionCount > 0) {
      insights.add(InsightData(
        message: "You've made ${thisMonthInsights.transactionCount} transactions this month totaling \$${thisMonthInsights.totalSpent.toStringAsFixed(2)}",
        type: InsightType.pattern,
        actionLabel: "View all",
        onActionTap: () {
          HapticUtils.light();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionsScreen()),
          );
        },
      ));
    }

    return insights.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final currency = PreferencesService.getCurrency() ?? 'USD';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fin Co-Pilot',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              HapticUtils.light();
              context.pushWithFade(const SettingsScreen());
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Spending Card - 35% of screen height
              StreamBuilder<List<model.Transaction>>(
                stream: TransactionService().getCurrentMonthTransactions(user!.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[300]!, Colors.grey[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  final transactions = snapshot.data!;
                  final totalSpent = transactions.fold<double>(0, (sum, t) => sum + t.amount);
                  
                  // Generate sample weekly spending data (last 7 days)
                  final weeklySpending = List.generate(7, (index) => 
                    (totalSpent / 30) * (0.8 + (index % 3) * 0.4)
                  );
                  
                  // For demo: assuming monthly budget of $2000
                  const monthlyBudget = 2000.0;

                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: HeroSpendingCard(
                      monthlySpent: totalSpent,
                      monthlyBudget: monthlyBudget,
                      currency: currency,
                      weeklySpending: weeklySpending,
                    ),
                  );
                },
              ),

              // AI Insight Card - Dynamic insights based on real user data
              StreamBuilder<List<model.Transaction>>(
                stream: TransactionService().getTransactions(user.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final allTransactions = snapshot.data!;
                  final insights = _generateSmartInsights(allTransactions);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AIInsightCard(insights: insights),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Task 3.1: Dashboard Simplification - Keep only 3-4 key cards
              // KEPT: Cash Flow Card (shows income vs expenses)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: CashFlowCard(),
              ),

              const SizedBox(height: 16),

              // REMOVED for V1.0 simplification:
              // - FinancialHealthScoreCard (complex scoring, V2.0)
              // - MoneyStoryCard (AI storytelling, V2.0)
              // - SubscriptionSummaryCard (subscription detection, V2.0)
              // - CoachingTipsDashboardCard (moved to separate coaching screen)

              const SizedBox(height: 32),

              // Recent Transactions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticUtils.light();
                        context.pushWithFade(const TransactionsScreen());
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Recent Transactions List - Show 3 most recent
              StreamBuilder<List<model.Transaction>>(
                stream: TransactionService().getTransactions(user.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final allTransactions = snapshot.data!;
                  // Take only the first 3 transactions (most recent)
                  final transactions = allTransactions.take(3).toList();
                  
                  if (transactions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first transaction to get started',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: transactions.map((transaction) {
                        return CompactTransactionCard(
                          transaction: transaction,
                          onTap: () {
                            HapticUtils.light();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionDetailScreen(
                                  transaction: transaction,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Quick Actions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick Actions Grid
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: QuickActionGrid(),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}