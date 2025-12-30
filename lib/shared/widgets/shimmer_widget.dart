import 'package:flutter/material.dart';

/// Beautiful shimmer effect for skeleton loaders
///
/// Creates a smooth, premium loading animation that moves across content.
/// Used throughout the app for loading states.
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.enabled = true,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = widget.baseColor ??
        (isDark ? Colors.grey[850]! : Colors.grey[300]!);
    final highlightColor = widget.highlightColor ??
        (isDark ? Colors.grey[800]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
              transform: _SlidingGradientTransform(slidePercent: _animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Skeleton Box - Base building block for skeleton loaders
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Skeleton Line - For text placeholders
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLine({
    super.key,
    this.width,
    this.height = 12,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(6),
    );
  }
}

/// Skeleton Circle - For avatars and icons
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton Card - Complete card skeleton
class SkeletonCard extends StatelessWidget {
  final double? height;
  final EdgeInsets padding;
  final bool showAvatar;

  const SkeletonCard({
    super.key,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.showAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: Card(
        child: Container(
          height: height,
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showAvatar) ...[
                    const SkeletonCircle(size: 40),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(width: MediaQuery.of(context).size.width * 0.4),
                        const SizedBox(height: 8),
                        SkeletonLine(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (height != null && height! > 100) ...[
                const SizedBox(height: 16),
                const SkeletonLine(height: 10),
                const SizedBox(height: 8),
                SkeletonLine(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 10,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton List - Multiple cards in a list
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets padding;
  final bool showAvatar;

  const SkeletonList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    this.showAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => SkeletonCard(
        height: itemHeight,
        showAvatar: showAvatar,
      ),
    );
  }
}

/// Hero Card Skeleton - For dashboard spending card
class HeroCardSkeleton extends StatelessWidget {
  const HeroCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.35,
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonLine(width: 100, height: 14),
              const SizedBox(height: 16),
              SkeletonLine(
                width: MediaQuery.of(context).size.width * 0.4,
                height: 32,
              ),
              const SizedBox(height: 8),
              const SkeletonLine(width: 150, height: 12),
              const Spacer(),
              SkeletonBox(
                width: double.infinity,
                height: 60,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashboard Skeleton - Complete dashboard loading state
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card
          const HeroCardSkeleton(),

          // Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ShimmerWidget(
              child: Column(
                children: [
                  SkeletonCard(height: 120),
                  const SizedBox(height: 16),
                  SkeletonCard(height: 100),
                  const SizedBox(height: 16),
                  SkeletonCard(height: 100),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Recent transactions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(
                  child: SkeletonLine(width: 150, height: 20),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          const SkeletonList(itemCount: 3, showAvatar: true),
        ],
      ),
    );
  }
}
