import 'package:flutter/material.dart';

import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import 'motion.dart';
import '../theme/app_palette.dart';

enum AppCardVariant { elevated, tonal, outline }

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.variant = AppCardVariant.elevated,
    this.onTap,
    this.borderRadius = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    final (Color fillColor, Color? borderColor, List<BoxShadow>? boxShadow) =
        switch (variant) {
      AppCardVariant.elevated => (
          color ?? palette.surface1,
          palette.borderHairline,
          AppShadows.adaptiveCard(context),
        ),
      AppCardVariant.tonal => (color ?? palette.surface2, null, null),
      AppCardVariant.outline => (color ?? Colors.transparent, palette.borderHairline, null),
    };

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
        boxShadow: boxShadow,
      ),
      child: child,
    );

    final card = onTap != null
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              highlightColor: palette.brandRoyal.withValues(alpha: 0.06),
              child: PressableScale(
                pressedScale: 0.985,
                child: content,
              ),
            ),
          )
        : content;

    return Padding(padding: margin, child: card);
  }
}

class AppBentoCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Color? accent;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppBentoCard({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.accent,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = accent ?? palette.brandRoyal;

    return PressableScale(
      pressedScale: 0.985,
      enabled: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          highlightColor: palette.brandRoyal.withValues(alpha: 0.06),
          child: Container(
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.borderHairline, width: 1),
              boxShadow: AppShadows.adaptiveCard(context),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title1(context),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption1(context).copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  ?trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
