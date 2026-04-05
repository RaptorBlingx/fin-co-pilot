import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../models/transaction.dart' as model;
import '../../../../core/utils/currency_utils.dart';
import '../../../../services/transaction_service.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
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
      PageRouteBuilder<bool>(
        pageBuilder: (_, __, ___) => TransactionEditScreen(
          transaction: _currentTransaction,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: DesignTokens.durationNormal,
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
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.pencilSimple()),
            tooltip: 'Edit',
            onPressed: _editTransaction,
          ),
          IconButton(
            icon: Icon(PhosphorIcons.trash(), color: AppTheme.rose500),
            tooltip: 'Delete',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header card with category icon and amount
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(DesignTokens.space32),
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
                  SizedBox(height: DesignTokens.space16),
                  Text(
                    CurrencyUtils.formatAmount(
                      _currentTransaction.amount,
                      _currentTransaction.currency,
                    ),
                    style: context.textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: DesignTokens.space8),
                  Text(
                    _currentTransaction.category,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: DesignTokens.durationNormal),

            // Details section
            Padding(
              padding: EdgeInsets.all(DesignTokens.space16),
              child: Column(
                children: [
                  _buildDetailCard(
                    context,
                    icon: PhosphorIcons.storefront(),
                    label: 'Merchant',
                    value: _currentTransaction.merchant ?? 'Not specified',
                  ),
                  SizedBox(height: DesignTokens.space12),
                  
                  if (_currentTransaction.description != null && _currentTransaction.description!.isNotEmpty) ...[
                    _buildDetailCard(
                      context,
                      icon: PhosphorIcons.noteBlank(),
                      label: 'Description',
                      value: _currentTransaction.description!,
                    ),
                    SizedBox(height: DesignTokens.space12),
                  ],
                  
                  _buildDetailCard(
                    context,
                    icon: PhosphorIcons.calendarBlank(),
                    label: 'Date',
                    value: DateFormat.yMMMMd().add_jm().format(_currentTransaction.transactionDate),
                  ),
                  SizedBox(height: DesignTokens.space12),
                  
                  _buildDetailCard(
                    context,
                    icon: PhosphorIcons.creditCard(),
                    label: 'Payment Method',
                    value: _formatPaymentMethod(_currentTransaction.paymentMethod),
                  ),
                  SizedBox(height: DesignTokens.space12),
                  
                  _buildDetailCard(
                    context,
                    icon: PhosphorIcons.textAa(),
                    label: 'Input Method',
                    value: _formatInputMethod(_currentTransaction.inputMethod),
                  ),
                  
                  // AI Confidence
                  if (_currentTransaction.aiConfidence != null) ...[
                    SizedBox(height: DesignTokens.space12),
                    _buildDetailCard(
                      context,
                      icon: PhosphorIcons.brain(),
                      label: 'AI Confidence',
                      value: '${(_currentTransaction.aiConfidence! * 100).toStringAsFixed(0)}%',
                      trailing: ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                        child: LinearProgressIndicator(
                          value: _currentTransaction.aiConfidence,
                          backgroundColor: context.colors.onSurface.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(
                            _currentTransaction.aiConfidence! > 0.8
                                ? AppTheme.accentEmerald
                                : AppTheme.amber500,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],

                  // Notes
                  if (_currentTransaction.notes != null && _currentTransaction.notes!.isNotEmpty) ...[
                    SizedBox(height: DesignTokens.space12),
                    _buildDetailCard(
                      context,
                      icon: PhosphorIcons.note(),
                      label: 'Notes',
                      value: _currentTransaction.notes!,
                    ),
                  ],

                  // Receipt items breakdown
                  if (_currentTransaction.receiptData != null) ...[
                    SizedBox(height: DesignTokens.space24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Receipt Items',
                        style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    SizedBox(height: DesignTokens.space12),
                    _buildReceiptItems(context),
                  ],
                  
                  // Metadata section
                  SizedBox(height: DesignTokens.space24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'METADATA',
                      style: context.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: context.colors.onSurface.withOpacity(0.5),
                          ),
                    ),
                  ),
                  SizedBox(height: DesignTokens.space12),
                  
                  _buildDetailCard(
                    context,
                    icon: PhosphorIcons.fingerprint(),
                    label: 'Transaction ID',
                    value: _currentTransaction.id ?? 'Unknown',
                  ),
                  SizedBox(height: DesignTokens.space12),
                  
                  _buildDetailCard(
                    context,
                    icon: PhosphorIcons.clockCounterClockwise(),
                    label: 'Created',
                    value: DateFormat('MMM d, y h:mm a').format(_currentTransaction.createdAt),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(
                  duration: DesignTokens.durationNormal,
                  delay: DesignTokens.staggerDelay,
                )
                .slideY(begin: 0.05, end: 0),
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
    return GlassCard(
      padding: EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: DesignTokens.iconSM, color: AppTheme.primaryIndigo),
              SizedBox(width: DesignTokens.space8),
              Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space8),
          Text(
            value,
            style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (trailing != null) ...[
            SizedBox(height: DesignTokens.space8),
            trailing,
          ],
        ],
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

        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.space8),
          child: GlassCard(
            child: ListTile(
              leading: Icon(
                PhosphorIcons.shoppingBag(),
                color: AppTheme.primaryIndigo,
              ),
              title: Text(itemName),
              trailing: Text(
                CurrencyUtils.formatAmount(itemPrice, _currentTransaction.currency),
                style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
    final confirmed = await showGlassBottomSheet<bool>(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.all(DesignTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.rose500.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.trash(),
                color: AppTheme.rose500,
                size: DesignTokens.iconLG,
              ),
            ),
            SizedBox(height: DesignTokens.space16),
            Text(
              'Delete Transaction',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: DesignTokens.space8),
            Text(
              'Are you sure you want to delete this transaction? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: DesignTokens.space24),
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    onPressed: () => Navigator.pop(context, false),
                    variant: PremiumButtonVariant.secondary,
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: PremiumButton(
                    onPressed: () => Navigator.pop(context, true),
                    variant: PremiumButtonVariant.danger,
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final transactionService = TransactionService();
        await transactionService.updateBudgetSpendingPublic(
          userId: _currentTransaction.userId,
          category: _currentTransaction.category,
          amount: -_currentTransaction.amount,
          transactionDate: _currentTransaction.transactionDate,
        );
        await transactionService.deleteTransaction(_currentTransaction.id!);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaction deleted'),
              backgroundColor: AppTheme.rose500,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting transaction: $e'),
              backgroundColor: AppTheme.rose500,
            ),
          );
        }
      }
    }
  }
}