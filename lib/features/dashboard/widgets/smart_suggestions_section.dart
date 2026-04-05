import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/navigation/page_transitions.dart';
import '../../../shared/widgets/staggered_animation.dart';
import '../../../features/financial_copilot/presentation/screens/financial_copilot_screen.dart';
import '../../../models/transaction.dart' as model;
import 'smart_suggestion_card.dart';

class SmartSuggestionsSection extends ConsumerWidget {
  const SmartSuggestionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(currentMonthTransactionsProvider).valueOrNull ?? [];
    final budgets = ref.watch(budgetsProvider).valueOrNull ?? [];

    final suggestions = _buildSuggestions(context, transactions, budgets);

    return Column(
      children: suggestions.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: entry.key < suggestions.length - 1 ? DesignTokens.space8 : 0,
          ),
          child: SmartSuggestionCard(suggestion: entry.value).staggered(entry.key),
        );
      }).toList(),
    );
  }

  List<SmartSuggestion> _buildSuggestions(
    BuildContext context,
    List<model.Transaction> transactions,
    List<Map<String, dynamic>> budgets,
  ) {
    final suggestions = <SmartSuggestion>[];
    final today = DateTime.now();

    // Check if user has added a transaction today
    final hasTransactionToday = transactions.any((t) =>
        t.date.year == today.year &&
        t.date.month == today.month &&
        t.date.day == today.day);

    if (!hasTransactionToday) {
      suggestions.add(SmartSuggestion(
        title: 'Log today\'s spending',
        subtitle: 'No transactions recorded today',
        icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
        color: AppTheme.primaryIndigo,
        onTap: () => context.pushWithSlideUp(const FinancialCopilotScreen()),
      ));
    }

    // Check budget status
    if (budgets.isEmpty) {
      suggestions.add(SmartSuggestion(
        title: 'Set up a budget',
        subtitle: 'Take control of your spending',
        icon: PhosphorIcons.chartPieSlice(PhosphorIconsStyle.duotone),
        color: AppTheme.accentEmerald,
        onTap: () => context.push(AppConstants.routeCoaching),
      ));
    } else {
      // Check if any budget is over 80%
      for (final budget in budgets) {
        final limit = (budget['amount'] as num?)?.toDouble() ?? 0;
        final spent = (budget['spent'] as num?)?.toDouble() ?? 0;
        if (limit > 0 && spent / limit >= 0.8) {
          suggestions.add(SmartSuggestion(
            title: 'Budget alert',
            subtitle: '${budget['category'] ?? 'A category'} is ${((spent / limit) * 100).toInt()}% spent',
            icon: PhosphorIcons.warning(PhosphorIconsStyle.duotone),
            color: AppTheme.amber500,
            onTap: () => context.push(AppConstants.routeCoaching),
          ));
          break; // Only show one budget alert
        }
      }
    }

    // Check health score
    suggestions.add(SmartSuggestion(
      title: 'Financial health check',
      subtitle: 'See how your finances are doing',
      icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.duotone),
      color: AppTheme.rose400,
      onTap: () => context.push(AppConstants.routeHealthScore),
    ));

    // Smart shopping suggestion if enough transactions
    if (transactions.length >= 5) {
      suggestions.add(SmartSuggestion(
        title: 'Find better prices',
        subtitle: 'Compare prices on recent purchases',
        icon: PhosphorIcons.shoppingBag(PhosphorIconsStyle.duotone),
        color: AppTheme.accentPurple,
        onTap: () => context.push(AppConstants.routeShopping),
      ));
    }

    // Limit to 3 suggestions max
    return suggestions.take(3).toList();
  }
}
