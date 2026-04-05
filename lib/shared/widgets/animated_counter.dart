import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Smoothly interpolates between numeric values with optional currency formatting.
///
/// ```dart
/// AnimatedCounter(
///   value: 1234.56,
///   prefix: '\$',
///   decimalPlaces: 2,
///   style: AppTheme.displayAmountStyle(context),
/// )
/// ```
class AnimatedCounter extends ImplicitlyAnimatedWidget {
  final double value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimalPlaces;
  final Color? positiveColor;
  final Color? negativeColor;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimalPlaces = 2,
    this.positiveColor,
    this.negativeColor,
    super.duration = DesignTokens.durationNormal,
    super.curve = DesignTokens.curveDecelerate,
  });

  @override
  AnimatedWidgetBaseState<AnimatedCounter> createState() =>
      _AnimatedCounterState();
}

class _AnimatedCounterState
    extends AnimatedWidgetBaseState<AnimatedCounter> {
  Tween<double>? _valueTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _valueTween = visitor(
      _valueTween,
      widget.value,
      (v) => Tween<double>(begin: v as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final current = _valueTween?.evaluate(animation) ?? widget.value;
    final formatted =
        '${widget.prefix}${current.toStringAsFixed(widget.decimalPlaces)}${widget.suffix}';

    Color? textColor;
    if (widget.positiveColor != null && current >= 0) {
      textColor = widget.positiveColor;
    } else if (widget.negativeColor != null && current < 0) {
      textColor = widget.negativeColor;
    }

    final style = (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
      color: textColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Text(formatted, style: style);
  }
}
