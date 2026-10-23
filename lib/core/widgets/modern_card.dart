import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_palette.dart';
import 'motion.dart';

/// Modern 2026-style card component with consistent styling.
///
/// Provides a clean, elevated surface with proper spacing and shadows.
/// Adapts automatically to light/dark themes.
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final bool elevated;
  final BorderRadiusGeometry? borderRadius;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.elevated = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final effectiveRadius = borderRadius ?? AppRadius.cardRadius;

    final Widget cardContent = Container(
      padding: padding ?? EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color ?? palette.surface1,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: palette.borderHairline,
          width: 1,
        ),
        boxShadow: elevated ? AppShadows.adaptiveCard(context) : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin ?? EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: PressableScale(
          pressedScale: 0.985,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: effectiveRadius is BorderRadius ? effectiveRadius : null,
              highlightColor: palette.brandRoyal.withValues(alpha: 0.06),
              child: cardContent,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: cardContent,
    );
  }
}

/// Compact card variant for list items.
class CompactCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const CompactCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: padding ?? EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      margin: margin ?? EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      onTap: onTap,
      child: child,
    );
  }
}
