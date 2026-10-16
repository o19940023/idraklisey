import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'agora_token_service.dart';

/// Gerçek Agora RTC Motoru sarmalayıcısı (agora_rtc_engine 6.x).
///
/// - Kanala token ilə qoşulma (AccessToken2, client tərəfdə yaradılır)
/// - Səs + video (kamera aç/bağla, ön/arxa kamera, hoparlör)
/// - Konuşan istifadəçi aşkarlaması (həcm indikasiyası)
/// - Uzaqdan video vəziyyəti, token yenilənməsi, təmizlənmə
class AgoraService {
  static const String appId = '045bdb3866464fb6b47009e8044ce57e';
  static const List<String> _debugUrls = <String>[
    'http://10.10.15.114:7777/event',
    'http://10.0.2.2:7777/event',
  ];
  static const String _debugSessionId = 'agora-invalid-token';

  // --- Callbacks (UI-a bildirir) ---
  Function(List<AudioVolumeInfo> speakers, int totalVolume)?
  onAudioVolumeIndication;
  Function(dynamic err, String msg)? onError;
  Function(int uid)? onUserJoined;
  Function(int uid, UserOfflineReasonType reason)? onUserOffline;

  /// Uzaq istifadəçinin kamerası açılıb/bağlanıb
  Function(int uid, bool videoOn)? onRemoteVideoStateChanged;
  Function()? onJoinSuccess;

  /// Bağlantı vəziyyəti dəyişdikdə (iOS'da join takılması teşhisi üçün)
  Function(ConnectionStateType state, ConnectionChangedReasonType reason)?
  onConnectionStateChanged;

  RtcEngine? _engine;
  bool _initialized = false;
  bool _joined = false;
  bool _disposed = false;
  bool _hasCameraPermission = false;

  int _localUid = 0;
  String _channelId = '';
  String _userId = ''; // Token renew için userId'yi saklıyoruz
  bool _isVideoRoom = false;
  bool _isMicMuted = false;
  bool _isCameraOn = false;
  bool _isFrontCamera = true;
  bool _isSpeakerOn = true;
  final Set<int> _remoteUids = {};
  final Map<int, bool> _remoteVideoOn = {};

  // --- State getters ---
  RtcEngine? get engine => _engine;
  bool get isJoined => _joined;
  bool get isInitialized => _initialized;
  int get localUid => _localUid;
  String get channelId => _channelId;
  bool get isVideoRoom => _isVideoRoom;
  bool get isMicMuted => _isMicMuted;
  bool get isCameraOn => _isCameraOn;
  bool get isFrontCamera => _isFrontCamera;
  bool get isSpeakerOn => _isSpeakerOn;
  Set<int> get remoteUids => Set.unmodifiable(_remoteUids);
  bool isRemoteVideoOn(int uid) => _remoteVideoOn[uid] ?? false;

  /// Mikrofon + (video otağı üçün) kamera icazələrini istəyir və motornu
  /// işə salır. Uğursuzluqda false qaytarır.
  Future<bool> initialize({bool enableVideo = false}) async {
    if (_initialized) return true;
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        debugPrint('[Agora] Microphone permission denied: $micStatus');
        return false;
      }
      if (enableVideo) {
        final camStatus = await Permission.camera.request();
        _hasCameraPermission = camStatus.isGranted;
        if (!_hasCameraPermission) {
          debugPrint('[Agora] Camera permission denied: $camStatus');
          // Kamera icazəsi yoxdursa yalnız səsli davam edə bilərik
          enableVideo = false;
        }
      }
      _isVideoRoom = enableVideo;

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      await _engine!.enableAudioVolumeIndication(
        interval: 200,
        smooth: 3,
        reportVad: true,
      );

      if (_isVideoRoom) {
        await _engine!.enableVideo();
        // Məktəb şəbəkələri üçün mülayim enkoder profili (360p @ 15fps)
        await _engine!.setVideoEncoderConfiguration(
          const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 640, height: 360),
            frameRate: 15,
            bitrate: 500,
            orientationMode: OrientationMode.orientationModeAdaptive,
          ),
        );
      }

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('[Agora] Joined channel: ${connection.channelId}');
            _joined = true;
            // #region debug-point D:join-success
            _reportDebug(
              hypothesisId: 'D',
              location: 'agora_service.dart:onJoinChannelSuccess',
              msg: '[DEBUG] Join channel success callback',
              data: <String, Object?>{
                'channelId': connection.channelId,
                'localUid': _localUid,
                'elapsed': elapsed,
              },
            );
            // #endregion
            // Mobil cihazlarda default qulaqlıq deyil hoparlör olsun
            _engine?.setEnableSpeakerphone(_isSpeakerOn);
            onJoinSuccess?.call();
          },
          onConnectionStateChanged:
              (
                RtcConnection connection,
                ConnectionStateType state,
                ConnectionChangedReasonType reason,
              ) {
                debugPrint('[Agora] Connection state: ${state.name} (${reason.name})');
                onConnectionStateChanged?.call(state, reason);
              },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint('[Agora] Left channel');
            _joined = false;
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('[Agora] User joined: $remoteUid');
            _remoteUids.add(remoteUid);
            _remoteVideoOn[remoteUid] = false;
            onUserJoined?.call(remoteUid);
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                debugPrint('[Agora] User offline: $remoteUid ($reason)');
                _remoteUids.remove(remoteUid);
                _remoteVideoOn.remove(remoteUid);
                onUserOffline?.call(remoteUid, reason);
              },
          onRemoteVideoStateChanged:
              (
                RtcConnection connection,
                int remoteUid,
                RemoteVideoState state,
                RemoteVideoStateReason reason,
                int elapsed,
              ) {
                final videoOn =
                    state == RemoteVideoState.remoteVideoStateDecoding;
                final previous = _remoteVideoOn[remoteUid];
                _remoteVideoOn[remoteUid] = videoOn;
                if (previous != videoOn) {
                  onRemoteVideoStateChanged?.call(remoteUid, videoOn);
                }
              },
          onAudioVolumeIndication:
              (
                RtcConnection connection,
                List<AudioVolumeInfo> speakers,
                int totalVolume,
                int vad,
              ) {
                onAudioVolumeIndication?.call(speakers, totalVolume);
              },
          onTokenPrivilegeWillExpire:
              (RtcConnection connection, String token) async {
                debugPrint('[Agora] Token expiring — renewing');
                try {
                  final result = await AgoraTokenService.fetchRtcToken(
                    channelName: _channelId,
                    userId: _userId,
                  );
                  await _engine?.renewToken(result.token);
                } catch (e) {
                  debugPrint('[Agora] renewToken on expire failed: $e');
                }
              },
          onRequestToken: (RtcConnection connection) async {
            debugPrint('[Agora] Token requested — generating fresh');
            // #region debug-point D:request-token
            _reportDebug(
              hypothesisId: 'D',
              location: 'agora_service.dart:onRequestToken',
              msg: '[DEBUG] Agora requested token refresh (RENDER)',
              data: <String, Object?>{
                'channelId': connection.channelId,
                'localUid': _localUid,
                'userId': _userId,
              },
            );
            // #endregion
            try {
              final result = await AgoraTokenService.fetchRtcToken(
                channelName: _channelId,
                userId: _userId,
              );
              await _engine?.renewToken(result.token);
            } catch (e) {
              debugPrint('[Agora] renewToken on request failed: $e');
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('[Agora] Error: $err — $msg');
            // #region debug-point D:error
            _reportDebug(
              hypothesisId: 'D',
              location: 'agora_service.dart:onError',
              msg: '[DEBUG] Agora emitted error',
              data: <String, Object?>{
                'error': err.name,
                'message': msg,
                'channelId': _channelId,
                'localUid': _localUid,
                'joined': _joined,
              },
            );
            // #endregion
            onError?.call(err, msg);
          },
        ),
      );

      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('[Agora] initialize failed: $e');
      await _cleanupEngine();
      return false;
    }
  }

  /// Kanala qoşulur. [enableVideo] otaq görüntülüdürsə true — kamera
  /// standart olaraq BAĞLI başlayır (istifadəçi özü açır).
  Future<bool> joinChannel({
    required String channelId,
    required String userId,
    bool enableVideo = false,
  }) async {
    if (!_initialized) {
      final ok = await initialize(enableVideo: enableVideo);
      if (!ok) return false;
    }
    if (_joined || _engine == null) return _joined;

    try {
      _channelId = channelId;
      _userId = userId; // Token renew için saklıyoruz

      // Render.com backend'inden token al (güvenli!)
      final result = await AgoraTokenService.fetchRtcToken(
        channelName: channelId,
        userId: userId,
      );

      _localUid = result.uid;
      final token = result.token;

      // #region debug-point C:join-params
      _reportDebug(
        hypothesisId: 'C',
        location: 'agora_service.dart:joinChannel',
        msg: '[DEBUG] Preparing joinChannel (RENDER BACKEND)',
        data: <String, Object?>{
          'channelId': channelId,
          'userId': userId,
          'computedUid': _localUid,
          'tokenLength': token.length,
          'tokenPrefix': token.substring(
            0,
            token.length > 12 ? 12 : token.length,
          ),
          'enableVideo': enableVideo,
          'isInitialized': _initialized,
          'alreadyJoined': _joined,
          'source': 'render_backend',
        },
      );
      // #endregion

      await _engine!.joinChannel(
        token: token,
        channelId: channelId,
        uid: _localUid,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishMicrophoneTrack: true,
          // Kamera istifadəçi açana qədər yayımlanmır
          publishCameraTrack: false,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[Agora] joinChannel failed: $e');
      return false;
    }
  }

  /// Mikrofonu susdurur/açır. Nəticə: uğurlu mu?
  Future<bool> muteLocalAudio(bool muted) async {
    _isMicMuted = muted;
    if (_engine == null || !_joined) return true; // state hələ tətbiq olunacaq
    try {
      await _engine!.muteLocalAudioStream(muted);
      await _updateMediaOptions(
        publishCameraTrack: _isCameraOn,
        publishMicrophoneOverride: !muted,
      );
      return true;
    } catch (e) {
      debugPrint('[Agora] muteLocalAudio failed: $e');
      return false;
    }
  }

  /// Kameranı açır/bağlayır (Discord tipli toggle).
  Future<bool> setCameraEnabled(bool enabled) async {
    if (!_isVideoRoom || _engine == null) return false;
    if (enabled && !_hasCameraPermission) {
      final camStatus = await Permission.camera.request();
      _hasCameraPermission = camStatus.isGranted;
      if (!_hasCameraPermission) {
        debugPrint('[Agora] Camera permission denied on toggle');
        return false;
      }
    }
    try {
      if (enabled) {
        await _engine!.enableLocalVideo(true);
        await _engine!.startPreview();
        if (_joined) {
          await _engine!.muteLocalVideoStream(false);
          await _updateMediaOptions(publishCameraTrack: true);
        }
      } else {
        if (_joined) {
          await _updateMediaOptions(publishCameraTrack: false);
          await _engine!.muteLocalVideoStream(true);
        }
        await _engine!.stopPreview();
        await _engine!.enableLocalVideo(false);
      }
      _isCameraOn = enabled;
      return true;
    } catch (e) {
      debugPrint('[Agora] setCameraEnabled failed: $e');
      return false;
    }
  }

  /// Ön/arxa kamera dəyişdirir. Nəticə: yeni ön kamera vəziyyəti.
  Future<bool> switchCamera() async {
    if (_engine == null || !_isCameraOn) return _isFrontCamera;
    try {
      await _engine!.switchCamera();
      _isFrontCamera = !_isFrontCamera;
      return _isFrontCamera;
    } catch (e) {
      debugPrint('[Agora] switchCamera failed: $e');
      return _isFrontCamera;
    }
  }

  /// Hoparlör/qulaqlıq keçidi. Nəticə: uğurlu mu?
  Future<bool> setSpeakerOn(bool on) async {
    _isSpeakerOn = on;
    if (_engine == null || !_joined) return true;
    try {
      await _engine!.setEnableSpeakerphone(on);
      return true;
    } catch (e) {
      debugPrint('[Agora] setSpeakerOn failed: $e');
      return false;
    }
  }

  Future<void> _updateMediaOptions({
    required bool publishCameraTrack,
    bool? publishMicrophoneOverride,
  }) async {
    await _engine?.updateChannelMediaOptions(
      ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishMicrophoneTrack: publishMicrophoneOverride ?? !_isMicMuted,
        publishCameraTrack: publishCameraTrack,
      ),
    );
  }

  /// Kanaldan çıxır və motoru buraxır. Təkrar çağrış təhlükəsizdir.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _cleanupEngine();
  }

  Future<void> _cleanupEngine() async {
    try {
      await _engine?.leaveChannel();
    } catch (_) {}
    try {
      await _engine?.stopPreview();
    } catch (_) {}
    try {
      await _engine?.release();
    } catch (_) {}
    _engine = null;
    _initialized = false;
    _joined = false;
    _isCameraOn = false;
    _isMicMuted = false;
    _remoteUids.clear();
    _remoteVideoOn.clear();
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
