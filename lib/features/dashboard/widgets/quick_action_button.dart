import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/staggered_animation.dart';

class QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const QuickActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () {
        HapticUtils.light();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space16,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: DesignTokens.borderRadiusMD,
              ),
              child: Icon(
                icon,
                size: DesignTokens.iconMD,
                color: color,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionDef(
        title: 'Scan Receipt',
        icon: PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
        color: AppTheme.accentPurple,
        route: AppConstants.routeReceiptCapture,
      ),
      _ActionDef(
        title: 'Reports',
        icon: PhosphorIcons.chartBar(PhosphorIconsStyle.duotone),
        color: AppTheme.primaryIndigo,
        route: AppConstants.routeReports,
      ),
      _ActionDef(
        title: 'Shopping',
        icon: PhosphorIcons.shoppingBag(PhosphorIconsStyle.duotone),
        color: AppTheme.accentEmerald,
        route: AppConstants.routeShopping,
      ),
      _ActionDef(
        title: 'Health Score',
        icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.duotone),
        color: AppTheme.rose400,
        route: AppConstants.routeHealthScore,
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                title: actions[0].title,
                icon: actions[0].icon,
                color: actions[0].color,
                onTap: () => context.push(actions[0].route),
              ).staggered(0),
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: QuickActionButton(
                title: actions[1].title,
                icon: actions[1].icon,
                color: actions[1].color,
                onTap: () => context.push(actions[1].route),
              ).staggered(1),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space12),
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                title: actions[2].title,
                icon: actions[2].icon,
                color: actions[2].color,
                onTap: () => context.push(actions[2].route),
              ).staggered(2),
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: QuickActionButton(
                title: actions[3].title,
                icon: actions[3].icon,
                color: actions[3].color,
                onTap: () => context.push(actions[3].route),
              ).staggered(3),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionDef {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  const _ActionDef({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}