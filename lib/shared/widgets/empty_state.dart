import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Specific empty states
class NoTransactionsEmpty extends StatelessWidget {
  final VoidCallback? onAdd;

  const NoTransactionsEmpty({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No Transactions Yet',
      message: 'Start tracking your expenses by adding your first transaction',
      actionLabel: 'Add Transaction',
      onAction: onAdd,
    );
  }
}

class NoInsightsEmpty extends StatelessWidget {
  const NoInsightsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.analytics_outlined,
      title: 'No Data to Analyze',
      message: 'Add some transactions to see insights and spending patterns',
    );
  }
}

class NoCoachingTipsEmpty extends StatelessWidget {
  final VoidCallback? onGenerate;

  const NoCoachingTipsEmpty({super.key, this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.psychology_outlined,
      title: 'No Coaching Tips Yet',
      message: 'Generate personalized financial coaching based on your spending habits',
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
      icon: Icons.search_off,
      title: 'No Results Found',
      message: 'We couldn\'t find any results for "$query"',
    );
  }
}