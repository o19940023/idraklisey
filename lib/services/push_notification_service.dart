import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user_model.dart';
import '../providers/app_state.dart' show UserRole;

/// FCM push bildiriş servisi.
///
/// Məqsəd: tətbiq bağlı olsa belə bildirişlər telefona çatsın.
/// Hədəfləmə topic-lərlə aparılır (server/Blaze tələb etmir):
///   user_<id>          → konkret istifadəçi (məs: ticket cavabı)
///   role_<roleAdı>     → admin / teacher / student / parent
///   staffrole_<rolId>  → helpdesk, IT, psixoloq kimi işçi rolları
///   class_<sinif>      → sinif elanları (valideynlər uşaq siniflərinə abunə)
///   all                → bütün qurulan cihazlar
///
/// Göndərmə: tətbiq bildirişi Firestore-a yazdıqda eyni anda
/// [PushRelayService] vasitəsilə Cloudflare Worker relay-ə POST atır,
/// worker FCM HTTP v1 ilə topic-lərə push göndərir (ətraflı: PUSH_SETUP.md).
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _topicsPrefKey = 'push_subscribed_topics';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _tokenListenerBound = false;
  Set<String> _activeTopics = {};
  AppUser? _lastUser;
  Set<String> _extraClassTopics = {};

  /// Tətbiq arxa planda / bağlı ikən gələn mesajlar üçün — top-level olmalıdır.
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    // Notification mesajları bu halda sistem tərəfindən özü göstərilir;
    // Firebase-in background izolyasiyasında işə düşməsi üçün init edirik.
    await Firebase.initializeApp();
    debugPrint('[Push] background message: ${message.messageId}');
  }

  /// main() içində, Firebase init-dən sonra bir dəfə çağrılır.
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // main() də init edir; təkrar init xətası problem deyil.
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Android notification channel (tətbiq bağlı ikən bildiriş almaq üçün mütləq lazımdır)
    const androidChannel = AndroidNotificationChannel(
      'idrak_general',
      'İdrak Liseyi bildirişləri',
      description: 'Məktəb bildirişləri və müraciət cavabları',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );

    // Tətbiq açıq ikən də bildiriş görünsün (iOS). Android üçün onMessage
    // listener aşağıda yerli bildiriş göstərir.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    debugPrint('[Push] initialized');
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'idrak_general',
          'İdrak Liseyi bildirişləri',
          channelDescription: 'Məktəb bildirişləri və müraciət cavabları',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Uğurlu giriş sonrası çağrılır — icazə istəyir, tokeni alır,
  /// köhnə topic-lərə abunəni ləğv edib yenilərinə yazılır.
  /// [childClasses] — valideyn üçün uşaqlarının sinifləri (push hədəfi).
  Future<void> onUserLoggedIn(
    AppUser user, {
    Set<String> childClasses = const {},
  }) async {
    try {
      _lastUser = user;
      _extraClassTopics = Set.of(childClasses);
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final settings = await messaging.getNotificationSettings();
      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) {
        debugPrint('[Push] notification permission not granted');
        return;
      }

      _fcmToken = await messaging.getToken();
      debugPrint('[Push] FCM Token: $_fcmToken');

      if (!_tokenListenerBound) {
        messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _saveDeviceDoc(user);
        });
        _tokenListenerBound = true;
      }

      final desiredTopics = _topicsFor(user);
      await _syncTopicSubscriptions(desiredTopics);
      await _saveDeviceDoc(user);

      debugPrint('[Push] subscribed topics: $desiredTopics');
    } catch (e) {
      debugPrint('[Push] onUserLoggedIn error: $e');
    }
  }

  /// Çıxış zamanı — şəxsi topic-lərə abunəliyi ləğv edir.
  Future<void> onUserLoggedOut() async {
    try {
      if (_activeTopics.isNotEmpty) {
        for (final topic in _activeTopics) {
          if (topic != 'all') {
            await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
          }
        }
      }
      _activeTopics = {};
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_topicsPrefKey);
      debugPrint('[Push] unsubscribed all personal topics');
    } catch (e) {
      debugPrint('[Push] onUserLoggedOut error: $e');
    }
  }

  /// Rol dəyişdikdə köhnə topic-lərdən çıxarıb yenilərə yazır.
  /// Uğursuz abunəlik yadda saxlanmır — növbəti girişdə avtomatik təkrar olunur.
  Future<void> _syncTopicSubscriptions(Set<String> desired) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_topicsPrefKey) ?? [];
    final succeeded = <String>{};

    for (final old in stored) {
      if (!desired.contains(old)) {
        try {
          await FirebaseMessaging.instance.unsubscribeFromTopic(old);
          debugPrint('[Push] unsubscribed from: $old');
        } catch (_) {}
      }
    }
    for (final topic in desired) {
      try {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
        succeeded.add(topic);
        debugPrint('[Push] subscribed to: $topic');
      } catch (e) {
        debugPrint('[Push] subscribe FAILED: $topic — $e');
      }
    }

    _activeTopics = succeeded;
    await prefs.setStringList(_topicsPrefKey, succeeded.toList());
  }

  /// Uşaqların sinifləri yüklənəndə (məs. initFirebaseData) çağrılır —
  /// valideyn class_<sinif> topic-lərinə yenidən abunə olur.
  Future<void> updateClassTopics(Set<String> classNames) async {
    final user = _lastUser;
    if (user == null || classNames.isEmpty) return;
    if (user.role != UserRole.parent) return;
    if (Set<String>.of(classNames).difference(_extraClassTopics).isEmpty &&
        _activeTopics.isNotEmpty) {
      return; // dəyişiklik yoxdur
    }
    _extraClassTopics = Set.of(classNames);
    try {
      await _syncTopicSubscriptions(_topicsFor(user));
      debugPrint('[Push] class topics updated: $_extraClassTopics');
    } catch (e) {
      debugPrint('[Push] updateClassTopics error: $e');
    }
  }

  Set<String> _topicsFor(AppUser user) {
    final topics = <String>{
      'all',
      _sanitize('user_${user.id}'),
      _sanitize('role_${user.role.name}'),
    };

    final roleId = user.assignedRoleId;
    if (roleId != null && roleId.isNotEmpty) {
      topics.add(_sanitize('staffrole_$roleId'));
    }

    final classes = <String>{
      ...user.assignedClasses,
      ..._extraClassTopics,
      if (user.className != null && user.className!.trim().isNotEmpty)
        user.className!,
    };
    for (final className in classes) {
      if (className.trim().isNotEmpty) {
        topics.add(_sanitize('class_$className'));
      }
    }
    return topics;
  }

  /// Firebase topic adları yalnız [a-zA-Z0-9-_.~%] qəbul edir.
  String _sanitize(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');
    return cleaned.length > 200 ? cleaned.substring(0, 200) : cleaned;
  }

  /// Gələcəkdə Cloud Function qurulanda (bkz. PUSH_SETUP.md) token
  /// xəritəsindən istifadə olunacaq; Console-dan da oxunabilir.
  Future<void> _saveDeviceDoc(AppUser user) async {
    final token = _fcmToken;
    if (token == null || token.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('devices').doc(user.id).set({
        'token': token,
        'userId': user.id,
        'fullName': user.fullName,
        'role': user.role.name,
        'assignedRoleId': user.assignedRoleId,
        'updatedAt': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name,
      });
      debugPrint('[Push] device token saved to Firestore');
    } catch (e) {
      debugPrint('[Push] saveDeviceDoc error: $e');
    }
  }
}
