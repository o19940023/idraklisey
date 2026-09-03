import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/push_config.dart';

/// Push relay klienti — Cloudflare Worker üzərindən FCM HTTP v1 API.
///
/// Blaze plan / Cloud Function tələb etmir: bildiriş payload-ını relay-ə
/// göndərir, relay service account açarı ilə topic-lərə push atır.
/// Topic-lərə abunəlik [PushNotificationService] tərəfindən aparılır,
/// burada yalnız "göndər" əmri var.
///
/// Push best-effort-dur: relay xətası in-app bildirişi pozmur —
/// bildiriş onsuz da Firestore-dadı və girişdə görünür.
class PushRelayService {
  PushRelayService._();

  static final PushRelayService instance = PushRelayService._();

  Future<void> sendPush({
    required String title,
    required String body,
    List<String> targetUserIds = const [],
    List<String> targetRoles = const [],
    List<String> targetClasses = const [],
    String? targetStudentId,
    String? targetParentId,
    String priority = 'normal',
    String? excludeUserId,
  }) async {
    if (!PushConfig.enabled) return;
    try {
      final res = await http
          .post(
            Uri.parse(PushConfig.relayUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Push-Key': PushConfig.relayKey,
            },
            body: jsonEncode({
              'title': title,
              'body': body,
              'targetUserIds': targetUserIds,
              'targetRoles': targetRoles,
              'targetClasses': targetClasses,
              'targetStudentId': targetStudentId,
              'targetParentId': targetParentId,
              'priority': priority,
              'excludeUserId': excludeUserId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        debugPrint('[PushRelay] göndərildi: ${res.body}');
      } else {
        debugPrint('[PushRelay] xəta ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[PushRelay] əlaqə xətası: $e');
    }
  }
}
