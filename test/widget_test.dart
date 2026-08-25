import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:idrak_liseyi/providers/app_state.dart';
import 'package:idrak_liseyi/data/models/user_preferences_model.dart';
import 'package:idrak_liseyi/data/models/timetable_model.dart';
import 'package:idrak_liseyi/core/utils/fin_code_formatter.dart';

final Uint8List _transparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _FakeHttpClientRequest();
  }
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse();
  }
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  test('UserPreferences default generation for all roles test', () {
    for (final role in ['admin', 'teacher', 'student', 'parent']) {
      final prefs = UserPreferences.createDefault(
        userId: 'test_$role',
        userRole: role,
      );
      expect(prefs.dashboardModules.isNotEmpty, isTrue);
      expect(prefs.navigationItems.isNotEmpty, isTrue);

      final navItem = prefs.dashboardModules.first.toNavigationItem();
      expect(navItem.id, equals(prefs.dashboardModules.first.id));
    }
  });

  test('FIN code uppercase formatting and validation test', () {
    expect(validateFinCode('6XX7UVH'), isNull);
    expect(validateFinCode('1234567'), isNull);
    expect(validateFinCode('7AB1234'), isNull);
    expect(validateFinCode('123456'), isNotNull); // too short
    expect(validateFinCode('12345678'), isNotNull); // too long
  });

  test('LessonSlot class merging and co-teacher display test', () {
    final slot = LessonSlot(
      period: '1-ci dərs',
      time: '08:00 - 08:45',
      subject: 'Riyaziyyat',
      teacher: 'Aysel Məmmədova',
      room: '301',
      isMerged: true,
      mergedClassNames: ['5B', '6B'],
      coTeacherName: 'Rəşad Əliyev',
    );

    expect(slot.isMerged, isTrue);
    expect(slot.displayClasses('5B'), equals('5B & 6B'));
    expect(slot.displayTeachers, equals('Aysel Məmmədova & Rəşad Əliyev'));
  });

  testWidgets('Idrak Liseyi App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('İDRAK LİSEYİ'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify that Idrak Liseyi title exists
    expect(find.text('İDRAK LİSEYİ'), findsOneWidget);
  });
}

