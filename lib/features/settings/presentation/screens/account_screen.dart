import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final initial = user?.email?.substring(0, 1).toUpperCase() ?? 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.space16),
        children: [
          SizedBox(height: DesignTokens.space8),

          // Profile card
          _GlassSection(
            delay: 0,
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.space20),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: DesignTokens.space12),
                  Text(
                    user?.displayName ?? 'User',
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
          ),
          SizedBox(height: DesignTokens.space20),

          // Subscription plan card
          _SectionLabel(title: 'SUBSCRIPTION', delay: 1),
          SizedBox(height: DesignTokens.space8),
          _GlassSection(
            delay: 1,
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.space12,
                          vertical: DesignTokens.space6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentEmerald.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                                size: 14, color: AppTheme.accentEmerald),
                            SizedBox(width: DesignTokens.space4),
                            Text(
                              'Free Plan',
                              style: context.textTheme.labelMedium?.copyWith(
                                color: AppTheme.accentEmerald,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.space16),

                  // Feature comparison
                  _PlanFeature(
                    title: 'AI Chat',
                    free: 'Basic',
                    pro: 'Advanced + Memory',
                    context: context,
                  ),
                  _PlanFeature(
                    title: 'Insights History',
                    free: '7 days',
                    pro: '365 days',
                    context: context,
                  ),
                  _PlanFeature(
                    title: 'Chat Sessions',
                    free: '7 max',
                    pro: 'Unlimited',
                    context: context,
                  ),
                  _PlanFeature(
                    title: 'Financial Goals',
                    free: '1 goal',
                    pro: 'Unlimited',
                    context: context,
                  ),
                  _PlanFeature(
                    title: 'AI Coaching',
                    free: 'Tip Library',
                    pro: 'Personalized + Nudges',
                    context: context,
                  ),
                  _PlanFeature(
                    title: 'AI Model',
                    free: 'Flash Lite',
                    pro: 'Flash + Pro',
                    context: context,
                  ),

                  SizedBox(height: DesignTokens.space16),
                  SizedBox(
                    width: double.infinity,
                    child: PremiumButton(
                      onPressed: () {
                        HapticUtils.medium();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(PhosphorIcons.info(PhosphorIconsStyle.fill),
                                    size: 18, color: Colors.white),
                                SizedBox(width: DesignTokens.space8),
                                const Expanded(
                                  child: Text('Pro subscription coming soon! Stay tuned.'),
                                ),
                              ],
                            ),
                            backgroundColor: AppTheme.primaryIndigo,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.crownSimple(PhosphorIconsStyle.fill), size: 18),
                          SizedBox(width: DesignTokens.space8),
                          const Text('Upgrade to Pro — \$4.99/mo'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: DesignTokens.space20),

          // Data section
          _SectionLabel(title: 'DATA', delay: 2),
          SizedBox(height: DesignTokens.space8),
          _GlassSection(
            delay: 2,
            child: _SettingsRow(
              icon: PhosphorIcons.downloadSimple(PhosphorIconsStyle.duotone),
              iconColor: AppTheme.primaryIndigo,
              title: 'Export Data',
              subtitle: 'Download your transactions as CSV',
              trailing: Icon(
                PhosphorIcons.caretRight(),
                size: DesignTokens.iconSM,
                color: context.colors.onSurface.withOpacity(0.3),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export coming soon')),
                );
              },
            ),
          ),
          SizedBox(height: DesignTokens.space20),

          // About section
          _SectionLabel(title: 'ABOUT', delay: 3),
          SizedBox(height: DesignTokens.space8),
          _GlassSection(
            delay: 3,
            child: Column(
              children: [
                _SettingsRow(
                  icon: PhosphorIcons.info(PhosphorIconsStyle.duotone),
                  iconColor: context.colors.onSurface.withOpacity(0.5),
                  title: 'Version',
                  subtitle: AppConstants.appVersion,
                  trailing: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.space8,
                      vertical: DesignTokens.space2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryIndigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                    ),
                    child: Text(
                      AppConstants.appVersion,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryIndigo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                _divider(context),
                _SettingsRow(
                  icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
                  iconColor: context.colors.onSurface.withOpacity(0.5),
                  title: 'Privacy Policy',
                  trailing: Icon(
                    PhosphorIcons.arrowSquareOut(),
                    size: DesignTokens.iconSM,
                    color: context.colors.onSurface.withOpacity(0.3),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy policy coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: DesignTokens.space24),

          // Sign out
          PremiumButton(
            onPressed: () => _confirmSignOut(context, authService),
            variant: PremiumButtonVariant.danger,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.signOut(), size: DesignTokens.iconSM),
                SizedBox(width: DesignTokens.space8),
                const Text('Sign Out'),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: 3 * 50))
              .fadeIn(duration: DesignTokens.durationNormal)
              .slideY(begin: 0.05, end: 0),

          SizedBox(height: DesignTokens.space48),
        ],
      ),
    );
  }

  static Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: DesignTokens.space48 + DesignTokens.space12,
      color: context.colors.onSurface.withOpacity(0.06),
    );
  }

  void _confirmSignOut(BuildContext context, AuthService authService) {
    showGlassBottomSheet(
      context: context,
      builder: (ctx) => Padding(
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
                PhosphorIcons.signOut(PhosphorIconsStyle.duotone),
                size: DesignTokens.iconLG,
                color: AppTheme.rose500,
              ),
            ),
            SizedBox(height: DesignTokens.space16),
            Text(
              'Sign Out',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: DesignTokens.space8),
            Text(
              'Are you sure you want to sign out?',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: DesignTokens.space24),
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    onPressed: () => Navigator.pop(ctx),
                    variant: PremiumButtonVariant.secondary,
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: PremiumButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await authService.signOut();
                      if (context.mounted) {
                        context.go(AppConstants.routeSignIn);
                      }
                    },
                    variant: PremiumButtonVariant.danger,
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan feature comparison row ──
class _PlanFeature extends StatelessWidget {
  final String title;
  final String free;
  final String pro;
  final BuildContext context;

  const _PlanFeature({
    required this.title,
    required this.free,
    required this.pro,
    required this.context,
  });

  @override
  Widget build(BuildContext outerContext) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.space8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: outerContext.textTheme.bodySmall?.copyWith(
                color: outerContext.colors.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              free,
              style: outerContext.textTheme.bodySmall?.copyWith(
                color: outerContext.colors.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          Expanded(
            child: Text(
              pro,
              style: outerContext.textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryIndigo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared UI components ──

class _SectionLabel extends StatelessWidget {
  final String title;
  final int delay;

  const _SectionLabel({required this.title, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: DesignTokens.space4),
      child: Text(
        title,
        style: context.textTheme.labelMedium?.copyWith(
          color: context.colors.onSurface.withOpacity(0.45),
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay * 50))
        .fadeIn(duration: DesignTokens.durationNormal);
  }
}

class _GlassSection extends StatelessWidget {
  final Widget child;
  final int delay;

  const _GlassSection({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    )
        .animate(delay: Duration(milliseconds: delay * 50))
        .fadeIn(duration: DesignTokens.durationNormal)
        .slideY(begin: 0.05, end: 0);
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                ),
                child: Icon(icon, size: DesignTokens.iconMD, color: iconColor),
              ),
              SizedBox(width: DesignTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurface.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
