import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animations/animations.dart';

/// Comprehensive animation utilities for smooth, consistent animations throughout the app
class AnimationUtils {
  
  // Animation durations
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration extraSlowDuration = Duration(milliseconds: 800);
  
  // Animation curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve fastCurve = Curves.easeOutQuart;
  
  // Standard delays for staggered animations
  static const Duration shortDelay = Duration(milliseconds: 50);
  static const Duration mediumDelay = Duration(milliseconds: 100);
  static const Duration longDelay = Duration(milliseconds: 150);

  /// Fade in animation with configurable duration and delay
  static Widget fadeIn({
    required Widget child,
    Duration duration = mediumDuration,
    Duration delay = Duration.zero,
    Curve curve = defaultCurve,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return child
        .animate(delay: delay)
        .fade(
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
        );
  }

  /// Slide in from bottom animation
  static Widget slideInFromBottom({
    required Widget child,
    Duration duration = mediumDuration,
    Duration delay = Duration.zero,
    Offset begin = const Offset(0, 1),
    Offset end = Offset.zero,
    Curve curve = smoothCurve,
  }) {
    return child
        .animate(delay: delay)
        .slideY(
          duration: duration,
          curve: curve,
          begin: begin.dy,
          end: end.dy,
        )
        .fade(duration: duration, curve: curve);
  }

  /// Slide in from top animation
  static Widget slideInFromTop({
    required Widget child,
    Duration duration = mediumDuration,
    Duration delay = Duration.zero,
    Offset begin = const Offset(0, -1),
    Offset end = Offset.zero,
    Curve curve = smoothCurve,
  }) {
    return child
        .animate(delay: delay)
        .slideY(
          duration: duration,
          curve: curve,
          begin: begin.dy,
          end: end.dy,
        )
        .fade(duration: duration, curve: curve);
  }

  /// Slide in from left animation
  static Widget slideInFromLeft({
    required Widget child,
    Duration duration = mediumDuration,
    Duration delay = Duration.zero,
    Offset begin = const Offset(-1, 0),
    Offset end = Offset.zero,
    Curve curve = smoothCurve,
  }) {
    return child
        .animate(delay: delay)
        .slideX(
          duration: duration,
          curve: curve,
          begin: begin.dx,
          end: end.dx,
        )
        .fade(duration: duration, curve: curve);
  }

  /// Slide in from right animation
  static Widget slideInFromRight({
    required Widget child,
    Duration duration = mediumDuration,
    Duration delay = Duration.zero,
    Offset begin = const Offset(1, 0),
    Offset end = Offset.zero,
    Curve curve = smoothCurve,
  }) {
    return child
        .animate(delay: delay)
        .slideX(
          duration: duration,
          curve: curve,
          begin: begin.dx,
          end: end.dx,
        )
        .fade(duration: duration, curve: curve);
  }

  /// Scale animation that grows from center
  static Widget scaleIn({
    required Widget child,
    Duration duration = mediumDuration,
    Duration delay = Duration.zero,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = bounceCurve,
    Alignment alignment = Alignment.center,
  }) {
    return child
        .animate(delay: delay)
        .scale(
          duration: duration,
          curve: curve,
          begin: Offset(begin, begin),
          end: Offset(end, end),
          alignment: alignment,
        )
        .fade(duration: duration, curve: defaultCurve);
  }

  /// Bounce animation for attention-grabbing effects
  static Widget bounce({
    required Widget child,
    Duration duration = mediumDuration,
    Duration delay = Duration.zero,
    double begin = 1.0,
    double end = 1.2,
    Curve curve = Curves.elasticOut,
  }) {
    return child
        .animate(delay: delay)
        .scale(
          duration: duration,
          curve: curve,
          begin: Offset(begin, begin),
          end: Offset(end, end),
        )
        .then()
        .scale(
          duration: duration,
          curve: curve,
          begin: Offset(end, end),
          end: Offset(begin, begin),
        );
  }

  /// Shake animation for error states
  static Widget shake({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    Duration delay = Duration.zero,
    double offset = 10.0,
  }) {
    return child
        .animate(delay: delay)
        .shake(
          duration: duration,
          offset: Offset(offset, 0),
        );
  }

  /// Rotation animation
  static Widget rotate({
    required Widget child,
    Duration duration = slowDuration,
    Duration delay = Duration.zero,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = defaultCurve,
  }) {
    return child
        .animate(delay: delay)
        .rotate(
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
        );
  }

  /// Shimmer effect for loading states
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    Color? color,
  }) {
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: duration,
          color: color ?? Colors.white.withOpacity(0.5),
        );
  }

  /// Blur animation for focus/unfocus effects
  static Widget blur({
    required Widget child,
    Duration duration = mediumDuration,
    Duration delay = Duration.zero,
    double begin = 0.0,
    double end = 5.0,
    Curve curve = defaultCurve,
  }) {
    return child
        .animate(delay: delay)
        .blur(
          duration: duration,
          curve: curve,
          begin: Offset(begin, begin),
          end: Offset(end, end),
        );
  }

  /// Flip animation for card reveals
  static Widget flip({
    required Widget child,
    Duration duration = slowDuration,
    Duration delay = Duration.zero,
    Axis direction = Axis.horizontal,
    Curve curve = defaultCurve,
  }) {
    return child
        .animate(delay: delay)
        .flip(
          duration: duration,
          curve: curve,
          direction: direction,
        );
  }

  /// Elastic scale animation for interactive elements
  static Widget elasticScale({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.elasticOut,
  }) {
    return child
        .animate(delay: delay)
        .scale(
          duration: duration,
          curve: curve,
          begin: Offset(begin, begin),
          end: Offset(end, end),
        );
  }

  /// Complex entrance animation combining multiple effects
  static Widget entranceAnimation({
    required Widget child,
    Duration delay = Duration.zero,
    AnimationDirection direction = AnimationDirection.fromBottom,
  }) {
    switch (direction) {
      case AnimationDirection.fromBottom:
        return slideInFromBottom(
          child: child,
          delay: delay,
          duration: mediumDuration,
        );
      case AnimationDirection.fromTop:
        return slideInFromTop(
          child: child,
          delay: delay,
          duration: mediumDuration,
        );
      case AnimationDirection.fromLeft:
        return slideInFromLeft(
          child: child,
          delay: delay,
          duration: mediumDuration,
        );
      case AnimationDirection.fromRight:
        return slideInFromRight(
          child: child,
          delay: delay,
          duration: mediumDuration,
        );
      case AnimationDirection.scale:
        return scaleIn(
          child: child,
          delay: delay,
          duration: mediumDuration,
        );
      case AnimationDirection.fade:
        return fadeIn(
          child: child,
          delay: delay,
          duration: mediumDuration,
        );
    }
  }

  /// Staggered list animation for multiple items
  static List<Widget> staggeredList({
    required List<Widget> children,
    Duration staggerDelay = mediumDelay,
    Duration animationDuration = mediumDuration,
    AnimationDirection direction = AnimationDirection.fromBottom,
  }) {
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      final delay = staggerDelay * index;
      
      return entranceAnimation(
        child: child,
        delay: delay,
        direction: direction,
      );
    }).toList();
  }

  /// Button press animation
  static Widget buttonPress({
    required Widget child,
    Duration duration = const Duration(milliseconds: 100),
    double scale = 0.95,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        // Scale down animation would be handled by AnimatedScale or similar
      },
      onTapUp: (_) {
        // Scale up animation would be handled by AnimatedScale or similar
        onTap?.call();
      },
      onTapCancel: () {
        // Reset scale animation
      },
      child: child
          .animate()
          .scale(
            duration: duration,
            curve: Curves.easeInOut,
          ),
    );
  }

  /// Attention animation for important elements
  static Widget attention({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    Duration delay = Duration.zero,
  }) {
    return child
        .animate(delay: delay, onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          duration: duration,
          curve: Curves.easeInOut,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
        );
  }

  /// Loading dots animation
  static Widget loadingDots({
    Duration duration = const Duration(milliseconds: 1200),
    Color color = Colors.grey,
    double size = 8.0,
    int dotCount = 3,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(dotCount, (index) {
        return Container(
          width: size,
          height: size,
          margin: EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(
              duration: duration,
              delay: Duration(milliseconds: index * 200),
              curve: Curves.easeInOut,
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
            )
            .then()
            .scale(
              duration: duration,
              curve: Curves.easeInOut,
              begin: const Offset(1.0, 1.0),
              end: const Offset(0.5, 0.5),
            );
      }),
    );
  }

  /// Pulse animation for notifications
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minOpacity = 0.3,
    double maxOpacity = 1.0,
  }) {
    return child
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(
          duration: duration,
          curve: Curves.easeInOut,
          begin: minOpacity,
          end: maxOpacity,
        );
  }

  /// Wave animation for decorative elements
  static Widget wave({
    required Widget child,
    Duration duration = const Duration(milliseconds: 2000),
    double amplitude = 10.0,
  }) {
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .custom(
          duration: duration,
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, amplitude * (value * 2 - 1)),
              child: child,
            );
          },
        );
  }

  /// Success animation with check mark effect
  static Widget success({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
  }) {
    return child
        .animate(delay: delay)
        .scale(
          duration: duration * 0.6,
          curve: Curves.elasticOut,
          begin: const Offset(0.0, 0.0),
          end: const Offset(1.2, 1.2),
        )
        .then()
        .scale(
          duration: duration * 0.4,
          curve: Curves.easeOut,
          begin: const Offset(1.2, 1.2),
          end: const Offset(1.0, 1.0),
        );
  }

  /// Error animation with shake and color change
  static Widget error({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
    Color errorColor = Colors.red,
  }) {
    return child
        .animate(delay: delay)
        .shake(
          duration: duration,
          offset: const Offset(5, 0),
        )
        .tint(
          duration: duration,
          color: errorColor,
        );
  }

  /// Card flip animation for revealing content
  static Widget cardFlip({
    required Widget frontChild,
    required Widget backChild,
    required bool showFront,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        final rotate = Tween(begin: 0.0, end: 1.0).animate(animation);
        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (context, child) {
            final isShowingFront = rotate.value < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(rotate.value * 3.14159),
              child: isShowingFront ? frontChild : Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(3.14159),
                child: backChild,
              ),
            );
          },
        );
      },
      child: showFront ? frontChild : backChild,
    );
  }
}

/// Page transition animations using the animations package
class PageTransitions {
  
  /// Shared axis transition (recommended for navigation between peer pages)
  static Widget sharedAxisTransition({
    required Widget child,
    required Animation<double> animation,
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
  }) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: const AlwaysStoppedAnimation(0.0),
      transitionType: transitionType,
      child: child,
    );
  }

  /// Fade through transition (good for bottom navigation)
  static Widget fadeThroughTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeThroughTransition(
      animation: animation,
      secondaryAnimation: const AlwaysStoppedAnimation(0.0),
      child: child,
    );
  }

  /// Container transform (perfect for expanding cards)
  static Widget containerTransform({
    required Widget openChild,
    required Widget closedChild,
    required bool isOpen,
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    return OpenContainer(
      transitionDuration: transitionDuration,
      openBuilder: (context, action) => openChild,
      closedBuilder: (context, action) => closedChild,
      tappable: false,
    );
  }
}

/// Enum for animation directions
enum AnimationDirection {
  fromBottom,
  fromTop,
  fromLeft,
  fromRight,
  scale,
  fade,
}

/// Preset animation configurations
class AnimationPresets {
  static const fastFadeIn = Duration(milliseconds: 150);
  static const mediumSlideIn = Duration(milliseconds: 300);
  static const slowElastic = Duration(milliseconds: 800);
  
  // Stagger delays
  static const quickStagger = Duration(milliseconds: 50);
  static const normalStagger = Duration(milliseconds: 100);
  static const slowStagger = Duration(milliseconds: 200);
}
