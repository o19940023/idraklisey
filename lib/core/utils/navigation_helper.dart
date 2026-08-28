import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../../data/models/user_preferences_model.dart';

/// Convert ModuleItem to AdaptiveNavigationDestination
class NavigationHelper {
  static List<AdaptiveNavigationDestination> toAdaptiveDestinations(
    List<ModuleItem> items,
  ) {
    return items.map((item) {
      // Extract SF Symbol from icon string (if it contains 'outlined' or 'rounded')
      String sfSymbol = _extractSFSymbol(item.icon);
      
      return AdaptiveNavigationDestination(
        icon: sfSymbol,
        label: item.label,
      );
    }).toList();
  }

  /// Extract SF Symbol name from Flutter icon string
  static String _extractSFSymbol(String iconName) {
    // Map common icon names to SF Symbols
    final iconMap = {
      'dashboard': 'square.grid.2x2',
      'manage_accounts': 'person.2',
      'support_agent': 'headphones',
      'analytics': 'chart.bar',
      'grid_view': 'square.grid.3x3',
      'insights': 'chart.line.uptrend.xyaxis',
      'calendar_month': 'calendar',
      'favorite': 'heart.fill',
      'badge': 'person.badge.shield.checkmark',
      'assignment': 'doc.text',
      'video_camera_front': 'video',
      'local_library': 'books.vertical',
      'groups': 'person.3',
      'edit_note': 'pencil.and.list.clipboard',
      'qr_code_scanner': 'qrcode.viewfinder',
      'school': 'graduationcap',
      'class': 'book',
      'admin_panel_settings': 'gearshape.2',
      'restaurant_menu': 'fork.knife',
      'campaign': 'megaphone',
      'mic': 'mic',
      'notifications': 'bell',
      'assignment_turned_in': 'checkmark.circle',
    };

    // Remove '_outlined' or '_rounded' suffix
    String cleanName = iconName
        .replaceAll('_outlined', '')
        .replaceAll('_rounded', '')
        .trim();

    return iconMap[cleanName] ?? 'circle';
  }
}
