import 'package:flutter/material.dart';
import '../../../models/subscription.dart';
import '../../../services/subscription_detection_service.dart';
import '../../../services/auth_service.dart';
import '../screens/subscriptions_screen.dart';

/// Subscription Summary Card for Dashboard
///
/// Week 8: Subscription Detection (Killer Feature #7)
/// Shows total monthly subscription cost and top subscriptions
class SubscriptionSummaryCard extends StatefulWidget {
  const SubscriptionSummaryCard({super.key});

  @override
  State<SubscriptionSummaryCard> createState() => _SubscriptionSummaryCardState();
}

class _SubscriptionSummaryCardState extends State<SubscriptionSummaryCard> {
  final _subscriptionService = SubscriptionDetectionService();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<Subscription>>(
      stream: _subscriptionService.getSubscriptionsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(theme);
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyCard(theme, user.uid);
        }

        final subscriptions = snapshot.data!;
        final activeSubscriptions =
            subscriptions.where((s) => s.status == SubscriptionStatus.active).toList();

        if (activeSubscriptions.isEmpty) {
          return _buildEmptyCard(theme, user.uid);
        }

        return _buildSummaryCard(theme, activeSubscriptions);
      },
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.subscriptions,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Subscriptions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(ThemeData theme, String userId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _detectSubscriptions(userId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.subscriptions,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Subscriptions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap to detect recurring charges',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, List<Subscription> subscriptions) {
    final monthlyTotal = _subscriptionService.calculateMonthlyTotal(subscriptions);
    final annualTotal = _subscriptionService.calculateAnnualTotal(subscriptions);
    final topSubscriptions = subscriptions.take(3).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.subscriptions,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Subscriptions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Monthly Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Total',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${monthlyTotal.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${subscriptions.length} active',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${annualTotal.toStringAsFixed(0)}/year',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Top Subscriptions
              ...topSubscriptions.map((sub) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSubscriptionItem(theme, sub),
              )),
              if (subscriptions.length > 3) ...[
                const SizedBox(height: 4),
                Text(
                  '+${subscriptions.length - 3} more',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionItem(ThemeData theme, Subscription subscription) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getSubscriptionColor(subscription.merchant),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            subscription.merchant,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          '\$${subscription.amount.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '/${_getFrequencyShort(subscription.frequency)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Color _getSubscriptionColor(String merchant) {
    final lowerMerchant = merchant.toLowerCase();

    if (lowerMerchant.contains('netflix')) return Colors.red;
    if (lowerMerchant.contains('spotify')) return Colors.green;
    if (lowerMerchant.contains('disney')) return Colors.blue;
    if (lowerMerchant.contains('hulu')) return Colors.teal;
    if (lowerMerchant.contains('amazon')) return Colors.orange;
    if (lowerMerchant.contains('gym')) return Colors.purple;

    return Colors.indigo;
  }

  String _getFrequencyShort(SubscriptionFrequency frequency) {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return 'wk';
      case SubscriptionFrequency.monthly:
        return 'mo';
      case SubscriptionFrequency.yearly:
        return 'yr';
    }
  }

  Future<void> _detectSubscriptions(String userId) async {
    try {
      await _subscriptionService.detectSubscriptions(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscriptions detected!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
