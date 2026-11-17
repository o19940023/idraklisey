import 'dart:convert';
import 'package:http/http.dart' as http;

/// Agora token'larını Render.com backend'inden alır.
/// 
/// App Certificate artık client-side'da yok - tam güvenli! 🔒
class AgoraTokenService {
  // Render.com URL'i - deploy edince güncellenecek
  static const String _baseUrl =
      'https://idrak-agora-token.onrender.com'; // Deploy sonrası güncellenecek

  /// RTC token al - channel + userId ile
  static Future<({String token, int uid})> fetchRtcToken({
    required String channelName,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'channelName': channelName,
          'userId': userId,
        }),
      ).timeout(
        // Render.com free tier soğuk başlatma 10+ saniye sürebilir — kısa
        // timeout iOS'ta gereksiz "katılamadı" hataları üretiyordu.
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Token server cavab vermədi (timeout)'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (
          token: data['token'] as String,
          uid: (data['uid'] as num).toInt(),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Token xətası: ${error['error']}');
      }
    } catch (e) {
      throw Exception('Agora token alınarkən xəta: $e');
    }
  }

  /// Qonaq üçün veb qoşulma linkini qaytarır
  static String getGuestJoinUrl(String roomId) {
    return '$_baseUrl/join/$roomId';
  }

  /// Otağı backend serverində qeydiyyatdan keçirir (Qonaq linki üçün)
  static Future<bool> registerRoom({
    required String roomId,
    required String title,
    required String hostName,
    required bool allowGuestLink,
    required int guestLimit,
    required bool hasVideo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/rooms/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomId': roomId,
          'title': title,
          'hostName': hostName,
          'allowGuestLink': allowGuestLink,
          'guestLimit': guestLimit,
          'hasVideo': hasVideo,
        }),
      ).timeout(const Duration(seconds: 8));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Otağı sonlandırır / qonaq linkini deaktiv edir (Destroy)
  static Future<bool> endRoom(String roomId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/rooms/end'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'roomId': roomId}),
      ).timeout(const Duration(seconds: 8));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
