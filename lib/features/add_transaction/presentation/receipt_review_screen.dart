import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/agents/receipt_agent.dart';

/// Screen to review and edit items extracted from receipt
class ReceiptReviewScreen extends ConsumerStatefulWidget {
  final ReceiptExtractionResult receiptData;

  const ReceiptReviewScreen({
    super.key,
    required this.receiptData,
  });

  @override
  ConsumerState<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  late List<ReceiptItem> _items;
  late TextEditingController _merchantController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.receiptData.items);
    _merchantController = TextEditingController(
      text: widget.receiptData.merchant ?? '',
    );
  }

  @override
  void dispose() {
    _merchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Review Receipt'),
        actions: [
          if (_items.isNotEmpty)
            TextButton.icon(
              icon: Icon(
                _isEditing ? Icons.check : Icons.edit,
                color: AppTheme.primaryIndigo,
              ),
              label: Text(
                _isEditing ? 'Done' : 'Edit',
                style: const TextStyle(color: AppTheme.primaryIndigo),
              ),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
            ),
        ],
      ),
      body: widget.receiptData.success
          ? _buildSuccessView()
          : _buildErrorView(),
      bottomNavigationBar: widget.receiptData.success
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        // Receipt info card
        _buildReceiptInfoCard(),

        // Items list
        Expanded(
          child: _items.isEmpty
              ? _buildEmptyItems()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return _buildItemCard(index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReceiptInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentEmerald.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppTheme.accentEmerald,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isEditing
                        ? TextField(
                            controller: _merchantController,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              border: OutlineInputBorder(),
                            ),
                          )
                        : Text(
                            widget.receiptData.merchant ?? 'Unknown Store',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                    if (widget.receiptData.date != null)
                      Text(
                        _formatDate(widget.receiptData.date!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${_items.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              if (widget.receiptData.subtotal != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '\$${widget.receiptData.subtotal!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              if (widget.receiptData.tax != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Tax',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '\$${widget.receiptData.tax!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '\$${widget.receiptData.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryIndigo,
                          fontFamily: 'SF Mono',
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(item.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getCategoryEmoji(item.category),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (item.category != null)
                    Text(
                      item.category!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getCategoryColor(item.category),
                          ),
                    ),
                  if (item.quantity > 1)
                    Text(
                      'Qty: ${item.quantity}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'SF Mono',
                      ),
                ),
                if (item.quantity > 1)
                  Text(
                    '@\$${item.unitPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            // Edit/Delete buttons
            if (_isEditing) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _deleteItem(index),
                color: Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItems() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try taking a clearer photo',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to process receipt',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.receiptData.errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _items.isEmpty ? null : _confirmAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryIndigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _confirmAndSave() {
    // Update merchant from text field
    final updatedReceiptData = ReceiptExtractionResult(
      success: true,
      merchant: _merchantController.text.trim(),
      date: widget.receiptData.date,
      location: widget.receiptData.location,
      items: _items,
      subtotal: _calculateSubtotal(),
      tax: widget.receiptData.tax,
      total: _calculateTotal(),
      paymentMethod: widget.receiptData.paymentMethod,
      confidence: widget.receiptData.confidence,
    );

    // Return the confirmed receipt data
    Navigator.pop(context, updatedReceiptData);
  }

  double _calculateSubtotal() {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double _calculateTotal() {
    final subtotal = _calculateSubtotal();
    final tax = widget.receiptData.tax ?? 0.0;
    return subtotal + tax;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getCategoryEmoji(String? category) {
    switch (category?.toLowerCase()) {
      case 'dairy':
        return '🥛';
      case 'produce':
        return '🥬';
      case 'meat':
        return '🥩';
      case 'bakery':
        return '🍞';
      case 'frozen':
        return '🧊';
      case 'snacks':
        return '🍿';
      case 'beverages':
        return '🥤';
      case 'household':
        return '🧼';
      case 'health':
        return '💊';
      default:
        return '🛒';
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'dairy':
        return Colors.blue;
      case 'produce':
        return Colors.green;
      case 'meat':
        return Colors.red;
      case 'bakery':
        return Colors.orange;
      case 'frozen':
        return Colors.cyan;
      case 'snacks':
        return Colors.purple;
      case 'beverages':
        return Colors.teal;
      case 'household':
        return Colors.brown;
      case 'health':
        return Colors.pink;
      default:
        return AppTheme.slate500;
    }
  }
}
