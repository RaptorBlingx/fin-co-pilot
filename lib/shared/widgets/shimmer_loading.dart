import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// THEME-AWARE SHIMMER BASE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// A single shimmer rectangle that adapts to the current theme.
/// Uses primary-tinted gradient instead of flat grey.
class ShimmerLoading extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = DesignTokens.radiusSM,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Shimmer.fromColors(
      baseColor: isDark
          ? AppTheme.darkSurfaceContainer
          : AppTheme.slate200,
      highlightColor: isDark
          ? primary.withOpacity(0.08)
          : primary.withOpacity(0.06),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SKELETON SHAPES — match real widget shapes
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Matches the hero spending card on the dashboard.
class HeroCardSkeleton extends StatelessWidget {
  const HeroCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonWrapper(
      child: Padding(
        padding: DesignTokens.cardPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month label
            const ShimmerLoading(width: 80, height: 14, borderRadius: DesignTokens.radiusXS),
            const SizedBox(height: DesignTokens.space12),
            // Big amount
            const ShimmerLoading(width: 180, height: 36, borderRadius: DesignTokens.radiusSM),
            const SizedBox(height: DesignTokens.space16),
            // Progress bar
            ShimmerLoading(
              width: double.infinity,
              height: 8,
              borderRadius: DesignTokens.radiusFull,
            ),
            const SizedBox(height: DesignTokens.space12),
            // Subtitle row
            Row(
              children: const [
                ShimmerLoading(width: 100, height: 12, borderRadius: DesignTokens.radiusXS),
                Spacer(),
                ShimmerLoading(width: 60, height: 12, borderRadius: DesignTokens.radiusXS),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Matches a transaction list tile.
class TransactionTileSkeleton extends StatelessWidget {
  const TransactionTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.screenPadding,
        vertical: DesignTokens.space6,
      ),
      child: Row(
        children: [
          // Category icon circle
          const ShimmerLoading(
            width: DesignTokens.avatarMD,
            height: DesignTokens.avatarMD,
            borderRadius: DesignTokens.radiusFull,
          ),
          const SizedBox(width: DesignTokens.space12),
          // Text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerLoading(width: 140, height: 14, borderRadius: DesignTokens.radiusXS),
                SizedBox(height: DesignTokens.space6),
                ShimmerLoading(width: 90, height: 12, borderRadius: DesignTokens.radiusXS),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          // Amount
          const ShimmerLoading(width: 64, height: 16, borderRadius: DesignTokens.radiusXS),
        ],
      ),
    );
  }
}

/// Skeleton list of transaction tiles.
class TransactionListSkeleton extends StatelessWidget {
  final int itemCount;

  const TransactionListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      itemBuilder: (_, __) => const TransactionTileSkeleton(),
    );
  }
}

/// Chat bubble skeleton rows (alternating left/right).
class ChatBubbleSkeleton extends StatelessWidget {
  final bool isUser;

  const ChatBubbleSkeleton({super.key, this.isUser = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isUser ? 64 : DesignTokens.screenPadding,
          right: isUser ? DesignTokens.screenPadding : 64,
          bottom: DesignTokens.space8,
        ),
        child: ShimmerLoading(
          width: double.infinity,
          height: isUser ? 40 : 72,
          borderRadius: DesignTokens.radiusLG,
        ),
      ),
    );
  }
}

/// Chat list skeleton with alternating AI/User bubbles.
class ChatListSkeleton extends StatelessWidget {
  final int count;

  const ChatListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (i) {
        return ChatBubbleSkeleton(isUser: i.isOdd);
      }),
    );
  }
}

/// Generic card skeleton.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonWrapper(
      child: Padding(
        padding: DesignTokens.cardPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerLoading(width: 120, height: 18, borderRadius: DesignTokens.radiusXS),
            SizedBox(height: DesignTokens.space16),
            ShimmerLoading(height: 14, borderRadius: DesignTokens.radiusXS),
            SizedBox(height: DesignTokens.space8),
            ShimmerLoading(width: 200, height: 14, borderRadius: DesignTokens.radiusXS),
            SizedBox(height: DesignTokens.space8),
            ShimmerLoading(width: 160, height: 14, borderRadius: DesignTokens.radiusXS),
          ],
        ),
      ),
    );
  }
}

/// Chart skeleton with bar placeholders.
class ChartSkeleton extends StatelessWidget {
  const ChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonWrapper(
      child: Padding(
        padding: DesignTokens.cardPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerLoading(width: 150, height: 18, borderRadius: DesignTokens.radiusXS),
            const SizedBox(height: DesignTokens.space24),
            SizedBox(
              height: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (i) {
                  final heights = [60.0, 100.0, 80.0, 140.0, 110.0, 70.0];
                  return ShimmerLoading(
                    width: 32,
                    height: heights[i],
                    borderRadius: DesignTokens.radiusSM,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── Helper ──────────────────────────────────────────

class _SkeletonWrapper extends StatelessWidget {
  final Widget child;
  const _SkeletonWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.screenPadding,
        vertical: DesignTokens.space6,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurfaceContainer.withOpacity(0.5)
            : Colors.white.withOpacity(0.6),
        borderRadius: DesignTokens.borderRadiusXL,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: child,
    );
  }
}
