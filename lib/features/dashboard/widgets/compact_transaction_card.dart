import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/models/transaction.dart';

class CompactTransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const CompactTransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor(transaction.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getCategoryEmoji(transaction.category),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchant ?? transaction.description ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(transaction.transactionDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Amount
              Text(
                '-${CurrencyUtils.formatAmount(transaction.amount, transaction.currency)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'SF Mono',
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDay = DateTime(date.year, date.month, date.day);

    if (transactionDay == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (transactionDay == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE, h:mm a').format(date); // "Monday, 2:30 PM"
    } else {
      return DateFormat('MMM d, h:mm a').format(date); // "Oct 5, 2:30 PM"
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return '🛒';
      case 'dining':
        return '🍽️';
      case 'transport':
        return '🚗';
      case 'entertainment':
        return '🎬';
      case 'shopping':
        return '🛍️';
      case 'health':
        return '🏥';
      case 'bills':
        return '📄';
      case 'education':
        return '📚';
      case 'travel':
        return '✈️';
      case 'coffee':
        return '☕';
      default:
        return '💰';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return Colors.green;
      case 'dining':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'health':
        return Colors.red;
      case 'bills':
        return Colors.teal;
      case 'education':
        return Colors.indigo;
      case 'travel':
        return Colors.cyan;
      case 'coffee':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}