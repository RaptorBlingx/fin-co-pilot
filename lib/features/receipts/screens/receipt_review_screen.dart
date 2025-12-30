import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/receipt_ocr_service.dart';
import '../../../services/price_intelligence_service.dart';
import '../../../models/transaction.dart' as models;

/// Receipt Review Screen (Week 10 Feature)
///
/// Displays extracted receipt data for user confirmation:
/// - Merchant, date, total
/// - Itemized list with prices
/// - Edit capabilities for corrections
/// - Price comparison (if available)
/// - Save to transactions + watchlist
///
/// Target: 95%+ extraction accuracy with user review
class ReceiptReviewScreen extends StatefulWidget {
  final ReceiptData receiptData;

  const ReceiptReviewScreen({
    super.key,
    required this.receiptData,
  });

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  final AuthService _authService = AuthService();
  // COMMENTED OUT: Tier 2 V2.0 feature - Price Intelligence
  // final PriceIntelligenceService _priceService = PriceIntelligenceService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _merchantController;
  late TextEditingController _totalController;
  late List<ReceiptItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.receiptData.merchant);
    _totalController = TextEditingController(text: widget.receiptData.total.toStringAsFixed(2));
    _items = List.from(widget.receiptData.items);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveReceipt,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Receipt image preview
            _buildImagePreview(theme),

            const SizedBox(height: 24),

            // Confidence indicator
            _buildConfidenceIndicator(theme),

            const SizedBox(height: 24),

            // Merchant info
            _buildMerchantInfo(theme),

            const SizedBox(height: 24),

            // Items list
            _buildItemsList(theme),

            const SizedBox(height: 24),

            // Totals
            _buildTotals(theme),

            const SizedBox(height: 24),

            // Save button
            _buildSaveButton(theme),
          ],
        ),
      ),
    );
  }

  /// Build receipt image preview
  Widget _buildImagePreview(ThemeData theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.receiptData.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.image_not_supported,
                size: 48,
                color: theme.colorScheme.outline,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build confidence indicator
  Widget _buildConfidenceIndicator(ThemeData theme) {
    final confidence = widget.receiptData.confidence;
    final color = confidence > 0.8
        ? Colors.green
        : confidence > 0.6
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'Review and edit as needed',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build merchant info section
  Widget _buildMerchantInfo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Merchant Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant Name',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      hintText: widget.receiptData.date,
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                if (widget.receiptData.time != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Time',
                        hintText: widget.receiptData.time,
                        prefixIcon: const Icon(Icons.access_time),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build items list
  Widget _buildItemsList(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items (${_items.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildItemTile(theme, item, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual item tile
  Widget _buildItemTile(ThemeData theme, ReceiptItem item, int index) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.description,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '\$${item.totalPrice.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _removeItem(index),
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  /// Build totals section
  Widget _buildTotals(ThemeData theme) {
    final subtotal = _items.fold<double>(0, (sum, item) => sum + item.totalPrice);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Subtotal', subtotal, theme),
            const SizedBox(height: 8),
            _buildTotalRow('Tax', widget.receiptData.tax, theme),
            if (widget.receiptData.tip > 0) ...[
              const SizedBox(height: 8),
              _buildTotalRow('Tip', widget.receiptData.tip, theme),
            ],
            const Divider(height: 24),
            _buildTotalRow(
              'Total',
              widget.receiptData.total,
              theme,
              isBold: true,
              isLarge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount,
    ThemeData theme, {
    bool isBold = false,
    bool isLarge = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isLarge ? 20 : null,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isLarge ? 20 : null,
          ),
        ),
      ],
    );
  }

  /// Build save button
  Widget _buildSaveButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: _isSaving ? null : _saveReceipt,
      icon: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.save),
      label: Text(_isSaving ? 'Saving...' : 'Save Receipt'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Add new item
  void _addItem() {
    setState(() {
      _items.add(ReceiptItem(
        description: 'New Item',
        quantity: 1,
        unitPrice: 0.00,
        totalPrice: 0.00,
      ));
    });
  }

  /// Remove item
  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  /// Save receipt to transactions and watchlist
  Future<void> _saveReceipt() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Create transaction
      final transaction = models.Transaction(
        id: '',
        userId: user.uid,
        amount: widget.receiptData.total,
        currency: 'USD',
        category: 'Groceries', // Default category
        type: models.TransactionType.expense,
        merchant: _merchantController.text,
        description: 'Receipt: ${_merchantController.text}',
        date: DateTime.parse(widget.receiptData.date),
        metadata: models.TransactionMetadata(
          source: 'receipt',
          confidence: widget.receiptData.confidence,
          verified: true,
          edited: false,
          aiAgent: 'gemini-2.5-flash',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final docRef = await _firestore.collection('transactions').add({
        'user_id': transaction.userId,
        'amount': transaction.amount,
        'currency': transaction.currency,
        'category': transaction.category,
        'type': transaction.type.name,
        'merchant': transaction.merchant,
        'description': transaction.description,
        'date': Timestamp.fromDate(transaction.date),
        'metadata': transaction.metadata.toMap(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'receipt': {
          'imageUrl': widget.receiptData.imageUrl,
          'parsedData': widget.receiptData.toMap(),
        },
      });

      // COMMENTED OUT: Tier 2 V2.0 feature - Price Intelligence watchlist
      // Add items to watchlist for price tracking
      // await _priceService.addReceiptItemsToWatchlist(
      //   userId: user.uid,
      //   items: _items,
      //   merchant: _merchantController.text,
      //   transactionId: docRef.id,
      //   date: DateTime.parse(widget.receiptData.date),
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving receipt: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
