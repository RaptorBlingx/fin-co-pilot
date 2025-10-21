import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/agents/item_tracker_agent.dart';
import '../../../services/price_intelligence_agent.dart';
import '../../../services/auth_service.dart';
import '../../../shared/models/price_result.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/haptic_utils.dart';

/// Enhanced Price Intelligence Dashboard - Unified Smart Shopping Experience
/// Tab 1: Tracked Items (existing functionality)
/// Tab 2: Search Prices (merged from Shopping screen)
class PriceIntelligenceScreen extends ConsumerStatefulWidget {
  const PriceIntelligenceScreen({super.key});

  @override
  ConsumerState<PriceIntelligenceScreen> createState() => _PriceIntelligenceScreenState();
}

class _PriceIntelligenceScreenState extends ConsumerState<PriceIntelligenceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tab 1: Tracked Items
  final ItemTrackerAgent _itemTracker = ItemTrackerAgent();
  List<ItemPurchaseHistory> _trackedItems = [];
  bool _isLoading = true;
  double _totalSavings = 0.0;

  // Tab 2: Search Prices (merged from Shopping)
  final PriceIntelligenceAgent _priceAgent = PriceIntelligenceAgent();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<PriceResult> _searchResults = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrackedItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
        title: const Text('Smart Shopping'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTrackedItems,
              tooltip: 'Refresh',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.trending_down), text: 'Tracked Items'),
            Tab(icon: Icon(Icons.search), text: 'Search Prices'),
          ],
          onTap: (_) => setState(() {}), // Refresh to show/hide refresh button
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrackedItemsTab(),
          _buildSearchTab(),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: TRACKED ITEMS (Existing functionality)
  // ============================================================================

  Widget _buildTrackedItemsTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _trackedItems.isEmpty
            ? _buildEmptyState()
            : _buildDashboard();
  }

  // ============================================================================
  // TAB 2: SEARCH PRICES (Merged from Shopping screen)
  // ============================================================================

  Widget _buildSearchTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _buildSearchContent(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for any product...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        HapticUtils.light();
                        setState(() {
                          _searchController.clear();
                          _searchResults = [];
                          _errorMessage = null;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onSubmitted: (_) => _searchPrices(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _searchPrices,
              icon: _isSearching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.price_check),
              label: Text(_isSearching ? 'Searching...' : 'Find Best Prices'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_errorMessage != null) {
      return _buildSearchError();
    }

    if (_searchResults.isEmpty && !_isSearching) {
      return _buildSearchEmptyState();
    }

    if (_isSearching) {
      return _buildSearchLoadingState();
    }

    return _buildSearchResults();
  }

  Widget _buildSearchEmptyState() {
    return Column(
      children: [
        const Expanded(
          child: EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'Find the Best Prices',
            message: 'Search for any product to compare prices from multiple retailers in your region',
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Text(
                'Popular searches:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildSuggestionChip('iPhone 16 Pro'),
                  _buildSuggestionChip('MacBook Air'),
                  _buildSuggestionChip('AirPods Pro'),
                  _buildSuggestionChip('iPad'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        HapticUtils.light();
        setState(() {
          _searchController.text = text;
        });
        _searchPrices();
      },
      backgroundColor: Colors.blue.shade50,
      labelStyle: const TextStyle(color: Colors.blue),
    );
  }

  Widget _buildSearchLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ShimmerLoading(width: 100, height: 16, borderRadius: 4),
                    const Spacer(),
                    const ShimmerLoading(width: 60, height: 20, borderRadius: 10),
                  ],
                ),
                const SizedBox(height: 12),
                const ShimmerLoading(width: 120, height: 24, borderRadius: 4),
                const SizedBox(height: 8),
                const ShimmerLoading(width: 80, height: 14, borderRadius: 4),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: ShimmerLoading(width: double.infinity, height: 36, borderRadius: 8),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: ShimmerLoading(width: double.infinity, height: 36, borderRadius: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Search Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _searchPrices,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    // Find the cheapest price
    final cheapestPrice = _searchResults.first.price;

    return Column(
      children: [
        // Results header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Found Best Prices',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_searchResults.length} results • Best: ${_searchResults.first.formattedPrice}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              final isCheapest = result.price == cheapestPrice;
              return _buildPriceCard(result, isCheapest);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard(PriceResult result, bool isCheapest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCheapest ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCheapest ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: result.hasUrl ? () => _launchUrl(result.url!) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Merchant name and best price badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.merchant,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCheapest)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'BEST PRICE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),

              // Price
              Text(
                result.formattedPrice,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isCheapest ? Colors.green : Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Availability
              Row(
                children: [
                  Text(
                    result.availabilityIcon,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    result.availabilityDisplay,
                    style: TextStyle(
                      fontSize: 13,
                      color: result.isAvailable ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Notes
              if (result.notes != null && result.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  result.notes!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Action buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  if (result.hasUrl)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchUrl(result.url!),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _trackPrice(result),
                      icon: const Icon(Icons.notifications, size: 16),
                      label: const Text('Track'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
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

  Future<void> _searchPrices() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a product to search';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults = [];
    });

    try {
      // Get user location data (from user profile or device)
      final userCountry = 'United States'; // TODO: Get from user profile or device locale
      final userLanguage = 'English'; // TODO: Get from user profile or device locale
      final userCurrency = 'USD'; // TODO: Get from user profile

      // Check cache first
      final cachedResults = await _priceAgent.getCachedResults(
        productQuery: query,
        userCountry: userCountry,
      );

      if (cachedResults != null && cachedResults.isNotEmpty) {
        setState(() {
          _searchResults = cachedResults;
          _isSearching = false;
        });
        return;
      }

      // Search with AI
      final results = await _priceAgent.searchBestPrice(
        productQuery: query,
        userCountry: userCountry,
        userLanguage: userLanguage,
        userCurrency: userCurrency,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;

        if (results.isEmpty) {
          _errorMessage = 'No results found. Try a different search term.';
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Search failed: ${e.toString()}';
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Future<void> _trackPrice(PriceResult result) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _priceAgent.trackProduct(
        userId: user.uid,
        productQuery: result.productQuery,
        merchant: result.merchant,
        targetPrice: result.price,
        currency: result.currency,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tracking ${result.merchant} - ${result.productQuery}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to track: $e')),
        );
      }
    }
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

              // Price Trend Chart
              if (item.purchases.length > 1) ...[
                _buildSectionHeader('Price Trend'),
                const SizedBox(height: 12),
                _buildPriceChart(item.purchases, item.itemName),
                const SizedBox(height: 24),
              ],
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

  Widget _buildPriceChart(List<ItemPurchase> purchases, String itemName) {
    if (purchases.length < 2) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.slate100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Need at least 2 purchases to show price trend',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.slate600,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Sort purchases by date
    final sorted = purchases.toList()..sort((a, b) => a.date.compareTo(b.date));
    
    // Create spots for the line chart
    final spots = sorted.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.price);
    }).toList();

    // Calculate min and max for better chart scaling
    final prices = sorted.map((p) => p.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final chartMinY = (minPrice - priceRange * 0.1).clamp(0.0, double.infinity);
    final chartMaxY = maxPrice + priceRange * 0.1;

    // Determine trend color
    final trend = _calculateTrend(ItemPurchaseHistory(
      itemName: itemName,
      purchaseCount: purchases.length,
      averagePrice: prices.reduce((a, b) => a + b) / prices.length,
      lastPrice: prices.last,
      category: 'Other',
      purchases: purchases,
    ));

    final lineColor = trend == 'up' 
        ? Colors.red 
        : trend == 'down' 
            ? Colors.green 
            : AppTheme.primaryIndigo;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: lineColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.1),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.slate600,
                          fontSize: 10,
                        ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  
                  // Show date for first, last, and middle points
                  if (index == 0 || 
                      index == sorted.length - 1 || 
                      index == sorted.length ~/ 2) {
                    final date = sorted[index].date;
                    final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${month.substring(0, 3)}\n${date.day}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.slate600,
                              fontSize: 9,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: priceRange / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.slate200,
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppTheme.slate200),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= sorted.length) return null;
                  
                  final purchase = sorted[index];
                  return LineTooltipItem(
                    '\$${purchase.price.toStringAsFixed(2)}\n${_formatDate(purchase.date)}',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      if (purchase.merchant != null)
                        TextSpan(
                          text: '\n${purchase.merchant}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
