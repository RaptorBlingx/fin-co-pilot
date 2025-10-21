import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/models/transaction.dart' as model;
import '../../../services/analytics_service.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextBubble(context);
      case MessageType.transactionPreview:
        return _buildTransactionPreview(context);
      case MessageType.quickActions:
        return _buildQuickActions(context);
      case MessageType.loading:
        return _buildLoadingBubble(context);
    }
  }

  Widget _buildTextBubble(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser 
              ? AppTheme.primaryIndigo 
              : Theme.of(context).brightness == Brightness.light
                  ? AppTheme.slate100
                  : AppTheme.slate800,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        child: Text(
          message.text ?? '',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionPreview(BuildContext context) {
    final preview = message.transactionPreview!;
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 48, bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? AppTheme.slate100
              : AppTheme.slate800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentEmerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.accentEmerald,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Got it! ✓',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Transaction details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji + Category
                  Row(
                    children: [
                      Text(
                        preview.categoryEmoji ?? _getDefaultEmoji(preview.category),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preview.merchant ?? preview.description ?? preview.category,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Just now • ${preview.category}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Amount
                  Text(
                    CurrencyUtils.formatAmount(preview.amount, preview.currency),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontFamily: 'SF Mono',
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryIndigo,
                        ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAddTransaction(context, preview),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryIndigo,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Transaction'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _handleEditTransaction(context, preview),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 48, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.text != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppTheme.slate100
                      : AppTheme.slate800,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  message.text!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.quickActions!.map((action) {
                return ActionChip(
                  label: Text(action.label),
                  avatar: action.icon != null ? Icon(action.icon, size: 18) : null,
                  onPressed: action.onTap,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  side: BorderSide(
                    color: AppTheme.primaryIndigo.withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 48, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? AppTheme.slate100
              : AppTheme.slate800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryIndigo,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Thinking...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDefaultEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'coffee':
        return '☕';
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
      default:
        return '💰';
    }
  }

  void _handleAddTransaction(BuildContext context, TransactionPreview preview) async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Saving transaction...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Create transaction from preview
      final transaction = model.Transaction(
        userId: user.uid,
        amount: preview.amount,
        currency: preview.currency,
        category: preview.category,
        merchant: preview.merchant,
        description: preview.description ?? preview.merchant ?? preview.category,
        transactionDate: preview.date,
        createdAt: DateTime.now(),
        inputMethod: 'chat',
        paymentMethod: 'cash',
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('transactions')
          .add(transaction.toFirestore());

      // Track analytics
      await AnalyticsService.logTransactionAdded(
        method: 'chat',
        category: transaction.category,
        amount: transaction.amount,
        merchant: transaction.merchant,
      );

      // Show success message
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaction saved! ${CurrencyUtils.formatAmount(preview.amount, preview.currency)} added to ${preview.category}',
          ),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to transactions screen
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );

      // Navigate back to home
      Navigator.of(context).pop();
    } catch (e) {
      // Show error message
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save transaction: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleEditTransaction(BuildContext context, TransactionPreview preview) {
    // TODO: Open edit dialog or screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
      ),
    );
  }
}