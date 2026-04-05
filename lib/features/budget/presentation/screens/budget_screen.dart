import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/categories.dart';
import '../../../../services/preferences_service.dart';
import '../../../../services/custom_category_service.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/animated_counter.dart';
import '../../../../shared/widgets/add_category_sheet.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(userIdProvider);
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final currency = PreferencesService.getCurrency() ?? 'USD';

    final budgetsAsync = ref.watch(budgetsProvider);
    final monthlyBudgetTotal = ref.watch(monthlyBudgetProvider).valueOrNull ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Manager'),
        centerTitle: true,
      ),
      body: budgetsAsync.when(
        loading: () => Padding(
          padding: EdgeInsets.all(DesignTokens.space16),
          child: Column(
            children: List.generate(4, (_) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.space12),
              child: const CardSkeleton(),
            )),
          ),
        ),
        error: (e, _) => ErrorStates.generic(
          context,
          'Unable to load budgets.',
          onRetry: () => ref.invalidate(budgetsProvider),
        ),
        data: (budgetsList) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeaderCardFromList(budgetsList, currency, monthlyBudgetTotal, uid, currentMonth),
              ),
              if (budgetsList.isEmpty && monthlyBudgetTotal == 0)
                SliverFillRemaining(child: _buildEmptyState(uid, currentMonth))
              else if (budgetsList.isEmpty)
                SliverFillRemaining(child: _buildNoCategoryBudgetsState(uid, currentMonth, monthlyBudgetTotal))
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final budgetData = budgetsList[index];
                        return _buildBudgetCard(
                          budgetData['id'] as String,
                          budgetData,
                          currency,
                          uid,
                        );
                      },
                      childCount: budgetsList.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticUtils.light();
          _showAddBudgetDialog(uid, currentMonth);
        },
        heroTag: 'add_category',
        icon: Icon(PhosphorIcons.plus(), size: DesignTokens.iconSM),
        label: const Text('Add Category'),
        backgroundColor: AppTheme.primaryIndigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeaderCardFromList(
    List<Map<String, dynamic>> budgets,
    String currency,
    double totalMonthlyBudget,
    String userId,
    String currentMonth,
  ) {
    double allocatedBudget = 0;
    for (final data in budgets) {
      allocatedBudget += (data['amount'] as num).toDouble();
    }

    final unallocated = totalMonthlyBudget - allocatedBudget;
    final hasMonthlyBudget = totalMonthlyBudget > 0;

    return GlassCard(
      padding: EdgeInsets.all(DesignTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Budget',
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: () async {
                  HapticUtils.light();
                  await _showSetMonthlyBudgetDialog(userId, currentMonth, totalMonthlyBudget);
                  if (mounted) setState(() {});
                },
                icon: Icon(
                  hasMonthlyBudget
                      ? PhosphorIcons.pencilSimple()
                      : PhosphorIcons.plusCircle(),
                  color: AppTheme.primaryIndigo,
                  size: DesignTokens.iconSM,
                ),
                tooltip: hasMonthlyBudget ? 'Edit Monthly Budget' : 'Set Monthly Budget',
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space8),
          hasMonthlyBudget
              ? AnimatedCounter(
                  value: totalMonthlyBudget,
                  prefix: CurrencyUtils.getCurrencySymbol(currency),
                  style: context.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  'Not Set',
                  style: context.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface.withOpacity(0.3),
                  ),
                ),
          if (hasMonthlyBudget) ...[
            SizedBox(height: DesignTokens.space16),
            Container(
              padding: EdgeInsets.all(DesignTokens.space12),
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBudgetStat(
                    'Allocated',
                    CurrencyUtils.formatAmount(allocatedBudget, currency),
                    PhosphorIcons.chartPie(PhosphorIconsStyle.duotone),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.colors.onSurface.withOpacity(0.1),
                  ),
                  _buildBudgetStat(
                    'Unallocated',
                    CurrencyUtils.formatAmount(unallocated, currency),
                    PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
                    color: unallocated < 0 ? AppTheme.rose500 : AppTheme.accentEmerald,
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: DesignTokens.space8),
          Text(
            hasMonthlyBudget
                ? '${budgets.length} ${budgets.length == 1 ? 'category' : 'categories'}'
                : 'Tap + to set your monthly budget',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: DesignTokens.durationNormal)
        .slideY(begin: -0.1, end: 0);
  }

  Widget _buildBudgetStat(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? context.colors.onSurface.withOpacity(0.6), size: DesignTokens.iconSM),
        SizedBox(height: DesignTokens.space4),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.onSurface.withOpacity(0.5),
          ),
        ),
        SizedBox(height: DesignTokens.space2),
        Text(
          value,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? context.colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String userId, String currentMonth) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
              size: 80,
              color: context.colors.onSurface.withOpacity(0.15),
            ),
            SizedBox(height: DesignTokens.space24),
            Text(
              'Start Your Budget Journey',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: DesignTokens.space12),
            Text(
              'Set a monthly budget and divide it\nacross categories to track your spending',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: DesignTokens.space32),
            PremiumButton(
              onPressed: () async {
                await _showSetMonthlyBudgetDialog(userId, currentMonth, 0);
                if (mounted) setState(() {});
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.wallet(), size: DesignTokens.iconSM),
                  SizedBox(width: DesignTokens.space8),
                  const Text('Set Monthly Budget'),
                ],
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

  Widget _buildNoCategoryBudgetsState(String userId, String currentMonth, double totalBudget) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.chartPie(PhosphorIconsStyle.duotone),
              size: 80,
              color: context.colors.onSurface.withOpacity(0.15),
            ),
            SizedBox(height: DesignTokens.space24),
            Text(
              'Divide Your Budget',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: DesignTokens.space12),
            Text(
              'You have ${CurrencyUtils.formatAmount(totalBudget, PreferencesService.getCurrency() ?? 'USD')} to allocate.\nCreate category budgets to organize your spending.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: DesignTokens.space32),
            PremiumButton(
              onPressed: () => _showAddBudgetDialog(userId, currentMonth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.plus(), size: DesignTokens.iconSM),
                  SizedBox(width: DesignTokens.space8),
                  const Text('Add Category Budget'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetMonthlyBudgetDialog(String userId, String currentMonth, double currentBudget) async {
    final TextEditingController budgetController = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toString() : '',
    );
    final currencySymbol = CurrencyUtils.getCurrencySymbol(PreferencesService.getCurrency() ?? 'USD');

    await showDialog(
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
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixText: '$currencySymbol ',
                hintText: '0.00',
                labelText: 'Monthly Budget',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
              child: Text('Remove', style: TextStyle(color: AppTheme.rose500)),
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
                  'user_id': userId,  // Fixed: was 'userId', rules expect 'user_id'
                  'userId': userId,    // Keep both for compatibility
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
      progressColor = AppTheme.rose500;
    } else if (percentage >= 90) {
      progressColor = AppTheme.amber500;
    } else if (percentage >= 75) {
      progressColor = AppTheme.amber500;
    } else {
      progressColor = AppTheme.accentEmerald;
    }

    final catData = AppCategories.getCategoryByName(category);

    return GlassCard(
      padding: EdgeInsets.all(DesignTokens.space16),
      onTap: () {
        HapticUtils.light();
        _showEditBudgetDialog(budgetId, budgetData, userId);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.space8),
                decoration: BoxDecoration(
                  color: catData.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                ),
                child: Icon(
                  catData.icon,
                  color: catData.color,
                  size: DesignTokens.iconMD,
                ),
              ),
              SizedBox(width: DesignTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category[0].toUpperCase() + category.substring(1),
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: DesignTokens.space2),
                    Text(
                      '${CurrencyUtils.formatAmount(currentSpending, currency)} / ${CurrencyUtils.formatAmount(budgetAmount, currency)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0, 1).toDouble(),
              backgroundColor: progressColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          if (percentage >= 90) ...[
            SizedBox(height: DesignTokens.space12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.space12,
                vertical: DesignTokens.space8,
              ),
              decoration: BoxDecoration(
                color: progressColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
              ),
              child: Row(
                children: [
                  Icon(
                    percentage >= 100
                        ? PhosphorIcons.warningCircle(PhosphorIconsStyle.fill)
                        : PhosphorIcons.warning(PhosphorIconsStyle.fill),
                    size: 16,
                    color: progressColor,
                  ),
                  SizedBox(width: DesignTokens.space8),
                  Expanded(
                    child: Text(
                      percentage >= 100
                          ? 'Budget exceeded by ${CurrencyUtils.formatAmount(currentSpending - budgetAmount, currency)}'
                          : 'Only ${CurrencyUtils.formatAmount(budgetAmount - currentSpending, currency)} remaining',
                      style: context.textTheme.labelSmall?.copyWith(
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
    )
        .animate()
        .fadeIn(duration: DesignTokens.durationNormal)
        .slideX(begin: 0.05, end: 0);
  }

  void _showAddBudgetDialog(String userId, String month) async {
    final TextEditingController amountController = TextEditingController();
    String selectedCategory = 'groceries';

    final baseCategories = [
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

    // Load custom categories
    final customCats = await CustomCategoryService().getCustomCategories();
    final customNames = customCats.map((c) => c.name.toLowerCase()).toList();
    final categories = [...baseCategories, ...customNames];

    if (!mounted) return;

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
              SizedBox(height: DesignTokens.space8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: categories.map((category) {
                        final catData = AppCategories.getCategoryByName(category);
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(catData.icon, size: 20, color: catData.color),
                              SizedBox(width: DesignTokens.space12),
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
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(PhosphorIcons.plus(), color: AppTheme.primaryIndigo),
                    tooltip: 'Add custom category',
                    onPressed: () async {
                      final result = await showAddCategorySheet(context);
                      if (result != null) {
                        final newName = result.name.toLowerCase();
                        setState(() {
                          categories.add(newName);
                          selectedCategory = newName;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Budget Amount',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: DesignTokens.space8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixText: '${CurrencyUtils.getCurrencySymbol(PreferencesService.getCurrency() ?? 'USD')} ',
                  hintText: '0.00',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    'user_id': userId,  // Fixed: was 'userId', rules expect 'user_id'
                    'userId': userId,    // Keep both for compatibility
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
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixText: '${CurrencyUtils.getCurrencySymbol(PreferencesService.getCurrency() ?? 'USD')} ',
                hintText: '0.00',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            child: Text('Delete', style: TextStyle(color: AppTheme.rose500)),
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
