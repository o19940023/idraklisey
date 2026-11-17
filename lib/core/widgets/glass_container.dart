import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// iPhone-style glassmorphism container
/// Uses BackdropFilter for real blur effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 20,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.5,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: boxShadow ??
              [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1,
                  ),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.glassHighlight.withValues(alpha: 0.08),
                    palette.glassHighlight.withValues(alpha: 0.0),
                  ],
                ),
                color: backgroundColor ?? palette.glassTint,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor ?? palette.glassBorder,
                  width: borderWidth,
                ),
              ),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Glassmorphism modal bottom sheet
class GlassModalSheet extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;

  const GlassModalSheet({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.blur = 20,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final underside = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.7);

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: -10,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadius),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              decoration: BoxDecoration(
                color: Color.alphaBlend(underside, palette.glassTint),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(borderRadius),
                ),
                border: Border(
                  top: BorderSide(
                    color: palette.glassBorder,
                    width: 1.5,
                  ),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
