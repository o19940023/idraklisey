import 'package:flutter/material.dart';

/// Semantic 2026 design tokens exposed as a [ThemeExtension].
///
/// Carries brand, status-container, glass and surface-tier roles that do not
/// fit `ColorScheme` but must still resolve per-brightness in widgets via
/// [AppPalette.of].
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.textMuted,
    required this.brandNavy,
    required this.brandRoyal,
    required this.brandAzure,
    required this.brandGold,
    required this.successContainer,
    required this.warningContainer,
    required this.dangerContainer,
    required this.infoContainer,
    required this.glassTint,
    required this.glassBorder,
    required this.glassHighlight,
    required this.bgBase,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.borderHairline,
    required this.borderStrong,
  });

  // Light fixtures
  static const Color _lTextMuted = Color(0xFF9A9EB9);
  static const Color _lNavy = Color(0xFF0B1B33);
  static const Color _lRoyal = Color(0xFF2563EB);
  static const Color _lAzure = Color(0xFF38BDF8);
  static const Color _lGold = Color(0xFFF5B301);
  static const Color _lSuccessContainer = Color(0xFFD1FAE5);
  static const Color _lWarningContainer = Color(0xFFFEF3C7);
  static const Color _lDangerContainer = Color(0xFFFEE2E2);
  static const Color _lInfoContainer = Color(0xFFDBEAFE);
  static const Color _lGlassTint = Color(0x26FFFFFF);
  static const Color _lGlassBorder = Color(0x4DFFFFFF);
  static const Color _lGlassHighlight = Color(0xD9FFFFFF);
  static const Color _lBgBase = Color(0xFFF2F3FA);
  static const Color _lSurface1 = Color(0xFFFFFFFF);
  static const Color _lSurface2 = Color(0xFFF8F9FE);
  static const Color _lSurface3 = Color(0xFFEFF0F9);
  static const Color _lBorderHairline = Color(0xFFE6E7F2);
  static const Color _lBorderStrong = Color(0xFFD0D3E4);

  // Dark fixtures
  static const Color _dTextMuted = Color(0xFF888EA8);
  static const Color _dNavy = Color(0xFF0B1B33);
  static const Color _dRoyal = Color(0xFF3B82F6);
  static const Color _dAzure = Color(0xFF38BDF8);
  static const Color _dGold = Color(0xFFFCC201);
  static const Color _dSuccessContainer = Color(0xFF0B2F22);
  static const Color _dWarningContainer = Color(0xFF332506);
  static const Color _dDangerContainer = Color(0xFF3B1215);
  static const Color _dInfoContainer = Color(0xFF0F2447);
  static const Color _dGlassTint = Color(0xB80F1118);
  static const Color _dGlassBorder = Color(0x1AFFFFFF);
  static const Color _dGlassHighlight = Color(0x59FFFFFF);
  static const Color _dBgBase = Color(0xFF000000);
  static const Color _dSurface1 = Color(0xFF0F1118);
  static const Color _dSurface2 = Color(0xFF161924);
  static const Color _dSurface3 = Color(0xFF1D2130);
  static const Color _dBorderHairline = Color(0xFF262B3D);
  static const Color _dBorderStrong = Color(0xFF343A52);

  const AppPalette.light()
      : textMuted = _lTextMuted,
        brandNavy = _lNavy,
        brandRoyal = _lRoyal,
        brandAzure = _lAzure,
        brandGold = _lGold,
        successContainer = _lSuccessContainer,
        warningContainer = _lWarningContainer,
        dangerContainer = _lDangerContainer,
        infoContainer = _lInfoContainer,
        glassTint = _lGlassTint,
        glassBorder = _lGlassBorder,
        glassHighlight = _lGlassHighlight,
        bgBase = _lBgBase,
        surface1 = _lSurface1,
        surface2 = _lSurface2,
        surface3 = _lSurface3,
        borderHairline = _lBorderHairline,
        borderStrong = _lBorderStrong;

  const AppPalette.dark()
      : textMuted = _dTextMuted,
        brandNavy = _dNavy,
        brandRoyal = _dRoyal,
        brandAzure = _dAzure,
        brandGold = _dGold,
        successContainer = _dSuccessContainer,
        warningContainer = _dWarningContainer,
        dangerContainer = _dDangerContainer,
        infoContainer = _dInfoContainer,
        glassTint = _dGlassTint,
        glassBorder = _dGlassBorder,
        glassHighlight = _dGlassHighlight,
        bgBase = _dBgBase,
        surface1 = _dSurface1,
        surface2 = _dSurface2,
        surface3 = _dSurface3,
        borderHairline = _dBorderHairline,
        borderStrong = _dBorderStrong;

  final Color textMuted;
  final Color brandNavy;
  final Color brandRoyal;
  final Color brandAzure;
  final Color brandGold;
  final Color successContainer;
  final Color warningContainer;
  final Color dangerContainer;
  final Color infoContainer;
  final Color glassTint;
  final Color glassBorder;
  final Color glassHighlight;
  final Color bgBase;
  final Color surface1;
  final Color surface2;
  final Color surface3;
  final Color borderHairline;
  final Color borderStrong;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? AppPalette.light();

  @override
  AppPalette copyWith({
    Color? textMuted,
    Color? brandNavy,
    Color? brandRoyal,
    Color? brandAzure,
    Color? brandGold,
    Color? successContainer,
    Color? warningContainer,
    Color? dangerContainer,
    Color? infoContainer,
    Color? glassTint,
    Color? glassBorder,
    Color? glassHighlight,
    Color? bgBase,
    Color? surface1,
    Color? surface2,
    Color? surface3,
    Color? borderHairline,
    Color? borderStrong,
  }) {
    return AppPalette(
      textMuted: textMuted ?? this.textMuted,
      brandNavy: brandNavy ?? this.brandNavy,
      brandRoyal: brandRoyal ?? this.brandRoyal,
      brandAzure: brandAzure ?? this.brandAzure,
      brandGold: brandGold ?? this.brandGold,
      successContainer: successContainer ?? this.successContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      glassTint: glassTint ?? this.glassTint,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      bgBase: bgBase ?? this.bgBase,
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      borderHairline: borderHairline ?? this.borderHairline,
      borderStrong: borderStrong ?? this.borderStrong,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      brandNavy: Color.lerp(brandNavy, other.brandNavy, t)!,
      brandRoyal: Color.lerp(brandRoyal, other.brandRoyal, t)!,
      brandAzure: Color.lerp(brandAzure, other.brandAzure, t)!,
      brandGold: Color.lerp(brandGold, other.brandGold, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      borderHairline: Color.lerp(borderHairline, other.borderHairline, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPalette &&
          runtimeType == other.runtimeType &&
          textMuted == other.textMuted &&
          brandNavy == other.brandNavy &&
          brandRoyal == other.brandRoyal &&
          brandAzure == other.brandAzure &&
          brandGold == other.brandGold &&
          successContainer == other.successContainer &&
          warningContainer == other.warningContainer &&
          dangerContainer == other.dangerContainer &&
          infoContainer == other.infoContainer &&
          glassTint == other.glassTint &&
          glassBorder == other.glassBorder &&
          glassHighlight == other.glassHighlight &&
          bgBase == other.bgBase &&
          surface1 == other.surface1 &&
          surface2 == other.surface2 &&
          surface3 == other.surface3 &&
          borderHairline == other.borderHairline &&
          borderStrong == other.borderStrong;

  @override
  int get hashCode => Object.hash(
        textMuted,
        brandNavy,
        brandRoyal,
        brandAzure,
        brandGold,
        successContainer,
        warningContainer,
        dangerContainer,
        infoContainer,
        glassTint,
        glassBorder,
        glassHighlight,
        bgBase,
        surface1,
        surface2,
        surface3,
        borderHairline,
        borderStrong,
      );
}
