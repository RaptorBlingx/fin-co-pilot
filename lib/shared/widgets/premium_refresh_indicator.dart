import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptic_utils.dart';

/// Branded pull-to-refresh indicator with glass circle and rotating arrow.
///
/// Usage:
/// ```dart
/// PremiumRefreshIndicator(
///   onRefresh: () async { ... },
///   child: ListView(...),
/// )
/// ```
class PremiumRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const PremiumRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  Future<void> _handleRefresh() async {
    HapticUtils.medium();
    await onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      backgroundColor: isDark
          ? AppTheme.darkSurfaceContainer
          : Colors.white,
      color: colors.primary,
      strokeWidth: 2.5,
      displacement: 60,
      edgeOffset: 0,
      child: child,
    );
  }
}
