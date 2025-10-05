import 'package:flutter/material.dart';
import '../../../../shared/models/transaction.dart' as model;
import '../../../../core/utils/currency_utils.dart';
import '../../../../services/transaction_service.dart';
import 'package:intl/intl.dart';

class TransactionDetailScreen extends StatelessWidget {
  final model.Transaction transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit screen (we'll add this next)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount card
            Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Text(
                        CurrencyUtils.formatAmount(
                          transaction.amount,
                          transaction.currency,
                        ),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        transaction.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Details
            _DetailRow(
              icon: Icons.store,
              label: 'Merchant',
              value: transaction.merchant ?? 'Not specified',
            ),

            _DetailRow(
              icon: Icons.description,
              label: 'Description',
              value: transaction.description ?? 'No description',
            ),

            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: DateFormat('EEEE, MMMM d, y').format(transaction.transactionDate),
            ),

            _DetailRow(
              icon: Icons.access_time,
              label: 'Time',
              value: DateFormat('h:mm a').format(transaction.transactionDate),
            ),

            _DetailRow(
              icon: Icons.payment,
              label: 'Payment Method',
              value: _formatPaymentMethod(transaction.paymentMethod),
            ),

            _DetailRow(
              icon: Icons.input,
              label: 'Input Method',
              value: _formatInputMethod(transaction.inputMethod),
            ),

            if (transaction.aiConfidence != null)
              _DetailRow(
                icon: Icons.psychology,
                label: 'AI Confidence',
                value: '${(transaction.aiConfidence! * 100).toStringAsFixed(0)}%',
              ),

            if (transaction.notes != null && transaction.notes!.isNotEmpty)
              _DetailRow(
                icon: Icons.notes,
                label: 'Notes',
                value: transaction.notes!,
              ),

            const SizedBox(height: 24),

            // Metadata
            Text(
              'METADATA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            _DetailRow(
              icon: Icons.fingerprint,
              label: 'Transaction ID',
              value: transaction.id ?? 'Unknown',
              isSmall: true,
            ),

            _DetailRow(
              icon: Icons.update,
              label: 'Created',
              value: DateFormat('MMM d, y h:mm a').format(transaction.createdAt),
              isSmall: true,
            ),
          ],
        ),
      ),
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

  Future<void> _confirmDelete(BuildContext context) async {
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await TransactionService().deleteTransaction(transaction.id!);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSmall;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isSmall ? 16 : 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 16,
                    fontWeight: isSmall ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}