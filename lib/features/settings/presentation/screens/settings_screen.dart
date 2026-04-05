import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/preferences_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../../main.dart' show themeProvider;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedCurrency = 'USD';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = PreferencesService.getCurrency() ?? 'USD';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeNotifier = ref.read(themeProvider);
    _isDarkMode = themeNotifier.isDarkMode ||
        (themeNotifier.isSystemMode && Theme.of(context).brightness == Brightness.dark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.space16),
        children: [
          SizedBox(height: DesignTokens.space8),

          // Theme section
          _SectionLabel(title: 'THEME', delay: 0),
          SizedBox(height: DesignTokens.space8),
          _GlassSection(
            delay: 0,
            child: Column(
              children: [
                // Dark Mode Toggle
                _SettingsRow(
                  icon: _isDarkMode
                      ? PhosphorIcons.moon(PhosphorIconsStyle.duotone)
                      : PhosphorIcons.sunDim(PhosphorIconsStyle.duotone),
                  iconColor: _isDarkMode ? AppTheme.accentPurple : AppTheme.amber500,
                  title: 'Dark Mode',
                  subtitle: _isDarkMode ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: (value) {
                      HapticUtils.light();
                      final themeNotifier = ref.read(themeProvider.notifier);
                      if (value) {
                        themeNotifier.setThemeMode(ThemeMode.dark);
                      } else {
                        themeNotifier.setThemeMode(ThemeMode.light);
                      }
                      setState(() => _isDarkMode = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: DesignTokens.space20),

          // Display section
          _SectionLabel(title: 'DISPLAY', delay: 1),
          SizedBox(height: DesignTokens.space8),
          _GlassSection(
            delay: 1,
            child: Column(
              children: [
                // Currency
                _SettingsRow(
                  icon: PhosphorIcons.coins(PhosphorIconsStyle.duotone),
                  iconColor: AppTheme.amber500,
                  title: 'Currency',
                  subtitle: '$_selectedCurrency (${CurrencyUtils.getCurrencySymbol(_selectedCurrency)})',
                  trailing: Icon(
                    PhosphorIcons.caretRight(),
                    size: DesignTokens.iconSM,
                    color: context.colors.onSurface.withOpacity(0.3),
                  ),
                ),
                _divider(context),
                // Language
                _SettingsRow(
                  icon: PhosphorIcons.globe(PhosphorIconsStyle.duotone),
                  iconColor: AppTheme.primaryIndigo,
                  title: 'Language',
                  subtitle: 'English',
                  trailing: Icon(
                    PhosphorIcons.caretRight(),
                    size: DesignTokens.iconSM,
                    color: context.colors.onSurface.withOpacity(0.3),
                  ),
                  onTap: () {
                    HapticUtils.light();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language selection coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: DesignTokens.space48),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: DesignTokens.space48 + DesignTokens.space12,
      color: context.colors.onSurface.withOpacity(0.06),
    );
  }
}

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