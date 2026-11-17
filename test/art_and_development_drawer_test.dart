import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:idrak_liseyi/core/session/session_controller.dart';
import 'package:idrak_liseyi/modules/navigation/widgets/gopanel_drawer.dart';
import 'package:idrak_liseyi/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GoPanelDrawer - Culture and Art group exists and expands for Super Admin', (tester) async {
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

    final headerFinder = find.text('Mədəniyyət və İncəsənət');
    expect(headerFinder, findsOneWidget);

    await tester.tap(headerFinder);
    await tester.pumpAndSettle();

    expect(find.text('Dərnək jurnalı'), findsOneWidget);
    expect(find.text('Dərnəklər'), findsOneWidget);
  });

  testWidgets('GoPanelDrawer - Culture and Art shows only Dərnək jurnalı when user has only club journal permission', (tester) async {
    final session = SessionController();
    session.setMockProfile(MobileProfile(
      id: 2,
      name: 'Müəllim Test',
      type: 'employer',
      guard: 'employer',
      isSuper: false,
      permissions: {'gopanel.academic.clubs.journal.view'},
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

    // Group should be visible because at least one item is permitted
    final headerFinder = find.text('Mədəniyyət və İncəsənət');
    expect(headerFinder, findsOneWidget);

    await tester.tap(headerFinder);
    await tester.pumpAndSettle();

    expect(find.text('Dərnək jurnalı'), findsOneWidget);
    expect(find.text('Dərnəklər'), findsNothing);
  });

  testWidgets('GoPanelDrawer - Culture and Art is completely hidden when user has neither club permission', (tester) async {
    final session = SessionController();
    session.setMockProfile(MobileProfile(
      id: 3,
      name: 'İstifadəçi Test',
      type: 'employer',
      guard: 'employer',
      isSuper: false,
      permissions: {'gopanel.academic.classes.view'}, // Only classes, no clubs
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

    // Group must NOT be rendered at all
    expect(find.text('Mədəniyyət və İncəsənət'), findsNothing);
  });
}
