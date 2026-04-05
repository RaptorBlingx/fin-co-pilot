import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/design_tokens.dart';

/// Wraps a child with staggered fade + slide-up entrance animation.
///
/// ```dart
/// Column(
///   children: items.asMap().entries.map((e) =>
///     StaggeredFadeSlide(index: e.key, child: MyWidget(e.value)),
///   ).toList(),
/// )
/// ```
class StaggeredFadeSlide extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration? delay;
  final Duration? duration;
  final double slideOffset;

  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.delay,
    this.duration,
    this.slideOffset = 20,
  });

  @override
  Widget build(BuildContext context) {
    final d = delay ?? DesignTokens.staggerFor(index);
    return child
        .animate(delay: d)
        .fadeIn(
          duration: duration ?? DesignTokens.durationFast,
          curve: DesignTokens.curveDecelerate,
        )
        .slideY(
          begin: slideOffset / 100,
          end: 0,
          duration: duration ?? DesignTokens.durationNormal,
          curve: DesignTokens.curveDecelerate,
        );
  }
}

/// Extension for convenience usage: `widget.staggered(2)`
extension StaggeredAnimationExt on Widget {
  Widget staggered(int index, {double slideOffset = 20}) {
    return StaggeredFadeSlide(
      index: index,
      slideOffset: slideOffset,
      child: this,
    );
  }
}
