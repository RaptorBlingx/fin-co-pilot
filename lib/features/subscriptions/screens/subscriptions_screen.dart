import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/subscription.dart';
import '../../../services/subscription_detection_service.dart';
import '../../../services/auth_service.dart';

/// Subscriptions Screen
///
/// Week 8: Subscription Detection (Killer Feature #7)
/// View and manage all detected subscriptions
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _subscriptionService = SubscriptionDetectionService();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subscriptions')),
        body: const Center(child: Text('Please log in to view subscriptions')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Subscriptions'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _detectSubscriptions(user.uid),
            tooltip: 'Detect Subscriptions',
          ),
        ],
      ),
      body: StreamBuilder<List<Subscription>>(
        stream: _subscriptionService.getSubscriptionsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(theme, user.uid);
          }

          final subscriptions = snapshot.data!;
          final activeSubscriptions =
              subscriptions.where((s) => s.status == SubscriptionStatus.active).toList();

          return Column(
            children: [
              // Total Cost Banner
              _buildTotalCostBanner(theme, activeSubscriptions),
              // Subscriptions List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSubscriptionCard(theme, subscriptions[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalCostBanner(ThemeData theme, List<Subscription> subscriptions) {
    final monthlyTotal = _subscriptionService.calculateMonthlyTotal(subscriptions);
    final annualTotal = _subscriptionService.calculateAnnualTotal(subscriptions);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Monthly Total',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${monthlyTotal.toStringAsFixed(2)}',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${annualTotal.toStringAsFixed(2)}/year • ${subscriptions.length} active',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(ThemeData theme, Subscription subscription) {
    final isActive = subscription.status == SubscriptionStatus.active;
    final isCanceled = subscription.status == SubscriptionStatus.canceled;
    final daysUntilNext = subscription.nextExpectedCharge.difference(DateTime.now()).inDays;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCanceled
            ? BorderSide(color: theme.colorScheme.outlineVariant)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getSubscriptionColor(subscription.merchant).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSubscriptionIcon(subscription.merchant),
                    color: _getSubscriptionColor(subscription.merchant),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subscription.merchant,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isCanceled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CANCELED',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subscription.metadata.category ?? 'Subscription',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Amount and Frequency
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    theme,
                    'Amount',
                    '\$${subscription.amount.toStringAsFixed(2)}',
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    theme,
                    'Frequency',
                    _getFrequencyLabel(subscription.frequency),
                    Icons.repeat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Next Charge
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    theme,
                    'Next Charge',
                    daysUntilNext > 0
                        ? 'in $daysUntilNext days'
                        : daysUntilNext == 0
                            ? 'Today'
                            : 'Overdue',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    theme,
                    'Annual Cost',
                    '\$${subscription.annualCost.toStringAsFixed(2)}',
                    Icons.calendar_month,
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (subscription.metadata.cancelUrl != null)
                    TextButton.icon(
                      onPressed: () => _openCancelUrl(subscription.metadata.cancelUrl!),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          subscription.status == SubscriptionStatus.flagged
                              ? Icons.flag
                              : Icons.flag_outlined,
                        ),
                        onPressed: () => _flagSubscription(subscription.id),
                        tooltip: 'Flag for review',
                        color: subscription.status == SubscriptionStatus.flagged
                            ? Colors.orange
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                          subscription.userConfirmed
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                        ),
                        onPressed: () => _confirmSubscription(subscription.id),
                        tooltip: 'Confirm subscription',
                        color: subscription.userConfirmed ? Colors.green : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        onPressed: () => _showCancelDialog(subscription),
                        tooltip: 'Mark as canceled',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ],
            if (subscription.metadata.savings != null && subscription.metadata.savings! > 100) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You could save \$${subscription.metadata.savings!.toStringAsFixed(2)}/year by canceling',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade800,
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
    );
  }

  Widget _buildInfoItem(ThemeData theme, String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, String userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.subscriptions_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Subscriptions Detected',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We analyze your transactions to detect recurring charges',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _detectSubscriptions(userId),
              icon: const Icon(Icons.search),
              label: const Text('Detect Subscriptions'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSubscriptionIcon(String merchant) {
    final lowerMerchant = merchant.toLowerCase();

    if (lowerMerchant.contains('netflix') ||
        lowerMerchant.contains('hulu') ||
        lowerMerchant.contains('disney')) {
      return Icons.movie;
    }
    if (lowerMerchant.contains('spotify') || lowerMerchant.contains('music')) {
      return Icons.music_note;
    }
    if (lowerMerchant.contains('gym') || lowerMerchant.contains('fitness')) {
      return Icons.fitness_center;
    }
    if (lowerMerchant.contains('cloud') || lowerMerchant.contains('storage')) {
      return Icons.cloud;
    }
    if (lowerMerchant.contains('amazon') || lowerMerchant.contains('prime')) {
      return Icons.shopping_bag;
    }

    return Icons.subscriptions;
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

  String _getFrequencyLabel(SubscriptionFrequency frequency) {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return 'Weekly';
      case SubscriptionFrequency.monthly:
        return 'Monthly';
      case SubscriptionFrequency.yearly:
        return 'Yearly';
    }
  }

  Future<void> _openCancelUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open cancel page')),
        );
      }
    }
  }

  Future<void> _confirmSubscription(String subscriptionId) async {
    await _subscriptionService.confirmSubscription(subscriptionId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription confirmed')),
      );
    }
  }

  Future<void> _flagSubscription(String subscriptionId) async {
    await _subscriptionService.flagSubscription(subscriptionId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription flagged for review')),
      );
    }
  }

  Future<void> _showCancelDialog(Subscription subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Canceled?'),
        content: Text(
          'Mark ${subscription.merchant} as canceled? This won\'t actually cancel the subscription - you\'ll need to do that through the service provider.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Mark Canceled'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _subscriptionService.cancelSubscription(subscription.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription marked as canceled')),
        );
      }
    }
  }

  Future<void> _detectSubscriptions(String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final subscriptions = await _subscriptionService.detectSubscriptions(userId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found ${subscriptions.length} subscriptions')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
