import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// A glassmorphism card component with backdrop blur.
///
/// Automatically adapts styling from [GlassTheme] extension.
/// Wraps content in [RepaintBoundary] to isolate blur cost.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final double? blurSigma;
  final VoidCallback? onTap;
  final bool enableBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.blurSigma,
    this.onTap,
    this.enableBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isDark = context.isDark;
    final radius = borderRadius ?? DesignTokens.borderRadiusMD;
    final sigma = blurSigma ?? glass.blurSigma;
    final bg = color ?? glass.glassBackground;

    Widget card = RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: enableBorder
                  ? Border.all(
                      color: glass.glassBorder,
                      width: DesignTokens.glassBorderWidth,
                    )
                  : null,
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        glass.glassHighlight,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3],
                    )
                  : null,
            ),
            padding: padding ?? DesignTokens.cardPadding,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      card = _TapScaleWrapper(onTap: onTap!, child: card);
    }

    return card;
  }
}

/// Adds scale-down press effect + haptic to any child.
class _TapScaleWrapper extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TapScaleWrapper({required this.onTap, required this.child});

  @override
  State<_TapScaleWrapper> createState() => _TapScaleWrapperState();
}

class _TapScaleWrapperState extends State<_TapScaleWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: DesignTokens.durationInstant,
      vsync: this,
    );
    _scale = Tween(begin: 1.0, end: DesignTokens.buttonPressScale)
        .animate(CurvedAnimation(parent: _ctrl, curve: DesignTokens.curveStandard));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
