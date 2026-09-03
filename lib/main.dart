import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_state.dart';
import 'services/app_update_service.dart';
import 'services/push_notification_service.dart';
import 'modules/auth/screens/video_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Restore appearance before the first frame so the correct palette
  // is applied from the very first splash.
  final appState = AppState();
  await appState.loadThemeMode();
  appState.initFirebaseData();

  // Push bildirişləri (tətbiq bağlı ikən də gəlməsi üçün) — arxa planda
  unawaited(PushNotificationService.instance.initialize());

  // Yeni versiya yoxlaması (banner üçün) — arxa planda, gecikmə yaratmır
  final appUpdateService = AppUpdateService();
  unawaited(Future.delayed(const Duration(seconds: 3), () {
    appUpdateService.checkForUpdate();
  }));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: appUpdateService),
      ],
      child: const IdrakLiseyiApp(),
    ),
  );
}

class IdrakLiseyiApp extends StatelessWidget {
  const IdrakLiseyiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'İdrak Liseyi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const VideoSplashScreen(),
    );
  }
}
