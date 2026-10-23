import 'package:flutter/material.dart';

import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import 'motion.dart';
import '../theme/app_palette.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? trend;
  final bool? trendUp;
  final bool compact;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color = const Color(0xFF2563EB),
    this.onTap,
    this.trend,
    this.trendUp,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    Widget card = Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline, width: 1),
        boxShadow: AppShadows.adaptiveCard(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (trend != null) ...[
                const Spacer(),
                _TrendChip(trend: trend!, trendUp: trendUp),
              ],
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppTypography.metricSm(context)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption1(context).copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    card = PressableScale(
      pressedScale: 0.97,
      enabled: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          highlightColor: palette.brandRoyal.withValues(alpha: 0.06),
          child: card,
        ),
      ),
    );

    return card;
  }
}

class _TrendChip extends StatelessWidget {
  final String trend;
  final bool? trendUp;

  const _TrendChip({required this.trend, this.trendUp});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final up = trendUp ?? true;
    final color = up ? const Color(0xFF10B981) : colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              trend,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCardRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final int? columns;

  const StatCardRow({
    super.key,
    required this.children,
    this.spacing = 12,
    this.columns,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final resolvedColumns = columns ??
            (maxWidth >= 600
                ? 3
                : (children.length == 3 ? 3 : 2));
        final count = resolvedColumns.clamp(1, children.length);
        final gaps = spacing * (count - 1);
        final itemWidth = (maxWidth - gaps) / count;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}
