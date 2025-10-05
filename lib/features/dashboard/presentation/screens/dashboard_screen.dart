import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/preferences_service.dart';
import '../../../../services/analytics_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../services/transaction_service.dart';
import '../../../../shared/models/transaction.dart' as model;
import 'ai_test_screen.dart';
import '../../../transactions/presentation/screens/transactions_screen.dart';
import '../../../transactions/presentation/screens/add_transaction_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../insights/presentation/screens/insights_screen.dart';
import '../../../coaching/presentation/screens/coaching_screen.dart';
import '../../../shopping/presentation/screens/shopping_screen.dart';
import '../widgets/coaching_tips_widget.dart';

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
        title: const Text('Fin Co-Pilot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome message
              Text(
                'Welcome back!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                user?.email ?? 'User',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Coaching Tips Widget
              const CoachingTipsWidget(),
              
              const SizedBox(height: 16),

              // Current month spending summary
              StreamBuilder<List<model.Transaction>>(
                stream: TransactionService().getCurrentMonthTransactions(user!.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  final transactions = snapshot.data!;
                  final totalInUserCurrency = transactions.fold<double>(
                    0,
                    (sum, t) => sum + t.amount,
                  );

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'This Month',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    CurrencyUtils.formatAmount(totalInUserCurrency, currency),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${transactions.length} transactions',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Currency preference
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.green),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Currency',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '$currency (${CurrencyUtils.getCurrencySymbol(currency)})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // AI Test Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.psychology,
                      size: 40,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'M3: AI Orchestrator Ready!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Test the AI agent routing system',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AITestScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Test AI Orchestrator'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Column(
                children: [
                  const SizedBox(height: 16),
                    
                    // Quick actions
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.add_circle,
                            label: 'Add Transaction',
                            color: Colors.blue,
                            onTap: () {
                              AnalyticsService.logFeatureUsed('add_transaction_button');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddTransactionScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.list,
                            label: 'View All',
                            color: Colors.green,
                            onTap: () {
                              AnalyticsService.logFeatureUsed('view_all_transactions_button');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TransactionsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.analytics,
                            label: 'Insights',
                            color: Colors.purple,
                            onTap: () {
                              AnalyticsService.logInsightsViewed();
                              AnalyticsService.logFeatureUsed('insights_button');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const InsightsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.psychology,
                            label: 'Test AI',
                            color: Colors.orange,
                            onTap: () {
                              AnalyticsService.logFeatureUsed('ai_test_button');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AITestScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.school,
                            label: 'Coaching',
                            color: Colors.teal,
                            onTap: () {
                              AnalyticsService.logFeatureUsed('coaching_button');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CoachingScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.shopping_bag,
                            label: 'Shopping',
                            color: Colors.indigo,
                            onTap: () {
                              AnalyticsService.logFeatureUsed('shopping_button');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ShoppingScreen(),
                                ),
                              );
                            },
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
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}