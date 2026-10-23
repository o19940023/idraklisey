import 'package:flutter/material.dart';

/// App color palette — İdrak Liseyi identity (brand: mavi + sarı).
///
/// Deep navy base (mirrors the digital ID card), royal-blue accent,
/// gold reserved for prestige moments, and a blue→azure duotone as the
/// signature gradient.
class AppColors {
  // Primary Deep Navy Brand Colors (logo: blue & gold)
  static const Color primary = Color(0xFF0B1B33);
  static const Color primaryDark = Color(0xFF060F1F);
  static const Color primaryLight = Color(0xFF24406B);
  static const Color primaryAccent = Color(0xFF2563EB); // Royal blue

  // Signature duotone partner of the blue accent (azure)
  static const Color azure = Color(0xFF38BDF8);

  // Gold / Amber Luxury Accents (logo yellow)
  static const Color gold = Color(0xFFF5B301);
  static const Color goldLight = Color(0xFFFCC201);
  static const Color goldDark = Color(0xFFB8860B);

  // Elevated neutral tiers for 2026 layering system
  static const Color darkSurface2 = Color(0xFF161924);
  static const Color darkSurface3 = Color(0xFF1D2130);
  static const Color lightSurface2 = Color(0xFFF8F9FE);
  static const Color lightSurface3 = Color(0xFFEFF0F9);
  static const Color lightBorderStrong = Color(0xFFD0D3E4);
  static const Color darkBorderStrong = Color(0xFF343A52);

  // Status Colors (Soft, refined variants)
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Dark container tonal variants
  static const Color successContainerDark = Color(0xFF0B2F22);
  static const Color warningContainerDark = Color(0xFF332506);
  static const Color dangerContainerDark = Color(0xFF3B1215);
  static const Color infoContainerDark = Color(0xFF0F2447);

  // Dark palette (OLED Pure Black & WCAG AA Compliance)
  static const Color darkBackground = Color(0xFF000000); // Pure OLED Black
  static const Color darkSurface = Color(0xFF0F1118); // Elevated OLED Surface
  static const Color darkCard = Color(0xFF161924); // Card Container
  static const Color darkBorder = Color(0xFF262B3D); // High Contrast Border

  // Light palette
  static const Color lightBackground = Color(0xFFF2F3FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE6E7F2);
  static const Color lightTextPrimary = Color(0xFF12152A);
  static const Color lightTextSecondary = Color(0xFF676A87);
  static const Color lightTextMuted = Color(0xFF9A9EB9);

  // WCAG AA compliant text contrast (>4.5:1 ratio on OLED Black & Surfaces)
  static const Color darkTextPrimary = Color(0xFFFAFBFD); // 19.8:1 contrast
  static const Color darkTextSecondary = Color(0xFFB4B9D2); // 9.2:1 contrast (WCAG AA+)
  static const Color darkTextMuted = Color(0xFF888EA8); // 5.5:1 contrast (WCAG AA)

  static Color background = lightBackground;
  static Color surface = lightSurface;
  static Color surfaceElevated = lightSurface2;
  static Color cardBorder = lightBorder;

  // Text
  static Color textPrimary = lightTextPrimary;
  static Color textSecondary = lightTextSecondary;
  static Color textMuted = lightTextMuted;
  static Color get textTertiary => textMuted;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Swaps adaptive colors according to active theme mode.
  static void applyDark(bool dark) {
    if (dark) {
      background = darkBackground;
      surface = darkSurface;
      surfaceElevated = darkCard;
      cardBorder = darkBorder;
      textPrimary = darkTextPrimary;
      textSecondary = darkTextSecondary;
      textMuted = darkTextMuted;
    } else {
      background = lightBackground;
      surface = lightSurface;
      surfaceElevated = lightSurface2;
      cardBorder = lightBorder;
      textPrimary = lightTextPrimary;
      textSecondary = lightTextSecondary;
      textMuted = lightTextMuted;
    }
  }

  /// True when adaptive statics currently hold the dark palette.
  static bool get isDarkMode => background == darkBackground;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1B33), Color(0xFF24406B)],
  );

  /// Signature duotone: royal blue → azure.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
  );

  /// Deep hero gradient for headers (navy → royal blue).
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF081326), Color(0xFF123B7A), Color(0xFF2563EB)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8860B), Color(0xFFF5B301)],
  );

  static LinearGradient get cardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [surface, background],
      );

  /// Soft duotone tint of any accent (for icon badges, chips).
  static List<Color> duoTint(Color c) => [c.withAlpha(38), azure.withAlpha(20)];
}
