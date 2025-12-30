import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/price_intelligence_service.dart';
import '../../../models/watchlist_item.dart';

/// Price Watchlist Screen (Week 10 Feature)
///
/// Shows all products user is tracking for price comparison:
/// - Product name and last price paid
/// - Price history and trends
/// - Market average comparison
/// - Savings opportunities
/// - Price drop alerts
///
/// Features:
/// - Track products across purchases
/// - See price trends (increasing/decreasing/stable)
/// - Get alerts on good deals
/// - Delete unwanted items
class PriceWatchlistScreen extends StatelessWidget {
  const PriceWatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view watchlist')),
      );
    }

    final theme = Theme.of(context);
    final priceService = PriceIntelligenceService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'How it works',
          ),
        ],
      ),
      body: StreamBuilder<List<WatchlistItem>>(
        stream: priceService.getWatchlistStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading watchlist: ${snapshot.error}'),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return _buildEmptyState(context, theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildWatchlistCard(context, theme, item, priceService);
            },
          );
        },
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.remove_red_eye_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No Items in Watchlist',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan receipts to automatically track product prices and find savings opportunities!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('Scan Receipt'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build watchlist item card
  Widget _buildWatchlistCard(
    BuildContext context,
    ThemeData theme,
    WatchlistItem item,
    PriceIntelligenceService priceService,
  ) {
    final trendColor = item.priceTrend == 'increasing'
        ? Colors.red
        : item.priceTrend == 'decreasing'
            ? Colors.green
            : Colors.grey;

    final trendIcon = item.priceTrend == 'increasing'
        ? Icons.trending_up
        : item.priceTrend == 'decreasing'
            ? Icons.trending_down
            : Icons.trending_flat;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Product name + Delete button
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, item, priceService),
                  color: theme.colorScheme.error,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Last purchase info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Purchase',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${item.lastPurchase.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.lastPurchase.merchant,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  // Price trend
                  Column(
                    children: [
                      Icon(trendIcon, color: trendColor, size: 32),
                      Text(
                        item.priceTrend.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: trendColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Market comparison (if available)
            if (item.marketAverage != null) ...[
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 12),
              _buildMarketComparison(theme, item),
            ],

            // Price history
            if (item.priceHistory.length > 1) ...[
              const SizedBox(height: 12),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 12),
              _buildPriceHistory(theme, item),
            ],

            // Recommendations
            if (item.savingsRecommendation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.wasGoodDeal
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.wasGoodDeal
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.wasGoodDeal ? Icons.check_circle : Icons.lightbulb,
                      color: item.wasGoodDeal ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.savingsRecommendation!,
                        style: theme.textTheme.bodySmall,
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

  /// Build market comparison section
  Widget _buildMarketComparison(ThemeData theme, WatchlistItem item) {
    final diff = item.lastPurchase.amount - item.marketAverage!;
    final isGoodDeal = diff <= 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Average',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${item.marketAverage!.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isGoodDeal
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isGoodDeal
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGoodDeal ? Icons.arrow_downward : Icons.arrow_upward,
                size: 16,
                color: isGoodDeal ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                '\$${diff.abs().toStringAsFixed(2)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isGoodDeal ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build price history section
  Widget _buildPriceHistory(ThemeData theme, WatchlistItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price History',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...item.priceHistory.take(5).map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${entry.date.month}/${entry.date.day}/${entry.date.year}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  entry.merchant,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '\$${entry.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
        if (item.priceHistory.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ ${item.priceHistory.length - 5} more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  /// Confirm delete dialog
  void _confirmDelete(
    BuildContext context,
    WatchlistItem item,
    PriceIntelligenceService priceService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Watchlist?'),
        content: Text('Stop tracking "${item.productName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await priceService.deleteWatchlistItem(item.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item removed from watchlist')),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  /// Show info dialog
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How Price Tracking Works'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📸 Scan Receipts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'When you scan a receipt, we automatically add items to your watchlist.',
              ),
              SizedBox(height: 16),
              Text(
                '📊 Track Prices',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'We track prices across all your purchases to show trends and patterns.',
              ),
              SizedBox(height: 16),
              Text(
                '💰 Find Savings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Compare your prices to market averages and discover where you can save money.',
              ),
              SizedBox(height: 16),
              Text(
                '🔔 Get Alerts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Receive notifications when prices drop significantly on items you track.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
