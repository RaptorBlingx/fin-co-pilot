import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../themes/app_theme.dart';
import '../../utils/animation_utils.dart';

/// Comprehensive loading states with shimmer effects and skeleton loaders
class LoadingStates {
  
  /// Basic shimmer effect wrapper
  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration period = const Duration(milliseconds: 1500),
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      period: period,
      child: child,
    );
  }

  /// Dark theme shimmer effect
  static Widget darkShimmer({
    required Widget child,
    Duration period = const Duration(milliseconds: 1500),
  }) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2C2C2C),
      highlightColor: const Color(0xFF3C3C3C),
      period: period,
      child: child,
    );
  }
}

/// Card skeleton loader with shimmer effect
class CardSkeleton extends StatelessWidget {
  final double height;
  final bool showAvatar;
  final bool showTitle;
  final bool showSubtitle;
  final bool showActions;
  final EdgeInsets margin;
  final bool isDark;

  const CardSkeleton({
    Key? key,
    this.height = 120,
    this.showAvatar = true,
    this.showTitle = true,
    this.showSubtitle = true,
    this.showActions = false,
    this.margin = const EdgeInsets.all(AppTheme.spacingM),
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shimmerWidget = Card(
      margin: margin,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar || showTitle || showSubtitle)
              Row(
                children: [
                  if (showAvatar) ...[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showTitle) ...[
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppTheme.smallRadius,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                        ],
                        if (showSubtitle)
                          Container(
                            height: 12,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppTheme.smallRadius,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            const Spacer(),
            if (showActions)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 32,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.smallRadius,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Container(
                    height: 32,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.smallRadius,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );

    return isDark 
        ? LoadingStates.darkShimmer(child: shimmerWidget)
        : LoadingStates.shimmer(child: shimmerWidget);
  }
}

/// List skeleton loader for displaying multiple loading cards
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final bool showAvatar;
  final bool showActions;
  final bool isDark;

  const ListSkeleton({
    Key? key,
    this.itemCount = 5,
    this.itemHeight = 120,
    this.showAvatar = true,
    this.showActions = false,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return AnimationUtils.fadeIn(
          delay: Duration(milliseconds: index * 100),
          child: CardSkeleton(
            height: itemHeight,
            showAvatar: showAvatar,
            showActions: showActions,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

/// Profile skeleton loader
class ProfileSkeleton extends StatelessWidget {
  final bool isDark;
  
  const ProfileSkeleton({
    Key? key,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final skeleton = Column(
      children: [
        // Profile header
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              // Name
              Container(
                height: 20,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.smallRadius,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              // Email
              Container(
                height: 16,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.smallRadius,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        // Settings items
        ...List.generate(6, (index) => 
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppTheme.smallRadius,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.smallRadius,
                    ),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppTheme.smallRadius,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return isDark 
        ? LoadingStates.darkShimmer(child: skeleton)
        : LoadingStates.shimmer(child: skeleton);
  }
}

/// Chart skeleton loader
class ChartSkeleton extends StatelessWidget {
  final double height;
  final bool showLegend;
  final bool isDark;

  const ChartSkeleton({
    Key? key,
    this.height = 200,
    this.showLegend = true,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final skeleton = Card(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart title
            Container(
              height: 18,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.smallRadius,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Chart area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.smallRadius,
                ),
              ),
            ),
            if (showLegend) ...[
              const SizedBox(height: AppTheme.spacingM),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) => 
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppTheme.smallRadius,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Container(
                        height: 12,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppTheme.smallRadius,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return isDark 
        ? LoadingStates.darkShimmer(child: skeleton)
        : LoadingStates.shimmer(child: skeleton);
  }
}

/// Transaction list skeleton loader
class TransactionListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool isDark;

  const TransactionListSkeleton({
    Key? key,
    this.itemCount = 8,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final skeleton = Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              // Icon/Category
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.smallRadius,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppTheme.smallRadius,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    // Subtitle
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppTheme.smallRadius,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    height: 16,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.smallRadius,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Container(
                    height: 12,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.smallRadius,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        return AnimationUtils.fadeIn(
          delay: Duration(milliseconds: index * 50),
          child: isDark 
              ? LoadingStates.darkShimmer(child: skeleton)
              : LoadingStates.shimmer(child: skeleton),
        );
      },
    );
  }
}

/// Simple text skeleton for loading text content
class TextSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final int lines;
  final bool isDark;

  const TextSkeleton({
    Key? key,
    this.height = 16,
    this.width,
    this.lines = 1,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final skeleton = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) =>
        Container(
          margin: EdgeInsets.only(bottom: index < lines - 1 ? AppTheme.spacingS : 0),
          height: height,
          width: width ?? (index == lines - 1 ? 
              MediaQuery.of(context).size.width * 0.7 : 
              double.infinity),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.smallRadius,
          ),
        ),
      ),
    );

    return isDark 
        ? LoadingStates.darkShimmer(child: skeleton)
        : LoadingStates.shimmer(child: skeleton);
  }
}

/// Button skeleton loader
class ButtonSkeleton extends StatelessWidget {
  final double height;
  final double width;
  final bool isDark;

  const ButtonSkeleton({
    Key? key,
    this.height = 48,
    this.width = 120,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final skeleton = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.mediumRadius,
      ),
    );

    return isDark 
        ? LoadingStates.darkShimmer(child: skeleton)
        : LoadingStates.shimmer(child: skeleton);
  }
}

/// Custom loading indicator with animated dots
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.color,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimationUtils.loadingDots(
          color: color ?? Theme.of(context).primaryColor,
          size: size / 3,
        ),
        if (message != null) ...[
          const SizedBox(height: AppTheme.spacingM),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {  
  final String message;
  final bool showBackground;
  final Color? backgroundColor;

  const LoadingOverlay({
    Key? key,
    this.message = 'Loading...',
    this.showBackground = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: showBackground 
          ? (backgroundColor ?? Colors.black.withOpacity(0.5))
          : Colors.transparent,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(AppTheme.spacingL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            child: LoadingIndicator(message: message),
          ),
        ),
      ),
    );
  }
}