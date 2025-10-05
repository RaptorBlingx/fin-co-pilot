import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
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

// Transaction list skeleton
class TransactionListSkeleton extends StatelessWidget {
  final int itemCount;

  const TransactionListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const ShimmerLoading(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: double.infinity,
                      height: 16,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 8),
                    ShimmerLoading(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ShimmerLoading(width: 60, height: 20, borderRadius: 4),
            ],
          ),
        );
      },
    );
  }
}

// Card skeleton
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerLoading(width: 120, height: 20, borderRadius: 4),
            const SizedBox(height: 16),
            ShimmerLoading(
              width: double.infinity,
              height: 16,
              borderRadius: 4,
            ),
            const SizedBox(height: 8),
            ShimmerLoading(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 16,
              borderRadius: 4,
            ),
            const SizedBox(height: 8),
            ShimmerLoading(
              width: MediaQuery.of(context).size.width * 0.5,
              height: 16,
              borderRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

// Chart skeleton
class ChartSkeleton extends StatelessWidget {
  const ChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerLoading(width: 150, height: 20, borderRadius: 4),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                5,
                (index) => ShimmerLoading(
                  width: 40,
                  height: 100 + (index * 20).toDouble(),
                  borderRadius: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}