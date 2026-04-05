import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../core/constants/categories.dart';
import '../../../models/transaction.dart' as model;
import '../../../services/analytics_service.dart';
import '../../../services/transaction_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_button.dart';
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
          bottom: DesignTokens.space8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space12,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primaryIndigo
              : context.isDark
                  ? Colors.white.withOpacity(0.06)
                  : AppTheme.slate100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(DesignTokens.radiusLG),
            topRight: const Radius.circular(DesignTokens.radiusLG),
            bottomLeft:
                Radius.circular(isUser ? DesignTokens.radiusLG : DesignTokens.radiusXS),
            bottomRight:
                Radius.circular(isUser ? DesignTokens.radiusXS : DesignTokens.radiusLG),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: context.colors.onSurface.withOpacity(0.06),
                ),
        ),
        child: Text(
          message.text ?? '',
          style: context.textTheme.bodyMedium?.copyWith(
            color: isUser ? Colors.white : context.colors.onSurface,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionPreview(BuildContext context) {
    final preview = message.transactionPreview!;
    final cat = AppCategories.getCategoryByName(preview.category);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          right: 48,
          bottom: DesignTokens.space8,
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.space8),
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusSM),
                    ),
                    child: Icon(cat.icon, size: DesignTokens.iconSM,
                        color: cat.color),
                  ),
                  const SizedBox(width: DesignTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preview.merchant ??
                              preview.description ??
                              preview.category,
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: DesignTokens.space2),
                        Text(
                          'Just now · ${preview.category}',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.onSurface
                                .withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.space12),

              // Amount
              Text(
                CurrencyUtils.formatAmount(
                    preview.amount, preview.currency),
                style: AppTheme.displayAmountStyle(context).copyWith(
                  color: context.financeColors.negative,
                ),
              ),

              const SizedBox(height: DesignTokens.space16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: PremiumButton(
                      onPressed: () =>
                          _handleAddTransaction(context, preview),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.check(),
                              size: 16, color: Colors.white),
                          const SizedBox(width: DesignTokens.space6),
                          const Text('Save'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  Expanded(
                    child: PremiumButton(
                      variant: PremiumButtonVariant.secondary,
                      onPressed: () =>
                          _handleEditTransaction(context, preview),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.pencilSimple(),
                              size: 16),
                          const SizedBox(width: DesignTokens.space6),
                          const Text('Edit'),
                        ],
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

  Widget _buildQuickActions(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          right: 48,
          bottom: DesignTokens.space8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.text != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space16,
                  vertical: DesignTokens.space12,
                ),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? Colors.white.withOpacity(0.06)
                      : AppTheme.slate100,
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusLG),
                  border: Border.all(
                    color:
                        context.colors.onSurface.withOpacity(0.06),
                  ),
                ),
                child: Text(
                  message.text!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
            const SizedBox(height: DesignTokens.space8),
            Wrap(
              spacing: DesignTokens.space8,
              runSpacing: DesignTokens.space8,
              children: message.quickActions!.map((action) {
                return GestureDetector(
                  onTap: action.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space12,
                      vertical: DesignTokens.space8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryIndigo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(
                          DesignTokens.radiusFull),
                      border: Border.all(
                        color:
                            AppTheme.primaryIndigo.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (action.icon != null) ...[
                          Icon(action.icon,
                              size: 16,
                              color: AppTheme.primaryIndigo),
                          const SizedBox(width: DesignTokens.space6),
                        ],
                        Text(
                          action.label,
                          style: context.textTheme.labelMedium
                              ?.copyWith(
                            color: AppTheme.primaryIndigo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
        margin: const EdgeInsets.only(
          right: 48,
          bottom: DesignTokens.space8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space20,
          vertical: DesignTokens.space16,
        ),
        decoration: BoxDecoration(
          color: context.isDark
              ? Colors.white.withOpacity(0.06)
              : AppTheme.slate100,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
          border: Border.all(
            color: context.colors.onSurface.withOpacity(0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Padding(
              padding: EdgeInsets.only(right: i < 2 ? 6.0 : 0),
              child: _PulseDot(delay: i * 200),
            ),
          ),
        ),
      ),
    );
  }

  void _handleAddTransaction(
      BuildContext context, TransactionPreview preview) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      HapticUtils.light();

      final transaction = model.Transaction(
        userId: user.uid,
        amount: preview.amount,
        currency: preview.currency,
        category: preview.category,
        merchant: preview.merchant,
        description:
            preview.description ?? preview.merchant ?? preview.category,
        transactionDate: preview.date,
        createdAt: DateTime.now(),
        inputMethod: 'chat',
        paymentMethod: 'cash',
      );

      await FirebaseFirestore.instance
          .collection('transactions')
          .add(transaction.toFirestore());

      await TransactionService().updateBudgetSpendingPublic(
        userId: user.uid,
        category: transaction.category,
        amount: transaction.amount,
        transactionDate: transaction.transactionDate,
      );

      await AnalyticsService.logTransactionAdded(
        method: 'chat',
        category: transaction.category,
        amount: transaction.amount,
        merchant: transaction.merchant,
      );

      if (!context.mounted) return;
      HapticUtils.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved! ${CurrencyUtils.formatAmount(preview.amount, preview.currency)} added to ${preview.category}',
          ),
          backgroundColor: AppTheme.accentEmerald,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Couldn\'t save — ${e.toString()}'),
          backgroundColor: AppTheme.rose500,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleEditTransaction(
      BuildContext context, TransactionPreview preview) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
      ),
    );
  }
}

// ── Animated pulse dot for loading ──
class _PulseDot extends StatefulWidget {
  final int delay;
  const _PulseDot({required this.delay});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryIndigo,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}