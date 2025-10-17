import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/agents/item_tracker_agent.dart';

/// Price Intelligence Dashboard - Shows user's item tracking and price trends
class PriceIntelligenceScreen extends ConsumerStatefulWidget {
  const PriceIntelligenceScreen({super.key});

  @override
  ConsumerState<PriceIntelligenceScreen> createState() => _PriceIntelligenceScreenState();
}

class _PriceIntelligenceScreenState extends ConsumerState<PriceIntelligenceScreen> {
  final ItemTrackerAgent _itemTracker = ItemTrackerAgent();
  List<ItemPurchaseHistory> _trackedItems = [];
  bool _isLoading = true;
  double _totalSavings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTrackedItems();
  }

  Future<void> _loadTrackedItems() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load tracked items from Firestore
      final items = await _itemTracker.getAllTrackedItems(userId: user.uid);

      // Calculate total potential savings (comparison between stores)
      double savings = 0.0;
      for (final item in items) {
        if (item.purchases.length > 1) {
          final prices = item.purchases.map((p) => p.price).toList();
          final minPrice = prices.reduce((a, b) => a < b ? a : b);
          final maxPrice = prices.reduce((a, b) => a > b ? a : b);
          savings += (maxPrice - minPrice) * item.purchaseCount;
        }
      }

      setState(() {
        _trackedItems = items;
        _totalSavings = savings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading tracked items: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Intelligence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrackedItems,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trackedItems.isEmpty
              ? _buildEmptyState()
              : _buildDashboard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start Tracking Items',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Upload receipts to track individual items, monitor price changes, and get purchase predictions!',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Upload Your First Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to add transaction
              },
            ),
            const SizedBox(height: 16),
            _buildFeaturesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      ('📊', 'Track prices over time'),
      ('💰', 'Find best deals'),
      ('🔮', 'Predict when you need items'),
      ('🏪', 'Compare stores'),
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(feature.$1, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                feature.$2,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.slate600,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadTrackedItems,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Text(
            'Your Tracked Items',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Items you\'ve purchased with receipt uploads',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.slate600,
                ),
          ),
          const SizedBox(height: 24),

          // Summary cards
          _buildSummaryCards(),

          const SizedBox(height: 24),

          // Item list
          ..._trackedItems.map((item) => _buildItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.shopping_bag,
            title: 'Items Tracked',
            value: '${_trackedItems.length}',
            color: AppTheme.primaryIndigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.savings,
            title: 'Potential Savings',
            value: '\$${_totalSavings.toStringAsFixed(2)}',
            color: AppTheme.accentEmerald,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemPurchaseHistory item) {
    // Calculate trend
    final trend = _calculateTrend(item);
    final nextPurchase = _itemTracker.predictNextPurchase(item);
    final daysUntil = nextPurchase?.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showItemDetail(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor(item.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getCategoryEmoji(item.category),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.purchaseCount} purchases • Avg \$${item.averagePrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (daysUntil != null && daysUntil <= 7)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          daysUntil <= 0
                              ? '🔔 Need soon!'
                              : '🔮 Need in $daysUntil days',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: daysUntil <= 2 ? Colors.orange : AppTheme.accentEmerald,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              // Trend
              if (trend != 'stable')
                Icon(
                  trend == 'up' ? Icons.trending_up : Icons.trending_down,
                  color: trend == 'up' ? Colors.red : Colors.green,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateTrend(ItemPurchaseHistory item) {
    if (item.purchases.length < 2) return 'stable';

    final sorted = item.purchases.toList()..sort((a, b) => a.date.compareTo(b.date));
    final oldestPrice = sorted.first.price;
    final latestPrice = sorted.last.price;
    final change = ((latestPrice - oldestPrice) / oldestPrice) * 100;

    if (change > 10) return 'up';
    if (change < -10) return 'down';
    return 'stable';
  }

  void _showItemDetail(ItemPurchaseHistory item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildItemDetailSheet(item),
    );
  }

  Widget _buildItemDetailSheet(ItemPurchaseHistory item) {
    final nextPurchase = _itemTracker.predictNextPurchase(item);
    final frequency = _itemTracker.calculatePurchaseFrequency(item.purchases);
    final trend = _calculateTrend(item);
    
    // Calculate price stats
    final prices = item.purchases.map((p) => p.price).toList();
    final minPrice = prices.isNotEmpty ? prices.reduce((a, b) => a < b ? a : b) : 0.0;
    final maxPrice = prices.isNotEmpty ? prices.reduce((a, b) => a > b ? a : b) : 0.0;
    final priceRange = maxPrice - minPrice;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category icon
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(item.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _getCategoryEmoji(item.category),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          item.category,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.slate600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatCard(
                      '${item.purchaseCount}',
                      'Purchases',
                      Icons.shopping_cart,
                      AppTheme.primaryIndigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniStatCard(
                      '\$${item.averagePrice.toStringAsFixed(2)}',
                      'Avg Price',
                      Icons.payments,
                      AppTheme.accentEmerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Price Stats
              _buildSectionHeader('Price Analysis'),
              const SizedBox(height: 12),
              _buildStatRow('Current Price', '\$${item.lastPrice.toStringAsFixed(2)}'),
              _buildStatRow('Average Price', '\$${item.averagePrice.toStringAsFixed(2)}'),
              _buildStatRow('Lowest Price', '\$${minPrice.toStringAsFixed(2)}'),
              _buildStatRow('Highest Price', '\$${maxPrice.toStringAsFixed(2)}'),
              _buildStatRow('Price Range', '\$${priceRange.toStringAsFixed(2)}'),
              _buildStatRowWithIcon(
                'Trend',
                trend == 'up' ? 'Increasing ↗' : trend == 'down' ? 'Decreasing ↘' : 'Stable →',
                trend == 'up' ? Icons.trending_up : trend == 'down' ? Icons.trending_down : Icons.trending_flat,
                trend == 'up' ? Colors.red : trend == 'down' ? Colors.green : AppTheme.slate600,
              ),

              const SizedBox(height: 24),

              // Purchase Predictions
              if (frequency != null) ...[
                _buildSectionHeader('Purchase Predictions'),
                const SizedBox(height: 12),
                _buildStatRow('Frequency', 'Every $frequency days'),
                if (nextPurchase != null)
                  _buildStatRow(
                    'Next Purchase',
                    _formatDate(nextPurchase),
                  ),
                if (nextPurchase != null)
                  _buildPredictionCard(nextPurchase),
                const SizedBox(height: 24),
              ],

              // Purchase History
              _buildSectionHeader('Purchase History'),
              const SizedBox(height: 12),
              _buildPurchaseHistory(item.purchases),

              const SizedBox(height: 24),

              // Store Comparison
              if (item.purchases.length > 1) ...[
                _buildSectionHeader('Store Comparison'),
                const SizedBox(height: 12),
                _buildStoreComparison(item.purchases),
                const SizedBox(height: 24),
              ],

              // Price Chart Placeholder (for fl_chart implementation)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryIndigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryIndigo.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.show_chart, color: AppTheme.primaryIndigo),
                        const SizedBox(width: 8),
                        Text(
                          'Price Trend Chart',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryIndigo,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coming soon: Visual price trends with fl_chart',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.slate600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.slate600,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonFeature(String emoji, String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            feature,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // Helper methods for item detail sheet
  Widget _buildMiniStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _buildStatRowWithIcon(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.slate600,
                ),
          ),
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(DateTime nextPurchase) {
    final daysUntil = nextPurchase.difference(DateTime.now()).inDays;
    final isUrgent = daysUntil <= 2;
    final isComingSoon = daysUntil > 2 && daysUntil <= 7;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isUrgent
            ? LinearGradient(
                colors: [Colors.orange.shade100, Colors.deepOrange.shade100],
              )
            : isComingSoon
                ? LinearGradient(
                    colors: [AppTheme.accentEmerald.withOpacity(0.2), AppTheme.accentEmerald.withOpacity(0.1)],
                  )
                : null,
        color: isUrgent || isComingSoon ? null : AppTheme.slate100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.orange : isComingSoon ? AppTheme.accentEmerald : AppTheme.slate300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.notifications_active : Icons.calendar_today,
            color: isUrgent ? Colors.orange : isComingSoon ? AppTheme.accentEmerald : AppTheme.slate600,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrgent
                      ? '🔔 You might need this soon!'
                      : isComingSoon
                          ? '🔮 Coming up soon'
                          : 'Next purchase predicted',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUrgent ? Colors.deepOrange : isComingSoon ? AppTheme.accentEmerald : AppTheme.slate800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  daysUntil <= 0
                      ? 'You typically buy this today or tomorrow'
                      : daysUntil == 1
                          ? 'You typically buy this tomorrow'
                          : 'You typically buy this in $daysUntil days',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseHistory(List<ItemPurchase> purchases) {
    final sorted = purchases.toList()..sort((a, b) => b.date.compareTo(a.date)); // Most recent first

    return Column(
      children: sorted.map((purchase) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.slate50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryIndigo,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(purchase.date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (purchase.merchant != null)
                      Text(
                        purchase.merchant!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.slate600,
                            ),
                      ),
                  ],
                ),
              ),
              Text(
                '\$${purchase.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SF Mono',
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStoreComparison(List<ItemPurchase> purchases) {
    // Group by merchant and calculate average
    final Map<String, List<double>> merchantPrices = {};
    for (final purchase in purchases) {
      if (purchase.merchant != null) {
        merchantPrices.putIfAbsent(purchase.merchant!, () => []);
        merchantPrices[purchase.merchant!]!.add(purchase.price);
      }
    }

    // Calculate average for each merchant
    final merchantAvgs = merchantPrices.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return MapEntry(entry.key, avg);
    }).toList()
      ..sort((a, b) => a.value.compareTo(b.value)); // Sort by price (cheapest first)

    if (merchantAvgs.isEmpty) {
      return Text(
        'No merchant data available',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.slate600,
            ),
      );
    }

    return Column(
      children: merchantAvgs.asMap().entries.map((entry) {
        final index = entry.key;
        final merchant = entry.value.key;
        final avgPrice = entry.value.value;
        final isBest = index == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isBest ? AppTheme.accentEmerald.withOpacity(0.1) : AppTheme.slate50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isBest ? AppTheme.accentEmerald : AppTheme.slate200,
              width: isBest ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (isBest)
                const Icon(
                  Icons.star,
                  color: AppTheme.accentEmerald,
                  size: 20,
                ),
              if (isBest) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isBest ? FontWeight.w700 : FontWeight.w600,
                            color: isBest ? AppTheme.accentEmerald : null,
                          ),
                    ),
                    if (isBest)
                      Text(
                        'Best price!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accentEmerald,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
              ),
              Text(
                '\$${avgPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isBest ? AppTheme.accentEmerald : null,
                      fontFamily: 'SF Mono',
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'dairy':
        return '🥛';
      case 'produce':
      case 'fruits & vegetables':
        return '🥬';
      case 'meat':
      case 'meat & seafood':
        return '🥩';
      case 'bakery':
        return '🍞';
      case 'beverages':
        return '🥤';
      case 'snacks':
        return '🍿';
      case 'frozen':
        return '🧊';
      case 'pantry':
      case 'canned goods':
        return '🥫';
      case 'household':
        return '🧹';
      case 'personal care':
        return '🧴';
      default:
        return '🛒';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'dairy':
        return Colors.blue;
      case 'produce':
      case 'fruits & vegetables':
        return Colors.green;
      case 'meat':
      case 'meat & seafood':
        return Colors.red;
      case 'bakery':
        return Colors.orange;
      case 'beverages':
        return Colors.purple;
      case 'snacks':
        return Colors.amber;
      case 'frozen':
        return Colors.lightBlue;
      case 'pantry':
      case 'canned goods':
        return Colors.brown;
      case 'household':
        return Colors.teal;
      case 'personal care':
        return Colors.pink;
      default:
        return AppTheme.primaryIndigo;
    }
  }
}
