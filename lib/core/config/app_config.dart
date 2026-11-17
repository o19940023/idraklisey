import 'package:flutter/foundation.dart';

/// Central runtime configuration.
///
/// The mobile application talks ONLY to the local Laravel gateway by default.
/// A hard guard prevents accidental requests to production during development.
class AppConfig {
  AppConfig._();

  /// Override at build time:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/mobile/v1
  static const String _definedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const bool _allowProduction = bool.fromEnvironment(
    'ALLOW_PRODUCTION_API',
    defaultValue: false,
  );

  /// Android emulator reaches the host via 10.0.2.2; everything else uses
  /// loopback.
  static String get defaultBaseUrl {
    if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;
    return 'https://new.idrak.edu.az/api/mobile/v1/';
  }

  static String get apiBaseUrl {
    final url = defaultBaseUrl;
    _guard(url);
    return url;
  }

  /// Returns true when the URL is safe for development or beta server.
  static bool isAllowed(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host == 'new.idrak.edu.az') return true;
    final isProduction = host == 'portal.idrak.edu.az' || host == 'idrak.edu.az' || host == 'idrak.az';
    return !isProduction || _allowProduction;
  }

  static void assertSafe(String url) {
    if (!isAllowed(url)) {
      throw StateError(
        'Təhlükəsizlik: mobil tətbiq istehsal serverinə (idrak.edu.az) sorğu göndərə bilməz. '
        'Lokal API ünvanı istifadə edin və ya ALLOW_PRODUCTION_API=true ilə açıq icazə verin.',
      );
    }
  }

  static void _guard(String url) => assertSafe(url);

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 40);
  static const int defaultPageSize = 20;

  /// The web panel wording is Azerbaijani; mobile defaults to `az`.
  static const String defaultLocale = 'az';
}
