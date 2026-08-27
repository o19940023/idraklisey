import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tətbiq versiyasını yoxlayan servis (iOS + Android).
///
/// Versiya mənbələri (prioritet sırası ilə):
///  1. Firestore `app_config/version` sənədi (admin idarə edir, hər iki platforma)
///     Fields: latest_version, update_url_ios, update_url_android
///  2. iOS: App Store Lookup API (iTunes)
///  3. Android: Google Play səhifəsindən versiya çıxartma
///
/// Yeni versiya varsa banner göstərilir; istifadəçi banner-i bağlasa belə
/// tətbiq yenilənənə qədər hər açılışda yenidən görünür.
class AppUpdateService extends ChangeNotifier {
  String _currentVersion = '';
  String _latestVersion = '';
  String _updateUrl = '';
  bool _updateAvailable = false;
  bool _dismissed = false; // Yalnız cari sessiyada gizlədir; yenilənənə qədər hər açılışda qayıdır

  String get currentVersion => _currentVersion;
  String get latestVersion => _latestVersion;
  String get updateUrl => _updateUrl;
  bool get updateAvailable => _updateAvailable && !_dismissed;
  bool get hasUpdate => _updateAvailable;

  // ─── Mağaza kimlikləri ───
  static const String _iosBundleId = 'az.idrak.liseyi';
  static const String _androidPackageName = 'az.idrak.liseyi';

  /// Tətbiq başlayanda çağırılır
  Future<void> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      // 1) Firestore-dan yoxla (admin tərəfindən idarə olunur)
      await _checkFirestoreConfig();

      // 2) Firestore boşdursa mağaza API-lərindən yoxla
      if (_latestVersion.isEmpty) {
        if (Platform.isIOS) {
          await _checkiOSUpdate();
        } else if (Platform.isAndroid) {
          await _checkAndroidUpdate();
        }
      }

      if (_latestVersion.isNotEmpty) {
        _updateAvailable = _isNewerVersion(_latestVersion, _currentVersion);
        _dismissed = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Versiya yoxlama xətası: $e');
    }
  }

  /// Firestore `app_config/version` sənədindən son versiyanı oxu
  Future<void> _checkFirestoreConfig() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));

      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final latest = (data['latest_version'] ?? '').toString().trim();
      if (latest.isEmpty) return;

      _latestVersion = latest;

      final iosUrl = (data['update_url_ios'] ?? '').toString().trim();
      final androidUrl = (data['update_url_android'] ?? '').toString().trim();
      _updateUrl = Platform.isIOS
          ? (iosUrl.isNotEmpty ? iosUrl : _fallbackStoreUrl())
          : (androidUrl.isNotEmpty ? androidUrl : _fallbackStoreUrl());
    } catch (e) {
      debugPrint('⚠️ Firestore versiya yoxlaması ötrüldü: $e');
    }
  }

  /// iOS: App Store Lookup API
  Future<void> _checkiOSUpdate() async {
    try {
      final response = await http.get(
        Uri.parse('https://itunes.apple.com/lookup?bundleId=$_iosBundleId&country=az'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = json['results'] as List;
        if (results.isNotEmpty) {
          _latestVersion = results[0]['version'] ?? '';
          _updateUrl = results[0]['trackViewUrl'] ?? _fallbackStoreUrl();
        }
      }
    } catch (e) {
      debugPrint('⚠️ iOS App Store yoxlama xətası: $e');
    }
  }

  /// Android: Google Play Store-dan yoxla (HTML parse)
  Future<void> _checkAndroidUpdate() async {
    try {
      final response = await http.get(
        Uri.parse('https://play.google.com/store/apps/details?id=$_androidPackageName&hl=az'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final versionMatch = RegExp(r'\[\[\["(\d+\.\d+\.\d+)"\]').firstMatch(response.body);
        if (versionMatch != null) {
          _latestVersion = versionMatch.group(1) ?? '';
          _updateUrl = _fallbackStoreUrl();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Play Store yoxlama xətası: $e');
    }
  }

  String _fallbackStoreUrl() {
    return Platform.isIOS
        ? 'https://apps.apple.com/az/search?term=idrak+liseyi'
        : 'https://play.google.com/store/apps/details?id=$_androidPackageName';
  }

  /// Semantik versiya müqayisəsi: latest > current ?
  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('-').first.split('.').map(int.parse).toList();
      final currentParts = current.split('-').first.split('.').map(int.parse).toList();

      // Major, Minor, Patch müqayisəsi
      for (int i = 0; i < 3; i++) {
        final l = i < latestParts.length ? latestParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Banner bağlandı — yalnız cari sessiya üçün.
  /// Tətbiq mağazadan yenilənənə qədər növbəti açılışda banner yenə göstərilir.
  void dismissUpdate() {
    _dismissed = true;
    notifyListeners();
  }

  /// App Store / Google Play səhifəsini aç
  Future<void> openStore() async {
    final url = _updateUrl.isNotEmpty ? _updateUrl : _fallbackStoreUrl();
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('⚠️ Mağaza açılma xətası: $e');
    }
  }
}
