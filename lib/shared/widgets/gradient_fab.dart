import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Premium floating action button with gradient fill, glass ring,
/// and deeper press animation.
class GradientFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData? icon;
  final String? heroTag;
  final String? tooltip;

  const GradientFAB({
    super.key,
    required this.onPressed,
    this.icon,
    this.heroTag,
    this.tooltip = 'Add Transaction',
  });

  @override
  State<GradientFAB> createState() => _GradientFABState();
}

class _GradientFABState extends State<GradientFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: DesignTokens.durationInstant,
    );
    _scale = Tween<double>(begin: 1.0, end: DesignTokens.fabPressScale)
        .animate(CurvedAnimation(parent: _ctrl, curve: DesignTokens.curveStandard));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    _ctrl.forward();
    HapticFeedback.heavyImpact();
    widget.onPressed();
    await Future.delayed(const Duration(milliseconds: 60));
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppTheme.primaryGradientDark : AppTheme.primaryGradient;

    return ScaleTransition(
      scale: _scale,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: GestureDetector(
          onTapDown: (_) => _ctrl.forward(),
          onTapUp: (_) => _handlePress(),
          onTapCancel: () => _ctrl.reverse(),
          child: Container(
            width: DesignTokens.fabSize,
            height: DesignTokens.fabSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.10 : 0.20),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryIndigo.withOpacity(isDark ? 0.3 : 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              widget.icon ?? PhosphorIcons.plus(PhosphorIconsStyle.bold),
              color: Colors.white,
              size: DesignTokens.fabIconSize,
            ),
          ),
        ),
      ),
    );
  }
}
