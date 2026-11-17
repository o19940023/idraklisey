import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:idrak_liseyi/core/session/session_controller.dart';
import 'package:idrak_liseyi/modules/navigation/widgets/gopanel_drawer.dart';
import 'package:idrak_liseyi/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GoPanelDrawer - Valideynlər is under Şagird və Valideyn group', (tester) async {
    final session = SessionController();
    session.setMockProfile(MobileProfile(
      id: 1,
      name: 'Super Admin',
      type: 'admin',
      guard: 'gopanel',
      isSuper: true,
    ));

    final appState = AppState();
    appState.syncFromSession(session);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<SessionController>.value(value: session),
        ],
        child: const MaterialApp(
          home: Scaffold(
            drawer: GoPanelDrawer(),
            body: Center(child: Text('Home')),
          ),
        ),
      ),
    );

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    // Verify "Şagird və Valideyn" group header exists
    final studentParentHeader = find.text('Şagird və Valideyn');
    expect(studentParentHeader, findsOneWidget);

    // Tap to expand "Şagird və Valideyn"
    await tester.tap(studentParentHeader);
    await tester.pumpAndSettle();

    // Both "Şagirdlər" and "Valideynlər" should now be visible under this group
    expect(find.text('Şagirdlər (360° İdarəetmə)'), findsOneWidget);
    expect(find.text('Valideynlər'), findsOneWidget);

    // Expand "E-məktəb"
    final emektebHeader = find.text('E-məktəb');
    expect(emektebHeader, findsOneWidget);
    await tester.tap(emektebHeader);
    await tester.pumpAndSettle();

    // "Valideynlər" should still only be found once (in Şagird və Valideyn, not duplicated in E-məktəb)
    expect(find.text('Valideynlər'), findsOneWidget);
    // E-məktəb first item should now be "Siniflər"
    expect(find.text('Siniflər'), findsOneWidget);
  });
}
