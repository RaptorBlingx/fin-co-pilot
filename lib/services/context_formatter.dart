import '../models/user_context.dart';

/// Formats [UserContext] into structured text blocks for agent system instructions.
class ContextFormatter {
  const ContextFormatter._();

  /// Full system instruction block with all context sections.
  static String formatForSystemInstruction(UserContext ctx) {
    final buffer = StringBuffer();

    buffer.writeln('=== USER PROFILE ===');
    buffer.writeln('Name: ${ctx.displayName ?? "User"}');
    buffer.writeln('Currency: ${ctx.primaryCurrency} (${ctx.currencySymbol})');
    buffer.writeln('Language: ${ctx.primaryLanguage}');
    if (ctx.country != null) buffer.writeln('Country: ${ctx.country}');
    buffer.writeln('Account age: ${ctx.accountAgeDays} days');
    buffer.writeln('Tier: ${ctx.subscriptionTier}');

    buffer.writeln();
    buffer.writeln('=== TEMPORAL CONTEXT ===');
    buffer.writeln('Time: ${ctx.timeOfDay} (${ctx.dayOfWeek})');
    buffer.writeln('Month position: ${ctx.monthPosition}');
    buffer.writeln('Timezone: ${ctx.timezone}');

    if (ctx.hasBudget) {
      buffer.writeln();
      buffer.writeln('=== BUDGET ===');
      buffer.writeln(
          'Budget: ${ctx.currencySymbol}${ctx.budgetAmount!.toStringAsFixed(2)}');
      buffer.writeln(
          'Spent: ${ctx.currencySymbol}${ctx.budgetSpent?.toStringAsFixed(2) ?? "0.00"}');
      if (ctx.budgetUtilization != null) {
        buffer.writeln(
            'Utilization: ${(ctx.budgetUtilization! * 100).toStringAsFixed(0)}%');
      }
      if (ctx.budgetDaysRemaining != null) {
        buffer.writeln('Days remaining: ${ctx.budgetDaysRemaining}');
      }
    }

    if (ctx.hasSpendingHistory) {
      buffer.writeln();
      buffer.writeln('=== SPENDING SNAPSHOT ===');
      buffer.writeln(
          'This month: ${ctx.currencySymbol}${ctx.monthTotal.toStringAsFixed(2)}');
      if (ctx.lastMonthTotal > 0) {
        buffer.writeln(
            'Last month: ${ctx.currencySymbol}${ctx.lastMonthTotal.toStringAsFixed(2)}');
        buffer.writeln(
            'Change: ${ctx.monthDelta >= 0 ? "+" : ""}${ctx.monthDelta.toStringAsFixed(1)}%');
      }
      if (ctx.topCategories.isNotEmpty) {
        buffer.writeln('Top categories:');
        for (final cat in ctx.topCategories) {
          buffer.writeln(
              '  - ${cat.name}: ${ctx.currencySymbol}${cat.amount.toStringAsFixed(2)} (${cat.txCount} txs)');
        }
      }
      if (ctx.recentMerchants.isNotEmpty) {
        buffer.writeln('Recent merchants: ${ctx.recentMerchants.join(", ")}');
      }
    }

    if (ctx.memoryDossier != null && ctx.memoryDossier!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('=== USER MEMORY ===');
      buffer.writeln(ctx.memoryDossier);
    }

    if (ctx.conversationHistory != null && ctx.conversationHistory!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('=== PREVIOUS CONVERSATIONS ===');
      buffer.writeln(ctx.conversationHistory);
    }

    return buffer.toString();
  }

  /// Short budget-only section for agents that only need budget awareness.
  static String formatBudgetSection(UserContext ctx) {
    if (!ctx.hasBudget) return 'No budget set.';

    final buffer = StringBuffer();
    buffer.writeln(
        'Budget: ${ctx.currencySymbol}${ctx.budgetAmount!.toStringAsFixed(2)}');
    buffer.writeln(
        'Spent: ${ctx.currencySymbol}${ctx.budgetSpent?.toStringAsFixed(2) ?? "0.00"}');
    if (ctx.budgetUtilization != null) {
      buffer.writeln(
          'Utilization: ${(ctx.budgetUtilization! * 100).toStringAsFixed(0)}%');
    }
    return buffer.toString();
  }

  /// Core rules every agent should follow, parameterized by user's currency.
  static String formatCoreRules(UserContext ctx) {
    return '''
IMPORTANT RULES:
- Always use ${ctx.primaryCurrency} (${ctx.currencySymbol}) for monetary values — NEVER hardcode \$.
- Respond in ${ctx.primaryLanguage}.
- Keep responses concise and actionable.
''';
  }
}
