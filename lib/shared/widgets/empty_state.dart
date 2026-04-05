import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/constants/app_icons.dart';
import 'premium_button.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PREMIUM EMPTY STATE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class EmptyState extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = iconColor ?? colors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon in tinted circle
            Container(
              padding: const EdgeInsets.all(DesignTokens.space24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withOpacity(isDark ? 0.12 : 0.08),
                border: Border.all(
                  color: tint.withOpacity(isDark ? 0.15 : 0.12),
                ),
              ),
              child: Icon(icon, size: DesignTokens.iconXXL, color: tint),
            )
                .animate()
                .fadeIn(duration: DesignTokens.durationNormal, curve: DesignTokens.curveDecelerate)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: DesignTokens.durationNormal, curve: DesignTokens.curveDecelerate),

            const SizedBox(height: DesignTokens.space24),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            )
                .animate(delay: const Duration(milliseconds: 80))
                .fadeIn(duration: DesignTokens.durationFast, curve: DesignTokens.curveDecelerate)
                .slideY(begin: 0.15, end: 0, duration: DesignTokens.durationNormal, curve: DesignTokens.curveDecelerate),

            const SizedBox(height: DesignTokens.space12),

            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            )
                .animate(delay: const Duration(milliseconds: 160))
                .fadeIn(duration: DesignTokens.durationFast, curve: DesignTokens.curveDecelerate)
                .slideY(begin: 0.15, end: 0, duration: DesignTokens.durationNormal, curve: DesignTokens.curveDecelerate),

            // CTA Button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.space24),
              PremiumButton(
                onPressed: onAction!,
                variant: PremiumButtonVariant.primary,
                child: Text(actionLabel!),
              )
                  .animate(delay: const Duration(milliseconds: 240))
                  .fadeIn(duration: DesignTokens.durationFast, curve: DesignTokens.curveDecelerate)
                  .slideY(begin: 0.15, end: 0, duration: DesignTokens.durationNormal, curve: DesignTokens.curveDecelerate),
            ],
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SPECIFIC EMPTY STATES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class NoTransactionsEmpty extends StatelessWidget {
  final VoidCallback? onAdd;

  const NoTransactionsEmpty({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: AppIcons.receipt,
      iconColor: AppTheme.accentEmerald,
      title: 'Your Financial Journey Starts Here',
      message: 'Add your first transaction and let us help you understand your spending.',
      actionLabel: 'Add Transaction',
      onAction: onAdd,
    );
  }
}

class NoInsightsEmpty extends StatelessWidget {
  const NoInsightsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: AppIcons.insights,
      iconColor: AppTheme.primaryIndigo,
      title: 'Insights Are on the Way',
      message: 'Add some transactions and we\'ll surface smart spending patterns for you.',
    );
  }
}

class NoCoachingTipsEmpty extends StatelessWidget {
  final VoidCallback? onGenerate;

  const NoCoachingTipsEmpty({super.key, this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: AppIcons.coach,
      iconColor: AppTheme.amber500,
      title: 'Your Coach Is Ready',
      message: 'Generate personalized tips based on your spending habits.',
      actionLabel: 'Generate Tips',
      onAction: onGenerate,
    );
  }
}

class NoSearchResultsEmpty extends StatelessWidget {
  final String query;

  const NoSearchResultsEmpty({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: AppIcons.search,
      iconColor: AppTheme.slate400,
      title: 'No Results Found',
      message: 'We couldn\'t find anything matching "$query". Try a different search.',
    );
  }
}
