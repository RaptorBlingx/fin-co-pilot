import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Circular progress indicator with animated sweep, gradient stroke,
/// and semantic color transitions.
///
/// ```dart
/// AnimatedProgressRing(
///   progress: 0.72,
///   size: 80,
///   color: context.financeColors.budgetHealthy,
///   child: Text('72%'),
/// )
/// ```
class AnimatedProgressRing extends StatefulWidget {
  final double progress; // 0.0 – 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final Color? backgroundColor;
  final Widget? child;
  final Gradient? gradient;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = DesignTokens.progressRingStroke,
    this.color = const Color(0xFF4F46E5),
    this.backgroundColor,
    this.child,
    this.gradient,
  });

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _progressAnim;
  double _prevProgress = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: DesignTokens.durationSlow,
    );
    _progressAnim = Tween(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _ctrl, curve: DesignTokens.curveDecelerate),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressRing old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _prevProgress = _progressAnim.value;
      _progressAnim = Tween(begin: _prevProgress, end: widget.progress).animate(
        CurvedAnimation(parent: _ctrl, curve: DesignTokens.curveDecelerate),
      );
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: _progressAnim.value.clamp(0.0, 1.0),
              color: widget.color,
              backgroundColor: widget.backgroundColor ??
                  widget.color.withOpacity(0.12),
              strokeWidth: widget.strokeWidth,
              gradient: widget.gradient,
            ),
            child: Center(child: widget.child),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final Gradient? gradient;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Progress arc
    final sweepAngle = 2 * math.pi * progress;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else {
      paint.color = color;
    }

    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
