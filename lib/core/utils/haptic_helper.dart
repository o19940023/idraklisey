import 'package:flutter/services.dart';

/// Haptic feedback helper for iOS-style interactions
class HapticHelper {
  /// Light impact - for UI element selections
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact - for UI state changes
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for important actions
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection click - for pickers and toggles
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate - for notifications
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  /// Success pattern - light + medium
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.mediumImpact();
  }

  /// Error pattern - heavy + heavy
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
