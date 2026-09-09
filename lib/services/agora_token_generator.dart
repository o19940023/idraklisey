import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Agora AccessToken2 (versiya "007") üreticisi — resmi binary spec.
///
/// Token formatı: "007" + base64(packed content + raw 32-byte HMAC-SHA256)
///
/// ⚠️ GÜVƏNLİK QEYDİ: Sertifika hazırda client tərəfdədir. İstehsalat üçün
/// token generasiyasını Cloud Function-a köçürmək tövsiyə olunur. Sertifika
/// APK-nı təhlil edən hər kəs tərəfindən oxuna bilər — bu, MVP mərhələsi
/// üçün qəbul edilmiş kompromisdür.
class AgoraTokenGenerator {
  static const String _appId = '045bdb3866464fb6b47009e8044ce57e';
  static const String _appCertificateHex = '0d55f75c1a5a48968ca941e880231003';
  static const String _version = '007';
  static const List<String> _debugUrls = <String>[
    'http://10.10.15.114:7777/event',
    'http://10.0.2.2:7777/event',
  ];
  static const String _debugSessionId = 'agora-invalid-token';

  static const int _privilegeJoinChannel = 1;
  static const int _privilegePublishAudio = 2;
  static const int _privilegePublishVideo = 3;
  static const int _privilegePublishData = 4;
  static const int _serviceTypeRtc = 1;

  // Certificate UTF-8 bytes (NOT hex-decoded!)
  static List<int> get _certificateBytes => utf8.encode(_appCertificateHex);

  static String generateRtcToken({
    required String channelName,
    required int uid,
    int expireInSeconds = 86400,
  }) {
    final issueTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final salt = Random.secure().nextInt(0x7FFFFFFF);

    // --- RTC service payload (type 1) ---
    final rtcPayload = BytesBuilder();
    _packString(rtcPayload, channelName);
    _packString(rtcPayload, uid.toString()); // UID as decimal string!

    // Privileges: relative seconds from issueTs
    final privileges = <int, int>{
      _privilegeJoinChannel: expireInSeconds,
      _privilegePublishAudio: expireInSeconds,
      _privilegePublishVideo: expireInSeconds,
      _privilegePublishData: expireInSeconds,
    };
    _packUint16(rtcPayload, privileges.length);
    for (final entry in privileges.entries) {
      _packUint16(rtcPayload, entry.key);
      _packUint32(rtcPayload, entry.value);
    }
    final rtcPayloadBytes = rtcPayload.toBytes();

    // --- Signing info: appId + issueTs + expire + salt + services ---
    final signingInfo = BytesBuilder();
    _packString(signingInfo, _appId);
    _packUint32(signingInfo, issueTs);
    _packUint32(signingInfo, expireInSeconds); // Token expire duration!
    _packUint32(signingInfo, salt);
    _packUint16(signingInfo, 1); // 1 service
    _packUint16(signingInfo, _serviceTypeRtc);
    signingInfo.add(rtcPayloadBytes);

    final signingInfoBytes = signingInfo.toBytes();

    // --- Two-layer HMAC key derivation per AccessToken2 spec ---
    // sign = HMAC-SHA256(key=uint32_le(issueTs), data=certificate_utf8)
    final timestampKey = BytesBuilder();
    _packUint32(timestampKey, issueTs);
    final sign = Hmac(
      sha256,
      timestampKey.toBytes(),
    ).convert(_certificateBytes).bytes;

    // signing = HMAC-SHA256(key=uint32_le(salt), data=sign)
    final saltKey = BytesBuilder();
    _packUint32(saltKey, salt);
    final signing = Hmac(sha256, saltKey.toBytes()).convert(sign).bytes;

    // signature = HMAC-SHA256(key=signing, data=signingInfo)
    final signature = Hmac(sha256, signing).convert(signingInfoBytes).bytes;

    // --- Pack: uint16(signature.length) + signature + signingInfo ---
    final tokenContent = BytesBuilder();
    _packUint16(tokenContent, signature.length);
    tokenContent.add(signature);
    tokenContent.add(signingInfoBytes);

    // --- Compress with zlib DEFLATE (gzip) and base64 ---
    final compressed = gzip.encode(tokenContent.toBytes());

    // #region debug-point A:token-layout
    _reportDebug(
      hypothesisId: 'A',
      location: 'agora_token_generator.dart:generateRtcToken',
      msg: '[DEBUG] Generated RTC token (FIXED SPEC)',
      data: <String, Object?>{
        'channelName': channelName,
        'uid': uid,
        'issueTs': issueTs,
        'expireInSeconds': expireInSeconds,
        'salt': salt,
        'certificateByteLength': _certificateBytes.length,
        'rtcPayloadLength': rtcPayloadBytes.length,
        'signingInfoLength': signingInfoBytes.length,
        'signatureLength': signature.length,
        'tokenContentLength': tokenContent.length,
        'compressedLength': compressed.length,
        'tokenPrefix': _version,
      },
    );
    // #endregion

    return _version + base64Encode(compressed);
  }

  static int uidFromUserId(String userId) {
    final digest = sha256.convert(utf8.encode('idrak-meet|$userId')).bytes;
    return (digest[0] | digest[1] << 8 | digest[2] << 16 | digest[3] << 24) &
        0x7FFFFFFF;
  }

  // --- Little-endian packing helpers ---

  static void _packString(BytesBuilder b, String value) {
    final bytes = utf8.encode(value);
    _packUint16(b, bytes.length);
    b.add(bytes);
  }

  static void _packUint16(BytesBuilder b, int value) {
    b.addByte(value & 0xFF);
    b.addByte((value >> 8) & 0xFF);
  }

  static void _packUint32(BytesBuilder b, int value) {
    b.addByte(value & 0xFF);
    b.addByte((value >> 8) & 0xFF);
    b.addByte((value >> 16) & 0xFF);
    b.addByte((value >> 24) & 0xFF);
  }

  static List<int> _hexToBytes(String hex) {
    final len = hex.length;
    final bytes = Uint8List(len ~/ 2);
    for (var i = 0; i < len; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }

  static void _reportDebug({
    required String hypothesisId,
    required String location,
    required String msg,
    Map<String, Object?>? data,
  }) {
    unawaited(() async {
      final payload = jsonEncode(<String, Object?>{
        'sessionId': _debugSessionId,
        'runId': 'post-fix',
        'hypothesisId': hypothesisId,
        'location': location,
        'msg': msg,
        'data': data ?? const <String, Object?>{},
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      for (final url in _debugUrls) {
        final client = HttpClient();
        try {
          final request = await client.postUrl(Uri.parse(url));
          request.headers.contentType = ContentType.json;
          request.write(payload);
          await request.close();
          break;
        } catch (_) {
        } finally {
          client.close(force: true);
        }
      }
    }());
  }
}
