import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../services/preferences_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final currency = PreferencesService.getCurrency() ?? 'USD';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Manager'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('monthly_budgets')
            .doc('${user.uid}_$currentMonth')
            .snapshots(),
        builder: (context, monthlyBudgetSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('budgets')
                .where('user_id', isEqualTo: user.uid)
                .where('month', isEqualTo: currentMonth)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final budgets = snapshot.data?.docs ?? [];
              final monthlyBudgetData = monthlyBudgetSnapshot.data?.data() as Map<String, dynamic>?;
              final totalMonthlyBudget = (monthlyBudgetData?['totalBudget'] as num?)?.toDouble() ?? 0.0;

              return CustomScrollView(
                slivers: [
                  // Header with total budget info
                  SliverToBoxAdapter(
                    child: _buildHeaderCard(budgets, currency, totalMonthlyBudget, user.uid, currentMonth),
                  ),

                  // Budget list
                  if (budgets.isEmpty && totalMonthlyBudget == 0)
                    SliverFillRemaining(
                      child: _buildEmptyState(user.uid, currentMonth),
                    )
                  else if (budgets.isEmpty)
                    SliverFillRemaining(
                      child: _buildNoCategoryBudgetsState(user.uid, currentMonth, totalMonthlyBudget),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final budgetDoc = budgets[index];
                            final budgetData = budgetDoc.data() as Map<String, dynamic>;
                            return _buildBudgetCard(
                              budgetDoc.id,
                              budgetData,
                              currency,
                              user.uid,
                            );
                          },
                          childCount: budgets.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _showAddBudgetDialog(user.uid, currentMonth),
            heroTag: 'add_category',
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    List<QueryDocumentSnapshot> budgets,
    String currency,
    double totalMonthlyBudget,
    String userId,
    String currentMonth,
  ) {
    double allocatedBudget = 0;
    for (final budget in budgets) {
      final data = budget.data() as Map<String, dynamic>;
      allocatedBudget += (data['amount'] as num).toDouble();
    }

    final unallocated = totalMonthlyBudget - allocatedBudget;
    final hasMonthlyBudget = totalMonthlyBudget > 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Budget',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: () => _showSetMonthlyBudgetDialog(userId, currentMonth, totalMonthlyBudget),
                icon: Icon(
                  hasMonthlyBudget ? Icons.edit : Icons.add_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: hasMonthlyBudget ? 'Edit Monthly Budget' : 'Set Monthly Budget',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasMonthlyBudget
                ? CurrencyUtils.formatAmount(totalMonthlyBudget, currency)
                : 'Not Set',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (hasMonthlyBudget) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBudgetStat(
                    'Allocated',
                    CurrencyUtils.formatAmount(allocatedBudget, currency),
                    Icons.pie_chart,
                  ),
                  Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                  _buildBudgetStat(
                    'Unallocated',
                    CurrencyUtils.formatAmount(unallocated, currency),
                    Icons.account_balance_wallet,
                    color: unallocated < 0 ? Colors.red.shade200 : Colors.green.shade200,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            hasMonthlyBudget
                ? '${budgets.length} ${budgets.length == 1 ? 'category' : 'categories'}'
                : 'Tap + to set your monthly budget',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStat(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String userId, String currentMonth) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'Start Your Budget Journey',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set a monthly budget and divide it\nacross categories to track your spending',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showSetMonthlyBudgetDialog(userId, currentMonth, 0),
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Set Monthly Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCategoryBudgetsState(String userId, String currentMonth, double totalBudget) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'Divide Your Budget',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have ${CurrencyUtils.formatAmount(totalBudget, PreferencesService.getCurrency() ?? 'USD')} to allocate.\nCreate category budgets to organize your spending.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddBudgetDialog(userId, currentMonth),
              icon: const Icon(Icons.add),
              label: const Text('Add Category Budget'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetMonthlyBudgetDialog(String userId, String currentMonth, double currentBudget) {
    final TextEditingController budgetController = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentBudget > 0 ? 'Edit Monthly Budget' : 'Set Monthly Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your total monthly budget. You can then divide it across categories.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixText: '\$ ',
                hintText: '0.00',
                labelText: 'Monthly Budget',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ],
        ),
        actions: [
          if (currentBudget > 0)
            TextButton(
              onPressed: () async {
                try {
                  await _firestore
                      .collection('monthly_budgets')
                      .doc('${userId}_$currentMonth')
                      .delete();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  HapticUtils.success();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Monthly budget removed')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final budget = double.tryParse(budgetController.text);
              if (budget == null || budget <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              try {
                await _firestore
                    .collection('monthly_budgets')
                    .doc('${userId}_$currentMonth')
                    .set({
                  'userId': userId,
                  'month': currentMonth,
                  'totalBudget': budget,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!context.mounted) return;
                Navigator.pop(context);
                HapticUtils.success();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Monthly budget saved successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    String budgetId,
    Map<String, dynamic> budgetData,
    String currency,
    String userId,
  ) {
    final category = budgetData['category'] as String;
    final budgetAmount = (budgetData['amount'] as num).toDouble();
    final currentSpending = (budgetData['currentSpending'] as num?)?.toDouble() ?? 0;
    final percentage = budgetAmount > 0 ? (currentSpending / budgetAmount) * 100 : 0;

    Color progressColor;
    if (percentage >= 100) {
      progressColor = Colors.red;
    } else if (percentage >= 90) {
      progressColor = Colors.orange;
    } else if (percentage >= 75) {
      progressColor = Colors.amber;
    } else {
      progressColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          HapticUtils.light();
          _showEditBudgetDialog(budgetId, budgetData, userId);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: progressColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category[0].toUpperCase() + category.substring(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${CurrencyUtils.formatAmount(currentSpending, currency)} / ${CurrencyUtils.formatAmount(budgetAmount, currency)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0, 1),
                  backgroundColor: progressColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ),
              if (percentage >= 90) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        percentage >= 100 ? Icons.error_outline : Icons.warning_amber_rounded,
                        size: 16,
                        color: progressColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          percentage >= 100
                              ? 'Budget exceeded by ${CurrencyUtils.formatAmount(currentSpending - budgetAmount, currency)}'
                              : 'Only ${CurrencyUtils.formatAmount(budgetAmount - currentSpending, currency)} remaining',
                          style: TextStyle(
                            fontSize: 12,
                            color: progressColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return Icons.shopping_cart;
      case 'dining':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.health_and_safety;
      case 'bills':
        return Icons.receipt_long;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      default:
        return Icons.category;
    }
  }

  void _showAddBudgetDialog(String userId, String month) {
    final TextEditingController amountController = TextEditingController();
    String selectedCategory = 'groceries';

    final categories = [
      'groceries',
      'dining',
      'transport',
      'entertainment',
      'shopping',
      'health',
      'bills',
      'education',
      'travel',
      'other',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(_getCategoryIcon(category), size: 20),
                        const SizedBox(width: 12),
                        Text(category[0].toUpperCase() + category.substring(1)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Budget Amount',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                  hintText: '0.00',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                try {
                  await _firestore.collection('budgets').add({
                    'userId': userId,
                    'category': selectedCategory,
                    'amount': amount,
                    'month': month,
                    'currentSpending': 0,
                    'createdAt': FieldValue.serverTimestamp(),
                    'overageAlertSent': false,
                    'ninetyPercentAlertSent': false,
                    'seventyFivePercentAlertSent': false,
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  HapticUtils.success();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Budget created successfully')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating budget: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBudgetDialog(
    String budgetId,
    Map<String, dynamic> budgetData,
    String userId,
  ) {
    final TextEditingController amountController = TextEditingController(
      text: (budgetData['amount'] as num).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${budgetData['category']} Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Amount',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixText: '\$ ',
                hintText: '0.00',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await _firestore.collection('budgets').doc(budgetId).delete();
                if (!context.mounted) return;
                Navigator.pop(context);
                HapticUtils.success();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget deleted')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting budget: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              try {
                await _firestore.collection('budgets').doc(budgetId).update({
                  'amount': amount,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (!context.mounted) return;
                Navigator.pop(context);
                HapticUtils.success();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget updated successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating budget: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
