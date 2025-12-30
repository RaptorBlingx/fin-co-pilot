import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Beautiful empty state widget with illustrations
///
/// Shows engaging empty states throughout the app with helpful CTAs
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? lottieAsset;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Color? iconColor;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.lottieAsset,
    this.actionLabel,
    this.onActionPressed,
    this.iconColor,
    this.iconSize = 120,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            if (lottieAsset != null)
              Lottie.asset(
                lottieAsset!,
                width: iconSize * 1.5,
                height: iconSize * 1.5,
                repeat: true,
              )
            else if (icon != null)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: (iconColor ?? theme.colorScheme.primary)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: iconSize,
                        color: iconColor ?? theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),

            // Title
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Message
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Text(
                      message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),

            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 32),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: ElevatedButton.icon(
                        onPressed: onActionPressed,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(actionLabel!),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Predefined empty states for common scenarios
class EmptyStates {
  // No transactions
  static Widget noTransactions(BuildContext context, VoidCallback onAddPressed) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: 'No Transactions Yet',
      message: 'Start tracking your spending by adding your first transaction',
      actionLabel: 'Add Transaction',
      onActionPressed: onAddPressed,
      iconColor: Colors.blue,
    );
  }

  // No budgets
  static Widget noBudgets(BuildContext context, VoidCallback onCreatePressed) {
    return EmptyStateWidget(
      icon: Icons.account_balance_wallet_outlined,
      title: 'No Budgets Set',
      message: 'Create a budget to track your spending and reach your financial goals',
      actionLabel: 'Create Budget',
      onActionPressed: onCreatePressed,
      iconColor: Colors.green,
    );
  }

  // No insights
  static Widget noInsights(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.lightbulb_outline,
      title: 'No Insights Yet',
      message: 'Keep adding transactions and we\'ll generate personalized insights for you',
      iconColor: Colors.amber,
    );
  }

  // No subscriptions
  static Widget noSubscriptions(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.repeat_outlined,
      title: 'No Subscriptions Detected',
      message: 'We\'ll automatically detect recurring payments as you add transactions',
      iconColor: Colors.purple,
    );
  }

  // No receipts
  static Widget noReceipts(BuildContext context, VoidCallback onScanPressed) {
    return EmptyStateWidget(
      icon: Icons.receipt_outlined,
      title: 'No Receipts Scanned',
      message: 'Scan receipts to track prices and find the best deals',
      actionLabel: 'Scan Receipt',
      onActionPressed: onScanPressed,
      iconColor: Colors.orange,
    );
  }

  // No coaching tips
  static Widget noCoachingTips(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.school_outlined,
      title: 'No Tips Available',
      message: 'Check back soon for personalized financial coaching tips',
      iconColor: Colors.teal,
    );
  }

  // No nudges
  static Widget noNudges(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.notifications_outlined,
      title: 'All Caught Up!',
      message: 'No alerts right now. You\'re doing great with your finances!',
      iconColor: Colors.green,
    );
  }

  // No money stories
  static Widget noMoneyStories(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.auto_stories_outlined,
      title: 'No Stories Yet',
      message: 'Your daily money story will appear here at 9 PM each day',
      iconColor: Colors.indigo,
    );
  }

  // No partner (couples)
  static Widget noPartner(BuildContext context, VoidCallback onInvitePressed) {
    return EmptyStateWidget(
      icon: Icons.favorite_outline,
      title: 'No Partner Connected',
      message: 'Invite your partner to share budgets and track finances together',
      actionLabel: 'Invite Partner',
      onActionPressed: onInvitePressed,
      iconColor: Colors.pink,
    );
  }

  // Search no results
  static Widget searchNoResults(BuildContext context, String query) {
    return EmptyStateWidget(
      icon: Icons.search_off_outlined,
      title: 'No Results Found',
      message: 'We couldn\'t find anything matching "$query"',
      iconColor: Colors.grey,
    );
  }
}
