import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../core/navigation/page_transitions.dart';
import '../../reports/presentation/screens/reports_screen.dart';
import '../../coaching/presentation/screens/unified_coach_screen.dart';
import '../../settings/presentation/screens/settings_screen.dart';
import '../../settings/presentation/screens/account_screen.dart';
import '../../settings/presentation/screens/notification_settings_screen.dart';
import '../../price_finder/presentation/enhanced_price_finder_home.dart';
import '../../budget/presentation/screens/budget_screen.dart';
import '../../../services/auth_service.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final initial = user?.email?.substring(0, 1).toUpperCase() ?? 'U';
    final name = user?.displayName ?? 'User';
    final greeting = _getGreeting();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space16,
          ),
          children: [
            // User header
            Container(
              padding: EdgeInsets.all(DesignTokens.space20),
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                border: Border.all(
                  color: context.isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: context.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: DesignTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $name',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: DesignTokens.space2),
                        Text(
                          user?.email ?? '',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: DesignTokens.durationNormal)
                .slideY(begin: -0.1, end: 0),
            SizedBox(height: DesignTokens.space24),

            // Tools section
            _buildSection(
              context,
              title: 'Tools',
              delay: 1,
              items: [
                _MenuItem(
                  icon: PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
                  title: 'Budget Manager',
                  subtitle: 'Set & track spending limits',
                  color: AppTheme.primaryIndigo,
                  onTap: () {
                    HapticUtils.light();
                    context.pushWithFade(const BudgetScreen());
                  },
                ),
                _MenuItem(
                  icon: PhosphorIcons.shoppingCart(PhosphorIconsStyle.duotone),
                  title: 'Price Finder',
                  subtitle: 'Track prices & find best deals',
                  color: AppTheme.accentEmerald,
                  onTap: () {
                    HapticUtils.light();
                    context.pushWithFade(const EnhancedPriceFinderHome());
                  },
                ),
              ],
            ),
            SizedBox(height: DesignTokens.space16),

            // Analysis section
            _buildSection(
              context,
              title: 'Analysis',
              delay: 2,
              items: [
                _MenuItem(
                  icon: PhosphorIcons.chartBar(PhosphorIconsStyle.duotone),
                  title: 'Reports',
                  subtitle: 'Monthly summaries & exports',
                  color: AppTheme.accentPurple,
                  onTap: () {
                    HapticUtils.light();
                    context.pushWithFade(const ReportsScreen());
                  },
                ),
                _MenuItem(
                  icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.duotone),
                  title: 'Health Score',
                  subtitle: 'Your financial wellness',
                  color: AppTheme.rose500,
                  onTap: () {
                    HapticUtils.light();
                    context.push(AppConstants.routeHealthScore);
                  },
                ),
                _MenuItem(
                  icon: PhosphorIcons.repeat(PhosphorIconsStyle.duotone),
                  title: 'Subscriptions',
                  subtitle: 'Detect & manage recurring charges',
                  color: AppTheme.amber500,
                  onTap: () {
                    HapticUtils.light();
                    context.push(AppConstants.routeSubscriptions);
                  },
                ),
              ],
            ),
            SizedBox(height: DesignTokens.space16),

            // Growth section
            _buildSection(
              context,
              title: 'Growth',
              delay: 3,
              items: [
                _MenuItem(
                  icon: PhosphorIcons.sparkle(PhosphorIconsStyle.duotone),
                  title: 'Coach',
                  subtitle: 'AI coaching & 100+ money tips',
                  color: AppTheme.primaryIndigo,
                  onTap: () {
                    HapticUtils.light();
                    context.pushWithFade(const UnifiedCoachScreen());
                  },
                ),
              ],
            ),
            SizedBox(height: DesignTokens.space24),

            // Settings section
            _buildSection(
              context,
              title: 'Settings',
              delay: 4,
              items: [
                _MenuItem(
                  icon: PhosphorIcons.userCircle(PhosphorIconsStyle.duotone),
                  title: 'Account',
                  subtitle: 'Profile & subscription',
                  color: context.colors.onSurface.withOpacity(0.6),
                  onTap: () {
                    HapticUtils.light();
                    context.pushWithFade(const AccountScreen());
                  },
                ),
                _MenuItem(
                  icon: PhosphorIcons.bell(PhosphorIconsStyle.duotone),
                  title: 'Notifications',
                  subtitle: 'Alerts & reminders',
                  color: context.colors.onSurface.withOpacity(0.6),
                  onTap: () {
                    HapticUtils.light();
                    context.pushWithFade(const NotificationSettingsScreen());
                  },
                ),
                _MenuItem(
                  icon: PhosphorIcons.palette(PhosphorIconsStyle.duotone),
                  title: 'Appearance',
                  subtitle: 'Theme & display',
                  color: context.colors.onSurface.withOpacity(0.6),
                  onTap: () {
                    HapticUtils.light();
                    context.pushWithFade(const SettingsScreen());
                  },
                ),
                _MenuItem(
                  icon: PhosphorIcons.question(PhosphorIconsStyle.duotone),
                  title: 'Help & Support',
                  subtitle: 'FAQs & contact us',
                  color: context.colors.onSurface.withOpacity(0.6),
                  onTap: () {
                    HapticUtils.light();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support coming soon!')),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: DesignTokens.space32),
            Center(
              child: Text(
                'Fin Co-Pilot v${AppConstants.appVersion}',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.35),
                ),
              ),
            ),
            SizedBox(height: DesignTokens.space16),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
    int delay = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.space4,
            bottom: DesignTokens.space8,
          ),
          child: Text(
            title.toUpperCase(),
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colors.onSurface.withOpacity(0.45),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
            border: Border.all(
              color: context.isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _buildMenuItem(context, items[i]),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: DesignTokens.space48 + DesignTokens.space12,
                    color: context.colors.onSurface.withOpacity(0.06),
                  ),
              ],
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(
          duration: DesignTokens.durationNormal,
          delay: Duration(milliseconds: delay * 50),
        )
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                ),
                child: Icon(
                  item.icon,
                  size: DesignTokens.iconMD,
                  color: item.color,
                ),
              ),
              SizedBox(width: DesignTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIcons.caretRight(),
                size: DesignTokens.iconSM,
                color: context.colors.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}