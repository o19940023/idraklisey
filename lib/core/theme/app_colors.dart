import 'package:flutter/material.dart';

/// App color palette — Modern 2026 Material 3 Design System.
///
/// Brand colors:
/// - Primary: #1A1B2E (Deep Onyx / Midnight Navy)
/// - Accent: #6C5CE7 (Vibrant Purple / Indigo)
/// - Background: #F7F7FB (Ultra Clean M3 Light) / #0E0F19 (Sleek Dark)
/// - Surface: #FFFFFF / #161827
class AppColors {
  // Primary Onyx / Midnight Brand Colors
  static const Color primary = Color(0xFF1A1B2E);
  static const Color primaryDark = Color(0xFF111220);
  static const Color primaryLight = Color(0xFF2E304F);
  static const Color primaryAccent = Color(0xFF6C5CE7); // Modern Purple/Indigo

  // Gold / Amber Luxury Accents
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFBBF24);
  static const Color goldDark = Color(0xFFD97706);

  // Status Colors (Soft, refined M3 variants)
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Dark palette (OLED Pure Black #000000 & WCAG AA Compliance)
  static const Color darkBackground = Color(0xFF000000); // Pure OLED Black
  static const Color darkSurface = Color(0xFF0F1118); // Elevated OLED Surface
  static const Color darkCard = Color(0xFF161924); // Card Container
  static const Color darkBorder = Color(0xFF262B3D); // High Contrast Border

  // Light palette
  static const Color _lightBackground = Color(0xFFF7F7FB);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightCardBorder = Color(0xFFE8E8F0);
  static const Color _lightTextPrimary = Color(0xFF1A1B2E);
  static const Color _lightTextSecondary = Color(0xFF6B6E8A);
  static const Color _lightTextMuted = Color(0xFF9EA2BD);

  // WCAG AA compliant text contrast (>4.5:1 ratio on OLED Black & Surfaces)
  static const Color _darkTextPrimary = Color(0xFFFAFBFD); // 19.8:1 contrast
  static const Color _darkTextSecondary = Color(0xFFB4B9D2); // 9.2:1 contrast (WCAG AA+)
  static const Color _darkTextMuted = Color(0xFF888EA8); // 5.5:1 contrast (WCAG AA)

  static Color background = _lightBackground;
  static Color surface = _lightSurface;
  static Color surfaceElevated = _lightSurface;
  static Color cardBorder = _lightCardBorder;

  // Text
  static Color textPrimary = _lightTextPrimary;
  static Color textSecondary = _lightTextSecondary;
  static Color textMuted = _lightTextMuted;
  static Color get textTertiary => textMuted;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Swaps adaptive colors according to active theme mode.
  static void applyDark(bool dark) {
    if (dark) {
      background = darkBackground;
      surface = darkSurface;
      surfaceElevated = darkCard;
      cardBorder = darkBorder;
      textPrimary = _darkTextPrimary;
      textSecondary = _darkTextSecondary;
      textMuted = _darkTextMuted;
    } else {
      background = _lightBackground;
      surface = _lightSurface;
      surfaceElevated = _lightSurface;
      cardBorder = _lightCardBorder;
      textPrimary = _lightTextPrimary;
      textSecondary = _lightTextSecondary;
      textMuted = _lightTextMuted;
    }
  }

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1B2E), Color(0xFF2E304F)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFF8070F6)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
  );

  static LinearGradient get cardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [surface, background],
      );
}
