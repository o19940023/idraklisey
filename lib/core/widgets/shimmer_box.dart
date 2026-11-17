import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_palette.dart';

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final base = baseColor ?? palette.borderHairline;
    final highlight =
        highlightColor ?? palette.brandRoyal.withValues(alpha: 0.18);

    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) return box;

    return box
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: highlight);
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final double spacing;

  const ShimmerList({
    super.key,
    this.count = 3,
    this.itemHeight = 88,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          ShimmerBox(height: itemHeight, borderRadius: 16),
        ],
      ],
    );
  }
}
