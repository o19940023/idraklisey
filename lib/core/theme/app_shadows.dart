import 'package:flutter/material.dart';

/// Centralized shadow system for subtle elevation and depth.
///
/// Provides consistent shadow definitions that work well in both
/// light and dark themes, following 2026 design principles of
/// subtle rather than aggressive depth cues.
class AppShadows {
  // Subtle elevation shadows (light theme optimized, faint violet tint
  // for a softer, more premium depth)
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x120E1230), // ~7% navy
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x160E1230), // ~9% navy
      blurRadius: 14,
      offset: Offset(0, 5),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1A0E1230), // ~10% navy
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x240E1230), // ~14% navy
      blurRadius: 34,
      offset: Offset(0, 14),
      spreadRadius: 0,
    ),
  ];

  // Card shadows
  static const List<BoxShadow> card = md;
  static const List<BoxShadow> cardHover = lg;

  // Button shadows
  static const List<BoxShadow> button = sm;

  // Dialog/modal shadows
  static const List<BoxShadow> modal = xl;

  // Dark theme shadows (more subtle)
  static const List<BoxShadow> darkSm = [
    BoxShadow(
      color: Color(0x1A000000), // 10% black (darker for dark mode)
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> darkMd = [
    BoxShadow(
      color: Color(0x29000000), // 16% black
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
}
