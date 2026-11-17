import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:idrak_liseyi/core/session/session_controller.dart';
import 'package:idrak_liseyi/modules/shared/widgets/dashboard_kit.dart';
import 'package:idrak_liseyi/modules/shared/widgets/school_hero_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SchoolHeroBackground Tests', () {
    testWidgets('renders background and child content cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SchoolHeroBackground(
              height: 240,
              child: Center(
                child: Text('Test Header Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Test Header Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DashboardHeroSliver renders all branding and user elements with 0 overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844); // Standard iPhone screen
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = SessionController();

      await tester.pumpWidget(
        ChangeNotifierProvider<SessionController>.value(
          value: session,
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  DashboardHeroSliver(
                    badge: 'SUPER ADMIN',
                    title: 'Super Admin',
                    subtitle: 'superadmin@idrak.edu.az',
                    photoUrl: null,
                    avatarName: 'Super Admin',
                    gradient: const [Color(0xFF071A2B), Color(0xFF0E7490)],
                    accentColor: const Color(0xFF0284C7),
                    watermarkIcon: Icons.admin_panel_settings_rounded,
                    isOnline: true,
                    notificationCount: 3,
                    onNotifications: () {},
                    onSettings: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('İDRAK LİSEYİ'), findsOneWidget);
      expect(find.text('Super Admin'), findsOneWidget);
      expect(find.text('superadmin@idrak.edu.az'), findsOneWidget);
      expect(find.text('Onlayn'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('DashboardHeroSliver renders on narrow 360px screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = SessionController();

      await tester.pumpWidget(
        ChangeNotifierProvider<SessionController>.value(
          value: session,
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  DashboardHeroSliver(
                    badge: 'MÜƏLLİM',
                    title: 'Müəllim Paneli',
                    subtitle: 'Riyaziyyat müəllimi • Bakı filialı',
                    photoUrl: null,
                    avatarName: 'Aytən Məmmədova',
                    gradient: const [Color(0xFF0F172A), Color(0xFF141724)],
                    accentColor: const Color(0xFFF59E0B),
                    watermarkIcon: Icons.psychology_rounded,
                    isOnline: true,
                    notificationCount: 0,
                    onNotifications: () {},
                    onSettings: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('İDRAK LİSEYİ'), findsOneWidget);
      expect(find.text('Müəllim Paneli'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
