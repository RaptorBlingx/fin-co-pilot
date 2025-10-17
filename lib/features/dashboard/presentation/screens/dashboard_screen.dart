import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/preferences_service.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/transaction_service.dart';
import '../../../../shared/models/transaction.dart' as model;
import '../../../transactions/presentation/screens/transactions_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

import '../../widgets/hero_spending_card.dart';
import '../../widgets/ai_insight_card.dart';
import '../../widgets/compact_transaction_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/navigation/page_transitions.dart';

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

              // AI Insight Card - Single highlighted insight
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: AIInsightCard(
                  insights: [
                    InsightData(
                      message: "You're spending 20% less on dining this month. Keep it up! 🎉",
                      type: InsightType.achievement,
                      actionLabel: "View details",
                    ),
                    InsightData(
                      message: "Grocery spending is trending higher. Consider setting a weekly budget.",
                      type: InsightType.tip,
                      actionLabel: "Set budget",
                    ),
                    InsightData(
                      message: "You've saved \$150 this month by reducing subscriptions! 💰",
                      type: InsightType.pattern,
                      actionLabel: "See savings",
                    ),
                  ],
                ),
              ),

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
                            // Navigate to transaction details or edit screen
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