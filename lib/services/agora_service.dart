import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'agora_token_service.dart';

/// Gerçek Agora RTC Motoru sarmalayıcısı (agora_rtc_engine 6.x).
///
/// - Kanala token ilə qoşulma (AccessToken2, backend tərəfindən yaradılır)
/// - Səs + video (kamera aç/bağla, ön/arxa kamera, hoparlör)
/// - Konuşan istifadəçi aşkarlaması (həcm indikasiyası)
/// - Uzaqdan video vəziyyəti, token yenilənməsi, təmizlənmə
class AgoraService {
  static const String appId = '045bdb3866464fb6b47009e8044ce57e';

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
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          // Bütün bölgələrdəki edge serverlər istifadə olunsun — ayrı-ayrı
          // ISP/lər üçün area yoxlaması kaynaklı qoşulma gecikmələrini aradan
          // qaldırır (iOS real cihazda müşahidə olunub).
          areaCode: AreaCode.areaCodeGlob.value(),
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
}
