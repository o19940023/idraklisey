import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:idrak_liseyi/core/session/session_controller.dart';
import 'package:idrak_liseyi/providers/app_state.dart';
import 'package:idrak_liseyi/modules/navigation/main_screen.dart';
import 'package:idrak_liseyi/l10n/app_localizations.dart';
import 'package:idrak_liseyi/services/app_update_service.dart';

void main() {
  testWidgets('Teacher login and dashboard renders without error', (tester) async {
    final session = SessionController();
    final profile = MobileProfile(
      id: 20,
      type: 'employer',
      guard: 'employer',
      name: 'Əntiqə Səlimzadə Zabil',
      roles: ['Müəllim', 'Uşaq Birliyi'],
      activeRole: 'Müəllim',
      permissions: {
        'gopanel.hr.teqvims.view',
        'gopanel.academic.schedules.view',
        'gopanel.academic.ejournal.attendance.view',
        'gopanel.academic.ejournal.grading.view',
        'gopanel.academic.clubs.view',
        'gopanel.tickets.view',
      },
      companyId: 1,
      filialId: 1,
    );
    session.setMockProfile(profile);

    final appState = AppState();
    appState.syncFromSession(session);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<AppUpdateService>.value(value: appUpdateService),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('az'),
          home: MainScreen(key: ValueKey('main')),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('Müəllim'), findsWidgets);
  });
}
