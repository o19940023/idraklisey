import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Simple Agora Token Generator (for testing only)
/// Production: Use server-side token generation
class AgoraTokenGenerator {
  static const String _appId = '693953780f8c47398354c42c47eab432';
  static const String _appCertificate = '7040f96cd0ca48158c226e6dc4b286ae';

  /// Generate RTC Token (valid for 24 hours)
  static String generateToken({required String channelName, required int uid}) {
    // Token expires in 24 hours
    final privilegeExpiredTs =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 86400;

    return _buildToken(
      appId: _appId,
      appCertificate: _appCertificate,
      channelName: channelName,
      uid: uid,
      privilegeExpiredTs: privilegeExpiredTs,
    );
  }

  static String _buildToken({
    required String appId,
    required String appCertificate,
    required String channelName,
    required int uid,
    required int privilegeExpiredTs,
  }) {
    // Simple token format: VERSION:APP_ID:EXPIRE_TIME:SIGNATURE
    // This is a SIMPLIFIED version - Production should use official token server

    final random = Random.secure();
    final salt = random.nextInt(0xFFFFFFFF);
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Build message to sign
    final message =
        '$appId$channelName${uid}${salt}$timestamp$privilegeExpiredTs';

    // Create HMAC-SHA256 signature
    final key = utf8.encode(appCertificate);
    final messageBytes = utf8.encode(message);
    final hmac = Hmac(sha256, key);
    final signature = hmac.convert(messageBytes);

    // Encode to base64
    final tokenData = {
      'salt': salt,
      'ts': timestamp,
      'expire': privilegeExpiredTs,
      'sig': signature.toString(),
    };

    final tokenJson = jsonEncode(tokenData);
    final tokenBase64 = base64Encode(utf8.encode(tokenJson));

    // Format: 007 (version) + appId + base64Token
    return '007$appId$tokenBase64';
  }
}
