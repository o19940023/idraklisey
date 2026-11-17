import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable school photo background with smooth deep blue gradient overlay
/// used across all dashboard heroes (Admin, Staff, Teacher, Student, Parent).
class SchoolHeroBackground extends StatelessWidget {
  final Widget? child;
  final BorderRadiusGeometry borderRadius;
  final Color accentColor;
  final double? height;

  const SchoolHeroBackground({
    super.key,
    this.child,
    this.borderRadius = const BorderRadius.vertical(bottom: Radius.circular(28)),
    this.accentColor = AppColors.primaryAccent,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF07122A),
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. School Photo (İdrak Liseyi building)
            Image.asset(
              'assets/images/idrak_school_bg.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.32),
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A1428),
                        Color(0xFF101D36),
                        Color(0xFF172554),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 2. Multi-stop Smooth Blue Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF020617).withValues(alpha: 0.72), // Deep at status bar for high contrast
                    const Color(0xFF0A1E4A).withValues(alpha: 0.52), // Translucent to highlight the building & sign
                    const Color(0xFF0E3278).withValues(alpha: 0.72), // Rich Idrak blue transition
                    const Color(0xFF071B42).withValues(alpha: 0.95), // Smooth dark blue blend at the bottom curve
                  ],
                  stops: const [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),

            // 3. Subtle horizontal blue tint
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0284C7).withValues(alpha: 0.16),
                    Colors.transparent,
                    const Color(0xFF1E40AF).withValues(alpha: 0.28),
                  ],
                ),
              ),
            ),

            // 4. Ambient Radial Glow (Bottom right wave accent)
            Positioned(
              right: -30,
              bottom: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: 0.35),
                      const Color(0xFF0284C7).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 5. Subtle Top-Left Accent Glow
            Positioned(
              left: -40,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 6. Child Content (Header elements)
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}
