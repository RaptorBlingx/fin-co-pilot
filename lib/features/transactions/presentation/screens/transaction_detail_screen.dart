import 'package:flutter/material.dart';
import '../../../../shared/models/transaction.dart' as model;
import '../../../../core/utils/currency_utils.dart';
import '../../../../services/transaction_service.dart';
import '../../../../core/constants/categories.dart';
import 'package:intl/intl.dart';
import 'transaction_edit_screen.dart';

/// Transaction Detail Screen
/// 
/// PHASE 1 FIX #3 & #4: Wire up edit functionality and improve UI
class TransactionDetailScreen extends StatefulWidget {
  final model.Transaction transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late model.Transaction _currentTransaction;

  @override
  void initState() {
    super.initState();
    _currentTransaction = widget.transaction;
  }

  Future<void> _editTransaction() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionEditScreen(
          transaction: _currentTransaction,
        ),
      ),
    );

    // Refresh transaction data if edit was successful
    if (result == true && mounted) {
      try {
        final transactionService = TransactionService();
        // Get updated transaction from Firestore
        final updatedTransaction = await transactionService.getTransactionById(_currentTransaction.id!);
        if (updatedTransaction != null && mounted) {
          setState(() {
            _currentTransaction = updatedTransaction;
          });
        }
      } catch (e) {
        // Silently fail - transaction will refresh on next load
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = AppCategories.getCategoryByName(_currentTransaction.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: _editTransaction,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header card with gradient and category icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    category.color,
                    category.color.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Category icon with hero animation
                  Hero(
                    tag: 'transaction_${_currentTransaction.id}',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category.icon,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  Text(
                    CurrencyUtils.formatAmount(
                      _currentTransaction.amount,
                      _currentTransaction.currency,
                    ),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Category
                  Text(
                    _currentTransaction.category,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),

            // Details section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailCard(
                    context,
                    icon: Icons.store,
                    label: 'Merchant',
                    value: _currentTransaction.merchant ?? 'Not specified',
                  ),
                  const SizedBox(height: 12),
                  
                  if (_currentTransaction.description != null && _currentTransaction.description!.isNotEmpty)
                    _buildDetailCard(
                      context,
                      icon: Icons.description,
                      label: 'Description',
                      value: _currentTransaction.description!,
                    ),
                  
                  if (_currentTransaction.description != null && _currentTransaction.description!.isNotEmpty)
                    const SizedBox(height: 12),
                  
                  _buildDetailCard(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: DateFormat.yMMMMd().add_jm().format(_currentTransaction.transactionDate),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildDetailCard(
                    context,
                    icon: Icons.payment,
                    label: 'Payment Method',
                    value: _formatPaymentMethod(_currentTransaction.paymentMethod),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildDetailCard(
                    context,
                    icon: Icons.input,
                    label: 'Input Method',
                    value: _formatInputMethod(_currentTransaction.inputMethod),
                  ),
                  
                  // AI Confidence (if available)
                  if (_currentTransaction.aiConfidence != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      context,
                      icon: Icons.psychology,
                      label: 'AI Confidence',
                      value: '${(_currentTransaction.aiConfidence! * 100).toStringAsFixed(0)}%',
                      trailing: LinearProgressIndicator(
                        value: _currentTransaction.aiConfidence,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                          _currentTransaction.aiConfidence! > 0.8 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],

                  // Notes (if available)
                  if (_currentTransaction.notes != null && _currentTransaction.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      context,
                      icon: Icons.notes,
                      label: 'Notes',
                      value: _currentTransaction.notes!,
                    ),
                  ],

                  // Receipt items breakdown (if from receipt)
                  if (_currentTransaction.receiptData != null) ...[
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Receipt Items',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildReceiptItems(context),
                  ],
                  
                  // Metadata section
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'METADATA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildDetailCard(
                    context,
                    icon: Icons.fingerprint,
                    label: 'Transaction ID',
                    value: _currentTransaction.id ?? 'Unknown',
                  ),
                  const SizedBox(height: 12),
                  
                  _buildDetailCard(
                    context,
                    icon: Icons.update,
                    label: 'Created',
                    value: DateFormat('MMM d, y h:mm a').format(_currentTransaction.createdAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (trailing != null) ...[
              const SizedBox(height: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptItems(BuildContext context) {
    final items = _currentTransaction.receiptData?['items'] as List?;
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: items.map<Widget>((item) {
        final itemName = item['name'] ?? item['item'] ?? 'Unknown item';
        final itemPrice = (item['price'] ?? 0).toDouble();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: Text(itemName),
            trailing: Text(
              CurrencyUtils.formatAmount(itemPrice, _currentTransaction.currency),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatPaymentMethod(String method) {
    return method.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatInputMethod(String method) {
    switch (method) {
      case 'text':
        return 'Text Entry';
      case 'receipt_photo':
        return 'Receipt Photo';
      case 'voice':
        return 'Voice Input';
      case 'manual':
        return 'Manual Entry';
      default:
        return method;
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await TransactionService().deleteTransaction(_currentTransaction.id!);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting transaction: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}