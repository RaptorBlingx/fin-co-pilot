import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../services/transaction_service.dart';
import '../../../../services/insights_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../shared/models/transaction.dart' as model;
import '../../../../shared/models/spending_insights.dart';
import '../../../../core/utils/currency_utils.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final TransactionService _transactionService = TransactionService();
  final AuthService _authService = AuthService();
  
  bool _isLoadingAI = false;
  List<String> _aiInsights = [];

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: StreamBuilder<List<model.Transaction>>(
        stream: _transactionService.getCurrentMonthTransactions(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No data to analyze yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some transactions to see insights',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final insights = InsightsService.generateInsights(transactions);
          final currency = transactions.first.currency;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                _SummaryCard(insights: insights, currency: currency),
                
                const SizedBox(height: 24),

                // Category breakdown
                _CategoryBreakdownChart(insights: insights, currency: currency),

                const SizedBox(height: 24),

                // Top merchants
                _TopMerchants(insights: insights, currency: currency),

                const SizedBox(height: 24),

                // AI Insights
                _AIInsightsSection(
                  insights: insights,
                  transactions: transactions,
                  aiInsights: _aiInsights,
                  isLoading: _isLoadingAI,
                  onGenerate: () => _generateAIInsights(transactions, insights),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateAIInsights(
    List<model.Transaction> transactions,
    SpendingInsights insights,
  ) async {
    setState(() => _isLoadingAI = true);

    try {
      final aiInsights = await InsightsService.generateAIInsights(
        transactions,
        insights,
      );

      setState(() {
        _aiInsights = aiInsights;
        _isLoadingAI = false;
      });
    } catch (e) {
      setState(() => _isLoadingAI = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating insights: ${e.toString()}')),
        );
      }
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final SpendingInsights insights;
  final String currency;

  const _SummaryCard({required this.insights, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Month',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyUtils.formatAmount(insights.totalSpent, currency),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.receipt_long,
                    label: 'Transactions',
                    value: '${insights.transactionCount}',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.trending_up,
                    label: 'Avg/Day',
                    value: CurrencyUtils.formatAmount(insights.averagePerDay, currency),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CategoryBreakdownChart extends StatelessWidget {
  final SpendingInsights insights;
  final String currency;

  const _CategoryBreakdownChart({
    required this.insights,
    required this.currency,
  });

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'groceries': return Colors.green;
      case 'dining': return Colors.orange;
      case 'transport': return Colors.blue;
      case 'entertainment': return Colors.purple;
      case 'shopping': return Colors.pink;
      case 'health': return Colors.red;
      case 'bills': return Colors.brown;
      case 'education': return Colors.indigo;
      case 'travel': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedCategories = insights.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Pie chart
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: sortedCategories.map((entry) {
                          final percentage = (entry.value / insights.totalSpent) * 100;
                          return PieChartSectionData(
                            color: _getCategoryColor(entry.key),
                            value: entry.value,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Legend
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sortedCategories.take(5).map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Category list
            ...sortedCategories.map((entry) {
              final percentage = (entry.value / insights.totalSpent) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key[0].toUpperCase() + entry.key.substring(1),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      CurrencyUtils.formatAmount(entry.value, currency),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TopMerchants extends StatelessWidget {
  final SpendingInsights insights;
  final String currency;

  const _TopMerchants({required this.insights, required this.currency});

  @override
  Widget build(BuildContext context) {
    final topMerchants = insights.byMerchant.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Merchants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...topMerchants.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.store, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      CurrencyUtils.formatAmount(entry.value, currency),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AIInsightsSection extends StatelessWidget {
  final SpendingInsights insights;
  final List<model.Transaction> transactions;
  final List<String> aiInsights;
  final bool isLoading;
  final VoidCallback onGenerate;

  const _AIInsightsSection({
    required this.insights,
    required this.transactions,
    required this.aiInsights,
    required this.isLoading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'AI Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!isLoading && aiInsights.isEmpty)
                  TextButton.icon(
                    onPressed: onGenerate,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Generate'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Analyzing your spending patterns...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (aiInsights.isEmpty)
              const Text(
                'Tap "Generate" to get personalized financial insights powered by AI',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...aiInsights.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}