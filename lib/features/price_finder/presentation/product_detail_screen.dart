import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/product_price_data.dart';
import '../../../services/enhanced_price_service.dart';
import '../../../services/auth_service.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../services/preferences_service.dart';

/// Premium Product Detail Screen
/// - Multi-retailer price comparison
/// - Interactive price history chart
/// - Deal detection
/// - Coupon finder
/// - Add to wishlist
/// - Share deal
class ProductDetailScreen extends StatefulWidget {
  final ProductPriceData product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final EnhancedPriceService _priceService = EnhancedPriceService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PriceHistoryPoint> _priceHistory = [];
  PricePrediction? _pricePrediction;
  DealDetection? _dealDetection;
  List<Coupon> _coupons = [];
  bool _isLoading = true;
  bool _isInWatchlist = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _priceService.getPriceHistory(productId: widget.product.id),
        _priceService.predictPriceDrop(widget.product.id),
        _priceService.detectDeal(widget.product),
        _priceService.findCoupons(widget.product.id),
        _checkWatchlistStatus(),
      ]);

      setState(() {
        _priceHistory = results[0] as List<PriceHistoryPoint>;
        _pricePrediction = results[1] as PricePrediction;
        _dealDetection = results[2] as DealDetection;
        _coupons = results[3] as List<Coupon>;
        _isInWatchlist = results[4] as bool;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkWatchlistStatus() async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore
          .collection('watchlist')
          .where('user_id', isEqualTo: user.uid)
          .where('productId', isEqualTo: widget.product.id)
          .limit(1)
          .get();

      return doc.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _toggleWatchlist() async {
    final user = _authService.currentUser;
    if (user == null) return;

    HapticUtils.medium();

    try {
      if (_isInWatchlist) {
        // Remove from watchlist
        final doc = await _firestore
            .collection('watchlist')
            .where('user_id', isEqualTo: user.uid)
            .where('productId', isEqualTo: widget.product.id)
            .limit(1)
            .get();

        if (doc.docs.isNotEmpty) {
          await _firestore.collection('watchlist').doc(doc.docs.first.id).delete();
        }

        setState(() => _isInWatchlist = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from watchlist')),
          );
        }
      } else {
        // Add to watchlist
        await _firestore.collection('watchlist').add({
          'userId': user.uid,
          'productId': widget.product.id,
          'productName': widget.product.name,
          'imageUrl': widget.product.imageUrl,
          'targetPrice': widget.product.cheapestPrice,
          'currentPrice': widget.product.cheapestPrice,
          'alertEnabled': true,
          'addedAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isInWatchlist = true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to watchlist! We\'ll notify you of price drops'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = PreferencesService.getCurrency() ?? 'USD';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: Icon(_isInWatchlist ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleWatchlist,
            tooltip: _isInWatchlist ? 'Remove from watchlist' : 'Add to watchlist',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProductHeader(),
                const SizedBox(height: 24),
                if (_dealDetection != null) _buildDealBanner(),
                const SizedBox(height: 16),
                _buildPriceSummary(currency),
                const SizedBox(height: 24),
                if (_priceHistory.isNotEmpty) ...[
                  _buildPriceHistoryChart(),
                  const SizedBox(height: 24),
                ],
                if (_pricePrediction != null && _pricePrediction!.willDrop) ...[
                  _buildPricePrediction(),
                  const SizedBox(height: 24),
                ],
                if (_coupons.isNotEmpty) ...[
                  _buildCoupons(),
                  const SizedBox(height: 24),
                ],
                _buildRetailerComparison(currency),
              ],
            ),
    );
  }

  Widget _buildProductHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.product.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: widget.product.imageUrl!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.product.brand != null)
                Text(
                  widget.product.brand!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                widget.product.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.product.category != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.product.category!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDealBanner() {
    if (_dealDetection == null) return const SizedBox.shrink();

    final isGoodDeal = _dealDetection!.isRealDeal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGoodDeal
              ? [Colors.green[100]!, Colors.green[50]!]
              : [Colors.orange[100]!, Colors.orange[50]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGoodDeal ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGoodDeal ? Icons.local_fire_department : Icons.info_outline,
            color: isGoodDeal ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGoodDeal ? 'Great Deal!' : 'Price Check',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isGoodDeal ? Colors.green[900] : Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dealDetection!.verdict,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(String currency) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Best Price',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (widget.product.savingsPercentage > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Save ${widget.product.savingsPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyUtils.formatAmount(widget.product.cheapestPrice, currency),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'at ${widget.product.cheapestRetailer?.name ?? "Unknown"}',
              style: const TextStyle(fontSize: 14),
            ),
            if (widget.product.maxSavings > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Save up to ${CurrencyUtils.formatAmount(widget.product.maxSavings, currency)} vs highest price',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
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

  Widget _buildPriceHistoryChart() {
    if (_priceHistory.length < 2) return const SizedBox.shrink();

    final sorted = _priceHistory.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = sorted.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.price);
    }).toList();

    final prices = sorted.map((h) => h.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minPrice - priceRange * 0.1,
                  maxY: maxPrice + priceRange * 0.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
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
                            '\$${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10),
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
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricePrediction() {
    if (_pricePrediction == null) return const SizedBox.shrink();

    return Card(
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.auto_graph, color: Colors.purple, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price Prediction',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _pricePrediction!.reason,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (_pricePrediction!.estimatedDays != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Estimated in ${_pricePrediction!.estimatedDays} days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoupons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_offer, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Available Coupons',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._coupons.map((coupon) => _buildCouponCard(coupon)),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.code,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(coupon.description),
                if (coupon.restrictions != null)
                  Text(
                    coupon.restrictions!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              // TODO: Copy to clipboard
              HapticUtils.success();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRetailerComparison(String currency) {
    final sortedRetailers = widget.product.retailers.toList()
      ..sort((a, b) => a.price.compareTo(b.price));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compare Retailers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...sortedRetailers.map((retailer) => _buildRetailerCard(retailer, currency)),
          ],
        ),
      ),
    );
  }

  Widget _buildRetailerCard(RetailerPrice retailer, String currency) {
    final isCheapest = retailer.price == widget.product.cheapestPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCheapest ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCheapest ? Colors.green : Colors.grey[300]!,
          width: isCheapest ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          retailer.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCheapest ? Colors.green[900] : null,
                          ),
                        ),
                        if (isCheapest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BEST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          retailer.isInStock ? Icons.check_circle : Icons.error,
                          size: 16,
                          color: retailer.isInStock ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          retailer.availability,
                          style: TextStyle(
                            fontSize: 12,
                            color: retailer.isInStock ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyUtils.formatAmount(retailer.price, currency),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isCheapest ? Colors.green[900] : null,
                ),
              ),
            ],
          ),
          if (retailer.shipping != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  retailer.shipping!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (retailer.url != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticUtils.light();
                  _launchUrl(retailer.url!);
                },
                icon: const Icon(Icons.shopping_cart, size: 18),
                label: const Text('View at Store'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCheapest ? Colors.green : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
