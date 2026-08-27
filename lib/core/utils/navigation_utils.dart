import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

/// Həm `Navigator.push` ilə açılan səhifələrdə, həm də alt menyu tablarında (IndexedStack)
/// təhlükəsiz geri qayıtmanı idarə edir.
/// - Əgər səhifə stack-də açılıbsa (`canPop` == true) -> səhifəni bağlayır (`Navigator.pop`).
/// - Əgər səhifə alt menyunun tabıdırsa (`canPop` == false) -> qara ekran vermir, Əsas tab-a (0) qayıdır!
void handleBackNavigation(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  } else {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.resetToDashboard();
    } catch (_) {}
  }
}
