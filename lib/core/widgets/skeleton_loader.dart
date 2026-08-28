import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Skeleton loading widget with shimmer effect
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 20,
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

/// Dashboard skeleton loading
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              const SkeletonLoader(width: 60, height: 60, borderRadius: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader(width: 120, height: 16),
                    SizedBox(height: 8),
                    SkeletonLoader(width: 180, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Metric cards skeleton
          Row(
            children: const [
              Expanded(child: SkeletonLoader(height: 80, borderRadius: 16)),
              SizedBox(width: 10),
              Expanded(child: SkeletonLoader(height: 80, borderRadius: 16)),
              SizedBox(width: 10),
              Expanded(child: SkeletonLoader(height: 80, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 16),

          // Large card skeleton
          const SkeletonLoader(width: double.infinity, height: 150, borderRadius: 20),
          const SizedBox(height: 16),

          // List items skeleton
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const SkeletonLoader(
                width: double.infinity,
                height: 70,
                borderRadius: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
