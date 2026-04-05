import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/categories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../models/transaction.dart';
import '../../../shared/widgets/light_card.dart';
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
    final category = AppCategories.getCategoryByName(transaction.category);
    final isIncome = transaction.type == TransactionType.income;
    final financeColors = context.financeColors;

    return LightCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space12,
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: DesignTokens.avatarMD,
              height: DesignTokens.avatarMD,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.12),
                borderRadius: DesignTokens.borderRadiusMD,
              ),
              child: Center(
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: DesignTokens.iconSM,
                ),
              ),
            ),

            const SizedBox(width: DesignTokens.space12),

            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchant ??
                        transaction.description ??
                        'Unknown',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(transaction.transactionDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: DesignTokens.space8),

            // Amount
            Text(
              '${isIncome ? '+' : '-'}${CurrencyUtils.formatAmount(transaction.amount.abs(), transaction.currency)}',
              style: AppTheme.monoAmountStyle(context).copyWith(
                    color: isIncome
                        ? financeColors.positive
                        : financeColors.negative,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
            ),
          ],
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
      return DateFormat('EEEE, h:mm a').format(date);
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }
}