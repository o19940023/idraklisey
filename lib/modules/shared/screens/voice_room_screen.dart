import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../data/models/meet_model.dart';
import '../../../services/agora_service.dart';
import '../../../services/agora_token_generator.dart';
import '../../../services/agora_token_service.dart';
import '../../../l10n/app_localizations.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Discord tipli canlı dərs otağı: görüntülü odlarda video grid (kamera
/// açıq olanlar video, bağlı olanlar avatar), səsli odlarda avatar grid.
/// Agora RTC ilə real səs/video.
class VoiceRoomScreen extends StatefulWidget {
  final MeetRoom room;

  const VoiceRoomScreen({super.key, required this.room});

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen>
    with SingleTickerProviderStateMixin {
  late Timer _durationTimer;
  int _secondsElapsed = 0;
  bool _isLocalMuted = false;
  bool _isCameraOn = false;
  bool _isSpeakerOn = true;
  bool _isHandRaised = false;
  bool _isConnected = false;
  String? _focusedUserId; // Spotlight / Focus mode
  final Set<String> _speakingUserIds = {};
  late AppState _appState;

  // 🎥 AGORA RTC ENGINE (real səs + video)
  final AgoraService _agoraService = AgoraService();
  bool _isAgoraInitialized = false;
  bool _isJoiningVoiceChannel = false;
  final Set<int> _remoteUids = {};
  final Map<int, bool> _remoteVideoOn = {};
  DateTime _lastAgoraErrorTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _invalidTokenCount = 0;
  Timer? _joinWatchdog;
  String _lastConnState = 'DISCONNECTED';
  String _lastConnReason = '';

  /// Join uğursuz oldu (token şəbəkə və ya ICE xətası) — istifadəçiyə
  /// "yenidən cəhd et" düyməsi göstərilir.
  bool _joinFailed = false;

  /// Watchdog işə düşəndə avtomatik təkrar cəhd sayı (yalnız 1 dəfə).
  int _autoRetries = 0;

  bool get _isVideoRoom => widget.room.hasVideo;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });

    _appState = Provider.of<AppState>(context, listen: false);
    _appState.addListener(_syncForcedMuteState);

    // 🎥 Initialize Agora RTC Engine
    unawaited(_initializeAgoraAndJoin());

    // Firebase presence registration
    unawaited(_registerMeetPresence(_appState));
  }

  /// 🎥 Initialize Agora RTC Engine and join channel
  Future<void> _initializeAgoraAndJoin() async {
    _invalidTokenCount = 0;
    _joinWatchdog?.cancel();
    setState(() {
      _isJoiningVoiceChannel = true;
      _joinFailed = false;
    });

    try {
      // Step 1: Initialize Agora (görüntülü otaqdursa video da açılır)
      final initialized = await _agoraService.initialize(
        enableVideo: _isVideoRoom,
      );
      if (!initialized) {
        throw Exception(
          'Agora initialization failed - Microphone permission denied',
        );
      }

      setState(() => _isAgoraInitialized = true);

      // Step 2: Setup callbacks for speaking detection
      _agoraService.onAudioVolumeIndication = (speakers, totalVolume) {
        if (!mounted) return;
        final newSpeaking = <String>{};
        for (var speaker in speakers) {
          if ((speaker.volume ?? 0) > 10) {
            final agoraUid = speaker.uid ?? 0;
            final userId = _userIdForAgoraUid(agoraUid);
            if (userId != null) {
              newSpeaking.add(userId);
            }
          }
        }
        if (!setEquals(_speakingUserIds, newSpeaking)) {
          setState(() {
            _speakingUserIds.clear();
            _speakingUserIds.addAll(newSpeaking);
          });
        }
      };

      // Step 3: Setup video / participant callbacks
      _agoraService.onUserJoined = (uid) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _remoteUids.add(uid));
          }
        });
      };
      _agoraService.onUserOffline = (uid, reason) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _remoteUids.remove(uid);
              _remoteVideoOn.remove(uid);
            });
          }
        });
      };
      _agoraService.onRemoteVideoStateChanged = (uid, videoOn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _remoteVideoOn[uid] = videoOn);
          }
        });
      };
      _agoraService.onJoinSuccess = () {
        _joinWatchdog?.cancel();
        _autoRetries = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isConnected = true);
        });
      };

      // Connection state tracking — iOS join takılmasını görünür etmək üçün
      _agoraService.onConnectionStateChanged = (state, reason) {
        _lastConnState = state.name;
        _lastConnReason = reason.name;
        if (state == ConnectionStateType.connectionStateConnected) {
          _joinWatchdog?.cancel();
          _autoRetries = 0;
          if (mounted && !_isConnected) {
            setState(() => _isConnected = true);
          }
        }
      };

      // Step 4: Setup error handler (throttled — spam'ı önlə)
      _agoraService.onError = (err, msg) async {
        debugPrint('⚠️ Agora error: $err - $msg');

        final now = DateTime.now();
        final isThrottled =
            now.difference(_lastAgoraErrorTime).inMilliseconds < 2500;
        _lastAgoraErrorTime = now;

        // errInvalidToken xüsusi işlə: 1-2 dəfə səsli retry, sonra çıxış
        if (err == ErrorCodeType.errInvalidToken ||
            err == ErrorCodeType.errTokenExpired) {
          _invalidTokenCount++;
          if (_invalidTokenCount <= 2) {
            debugPrint(
              '[Agora] Token xətası ($_invalidTokenCount/2) — fresh token ilə rejoin',
            );
            try {
              await _agoraService.dispose();
            } catch (_) {}
            if (mounted) {
              setState(() {
                _isAgoraInitialized = false;
                _isConnected = false;
              });
              unawaited(_initializeAgoraAndJoin());
            }
            return;
          }
        }

        if (isThrottled) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          String? userMsg;
          if (err == ErrorCodeType.errInvalidToken ||
              err == ErrorCodeType.errTokenExpired) {
            userMsg = 'Bağlantı tokeni keçərsizdir — otağı yenidən açın.';
          } else if (err == ErrorCodeType.errJoinChannelRejected) {
            userMsg = 'Otağa qoşulma rədd edildi — internetinizi yoxlayın.';
          } else if (err == ErrorCodeType.errInvalidAppId) {
            userMsg = 'Sistem konfiqurasiyası səhvidir — administratora müraciət edin.';
          } else if (err == ErrorCodeType.errNotInitialized) {
            userMsg = 'Video motoru hazır deyil — biraz gözləyin.';
          } else {
            userMsg = msg.isNotEmpty
                ? 'Bağlantı xətası: $msg'
                : 'Bağlantı xətası baş verdi — yenidən cəhd edin.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userMsg),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 4),
            ),
          );
        });
      };

      // Step 5: Join channel
      final userId = _appState.currentUser?.id ?? _appState.student.id;
      debugPrint('🔑 [DIAG] Joining Agora channel: channelId=${widget.room.id}, userId=$userId');
      final joined = await _agoraService.joinChannel(
        channelId: widget.room.id,
        userId: userId,
        enableVideo: _isVideoRoom,
      );

      if (!joined) {
        throw Exception('Failed to join voice channel');
      }

      // Join çağırışı qəbul olundu, amma connection callback gəlməyə bilər
      // (iOS real cihazda müşahidə olunur) — 20 saniyə içində bağlanmasa
      // avtomatik bir dəfə təkrar cəhd edilir; sonra görünən teşhis.
      _joinWatchdog?.cancel();
      _joinWatchdog = Timer(const Duration(seconds: 20), () {
        if (!mounted || _isConnected) return;
        debugPrint(
          '⚠️ [DIAG] Agora join watchdog: still not connected. '
          'state=$_lastConnState reason=$_lastConnReason',
        );
        if (_autoRetries < 1) {
          // Şəbəkə/ICE ilk qoşulmada takıla bilər — təmiz motorla bir dəfə
          // avtomatik yenidən cəhd et (istifadəçiyə toxunulmadan).
          _autoRetries++;
          debugPrint('♻️ [Agora] Auto-retry join ($_autoRetries/1)');
          unawaited(_rejoinWithFreshEngine());
          return;
        }
        if (mounted) setState(() => _joinFailed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aqroraya bağlana bilmədi (vəziyyət: $_lastConnState'
              '${_lastConnReason.isNotEmpty ? ' / $_lastConnReason' : ''}). '
              'Wi-Fi şəbəkəsi Aqroranın trafikini (UDP) blokla ya bilər — '
              'mobil internetlə yenidən cəhd edin.',
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 8),
          ),
        );
      });

      debugPrint(
        '✓ [DIAG] Successfully joined Agora channel: ${widget.room.id} '
        '(localUid=${_agoraService.localUid}, video: $_isVideoRoom)',
      );
    } catch (e) {
      debugPrint('⚠️ Agora setup failed: $e');
      if (mounted) {
        setState(() => _joinFailed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Otağa qoşula bilmədiniz: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoiningVoiceChannel = false);
      }
    }
  }

  /// Motoru tam söküb təzə token ilə yenidən qoşulur (watchdog və ya
  /// istifadəçinin "yenidən cəhd et" toxunması ilə).
  Future<void> _rejoinWithFreshEngine() async {
    try {
      await _agoraService.dispose();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isAgoraInitialized = false;
      _isConnected = false;
    });
    await _initializeAgoraAndJoin();
  }

  /// İstifadəçi pill-ə toxunaraq əl ilə retry edir.
  Future<void> _manualRetryJoin() async {
    _autoRetries = 0;
    await _rejoinWithFreshEngine();
  }

  /// Agora rəqəmsal uid-inə uyğun iştirakçının userId-sini tapır
  /// Agora bəzi hallarda yerli istifadəçi üçün uid=0 göndərə bilər —
  /// bu halda cari istifadəçi kimi qəbul edirik.
  String? _userIdForAgoraUid(int agoraUid) {
    if (agoraUid == 0) {
      return _appState.currentUser?.id ?? _appState.student.id;
    }
    for (final p in _appState
        .meetRooms
        .where((r) => r.id == widget.room.id)
        .map((r) => r.participants)
        .expand((list) => list)) {
      if (AgoraTokenGenerator.uidFromUserId(p.userId) == agoraUid) {
        return p.userId;
      }
    }
    return 'agora_$agoraUid';
  }

  Future<void> _registerMeetPresence(AppState appState) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await appState
            .joinMeetRoom(widget.room.id)
            .timeout(const Duration(seconds: 20));
        debugPrint('✓ Meet presence registered successfully');
        return;
      } catch (error) {
        debugPrint(
          'Meet presence attempt ${attempt + 1}/5 failed; retrying: $error',
        );
        if (attempt < 4) {
          await Future<void>.delayed(Duration(seconds: 3 * (attempt + 1)));
        }
      }
    }

    // ⚠️ IMPROVED ERROR HANDLING
    debugPrint('⚠️ Meet presence registration failed after 5 attempts');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Otağa qoşula bilmədiniz. Zəhmət olmasa yenidən cəhd edin.',
          ),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 5),
        ),
      );

      // Exit after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  void _syncForcedMuteState() {
    final userId = _appState.currentUser?.id ?? _appState.student.id;
    final room = _appState.meetRooms.firstWhere(
      (item) => item.id == widget.room.id,
      orElse: () => widget.room,
    );
    final participant = room.participants
        .where((item) => item.userId == userId)
        .firstOrNull;
    if (participant == null || participant.isMutedByHost == _isLocalMuted) {
      return;
    }
    if (mounted) {
      setState(() {
        _isLocalMuted = participant.isMutedByHost;
        _agoraService.muteLocalAudio(_isLocalMuted);
      });
    }
  }

  @override
  void dispose() {
    _durationTimer.cancel();
    _joinWatchdog?.cancel();
    _pulseController.dispose();
    _appState.removeListener(_syncForcedMuteState);
    _appState.leaveMeetRoom(widget.room.id);

    // 🎥 Cleanup Agora resources
    unawaited(_agoraService.dispose());

    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggleMute() async {
    final appState = _appState;
    final userId = appState.currentUser?.id ?? appState.student.id;
    final room = appState.meetRooms.firstWhere(
      (item) => item.id == widget.room.id,
      orElse: () => widget.room,
    );
    final me = room.participants
        .where((participant) => participant.userId == userId)
        .firstOrNull;
    if (me?.isMutedByHost ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Müəllim mikrofonunuzu müvəqqəti bağlayıb.'),
        ),
      );
      return;
    }

    final newMuted = !_isLocalMuted;

    // 🎥 Toggle microphone in Agora
    final ok = await _agoraService.muteLocalAudio(newMuted);

    // Update Firebase state
    await appState.toggleMyMuteInRoom(widget.room.id);

    if (mounted) {
      setState(() => _isLocalMuted = ok ? newMuted : _isLocalMuted);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofon dəyişdirilə bilmədi, yenidən cəhd edin.'),
          ),
        );
      }
    }
  }

  Future<void> _toggleCamera() async {
    final target = !_isCameraOn;
    final ok = await _agoraService.setCameraEnabled(target);
    if (mounted) {
      if (ok) {
        setState(() => _isCameraOn = target);
      } else {
        String msg;
        final camPermission = await Permission.camera.status;
        if (target && !camPermission.isGranted) {
          msg = 'Kamera icazəsi verilməyib. Tənzimləmələrdən kamera icazəsini açın.';
        } else if (!_isConnected) {
          msg = 'Hələ otağa qoşulmadınız — biraz gözləyin və yenidən cəhd edin.';
        } else {
          msg = target
              ? 'Kamera açıla bilmədi — cihazın kamera modülünü yoxlayın.'
              : 'Kamera bağlanıla bilmədi.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tənzimləmələr',
              textColor: Colors.white,
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    final isFront = await _agoraService.switchCamera();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFront ? 'Ön kamera' : 'Arxa kamera'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    }
  }

  Future<void> _toggleSpeaker() async {
    final target = !_isSpeakerOn;
    final ok = await _agoraService.setSpeakerOn(target);
    if (mounted && ok) setState(() => _isSpeakerOn = target);
  }

  void _leaveRoom() async {
    final currentUserId = _appState.currentUser?.id ?? _appState.student.id;
    final isHost = widget.room.hostId == currentUserId;
    if (isHost) {
      _showEndMeetingDialog();
      return;
    }
    await _appState.leaveMeetRoom(widget.room.id);
    if (mounted) handleBackNavigation(context);
  }

  void _showParticipantOptions(
    MeetParticipant participant,
    bool isHost,
    String hostId,
  ) {
    if (!isHost) return;
    final loc = AppLocalizations.of(context);
    final appState = Provider.of<AppState>(context, listen: false);
    final isTargetHost = participant.userId == hostId;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                  participant.photoUrl ??
                      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                participant.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${participant.role == 'host' ? 'Host (Müəllim)' : (participant.role == 'teacher' ? loc.teacher : loc.student)} • ${participant.className ?? 'İdrak'}',
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),

              if (!isTargetHost) ...[
                ListTile(
                  leading: Icon(
                    participant.isMuted
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    color: participant.isMuted
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  title: Text(
                    participant.isMuted
                        ? loc.unmute
                        : loc.mute,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    participant.isMuted
                        ? 'Şagirdin danışmasına icazə ver'
                        : 'Şagirdin mikrofonunu məcburi bağla',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final newMute = !participant.isMuted;
                    await appState.setParticipantMuteByHost(
                      widget.room.id,
                      participant.userId,
                      newMute,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${participant.fullName} ${newMute ? 'susduruldu' : 'səsi açıldı'}',
                          ),
                          backgroundColor: newMute
                              ? AppColors.danger
                              : AppColors.success,
                        ),
                      );
                    }
                  },
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(
                    Icons.person_remove_rounded,
                    color: AppColors.danger,
                  ),
                  title: Text(
                    'Otaqdan Çıxar',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'İştirakçını bu toplantıdan uzaqlaşdır',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await appState.setParticipantMuteByHost(
                      widget.room.id,
                      participant.userId,
                      true,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${participant.fullName} otaqdan uzaqlaşdırıldı',
                          ),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  },
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Bu istifadəçi otağın təşkilatçısıdır (Host).',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showMuteAllDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(Icons.volume_off_rounded, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                'Hamını Susdur?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Bütün şagird və iştirakçıların mikrofonları bağlanacaq. Yalnız siz danışa biləcəksiniz.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                loc.cancel,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final appState = Provider.of<AppState>(context, listen: false);
                await appState.muteAllInRoom(widget.room.id, true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bütün iştirakçılar susduruldu'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
              child: Text(
                'Hamısını Susdur',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEndMeetingDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(Icons.call_end_rounded, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                'Toplantını Bitir?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Bu görüş bütün iştirakçılar üçün sonlandırılacaq və otaq bağlanacaq.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                loc.cancel,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final appState = Provider.of<AppState>(context, listen: false);
                await appState.endMeetRoom(widget.room.id);
                if (mounted) Navigator.pop(context);
              },
              child: Text(
                'Toplantını Bitir',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showGuestLinkSheet(BuildContext context) {
    final guestUrl = AgoraTokenService.getGuestJoinUrl(widget.room.id);
    final limitStr = widget.room.guestLimit == 0
        ? 'Limitsiz'
        : '${widget.room.guestLimit} nəfər';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.qr_code_rounded,
                        color: AppColors.primaryAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Qonaq Veb Dəvət Linki',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Maksimum limit: $limitStr',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, color: AppColors.primaryAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          guestUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '💡 Qonaqlar tətbiq olmadan brauzerdən dərhal kamera və səslə qoşula bilər. Görüş bitdikdə link avtomatik ləğv edilir.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(160),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: guestUrl));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Qonaq linki kopyalandı!'),
                              backgroundColor: AppColors.success,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Linki Kopyala',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<MeetParticipant> _participantsForDisplay(
    MeetRoom room,
    AppState appState,
    String currentUserId,
  ) {
    final participants = List<MeetParticipant>.from(room.participants);
    final includesMe = participants.any((p) => p.userId == currentUserId);
    if (!includesMe) {
      final currentUser = appState.currentUser;
      participants.add(
        MeetParticipant(
          userId: currentUserId,
          fullName: currentUser?.fullName ?? appState.student.fullName,
          role: room.hostId == currentUserId
              ? 'host'
              : (currentUser?.role == UserRole.teacher ? 'teacher' : 'student'),
          photoUrl: currentUser?.photoUrl ?? appState.student.photoUrl,
          className: currentUser?.className ?? appState.student.className,
        ),
      );
    }

    // Dynamic: Include all connected Agora participants (e.g. Web Guests)
    for (final remoteUid in _remoteUids) {
      final isAlreadyInList = participants.any((p) {
        if (p.userId.startsWith('agora_')) {
          final uid = int.tryParse(p.userId.replaceFirst('agora_', ''));
          return uid == remoteUid;
        }
        return AgoraTokenGenerator.uidFromUserId(p.userId) == remoteUid;
      });

      if (!isAlreadyInList) {
        participants.add(
          MeetParticipant(
            userId: 'agora_$remoteUid',
            fullName: 'Qonaq (#${remoteUid % 10000})',
            role: 'guest',
            photoUrl:
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
            className: 'Veb Qonaq',
          ),
        );
      }
    }

    return participants..sort((a, b) {
      final aIsHost = a.userId == room.hostId;
      final bIsHost = b.userId == room.hostId;
      if (aIsHost != bIsHost) return aIsHost ? -1 : 1;
      return a.joinedAt.compareTo(b.joinedAt);
    });
  }

  /// İştirakçının kamerası hal-hazırda açıqdımı? (mən: yerli vəziyyət,
  /// digərlər: Agora uzaq video vəziyyəti)
  bool _isVideoActiveFor(MeetParticipant p, String currentUserId) {
    if (!_isVideoRoom) return false;
    if (p.userId == currentUserId) return _isCameraOn;
    final int uid;
    if (p.userId.startsWith('agora_')) {
      uid = int.tryParse(p.userId.replaceFirst('agora_', '')) ?? 0;
    } else {
      uid = AgoraTokenGenerator.uidFromUserId(p.userId);
    }
    return _remoteVideoOn[uid] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = Provider.of<AppState>(context);
    final currentUserId = appState.currentUser?.id ?? appState.student.id;

    final currentRoom = appState.meetRooms.firstWhere(
      (r) => r.id == widget.room.id,
      orElse: () => widget.room,
    );

    final isHost = currentRoom.hostId == currentUserId;
    final participants = _participantsForDisplay(
      currentRoom,
      appState,
      currentUserId,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF111214), // Discord Pure Dark
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1F22), // Discord Topbar
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
          onPressed: _leaveRoom,
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentRoom.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isConnected
                          ? const Color(0xFF23A55A) // Discord Green
                          : AppColors.goldLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '${currentRoom.subject} • ${_formatDuration(_secondsElapsed)} • ${participants.length} İştirakçı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (widget.room.allowGuestLink || isHost)
            IconButton(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryAccent.withAlpha(60),
                  ),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.primaryAccent,
                  size: 16,
                ),
              ),
              tooltip: 'Qonaq Linkini Paylaş',
              onPressed: () => _showGuestLinkSheet(context),
            ),
          if (isHost) ...[
            IconButton(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.volume_off_rounded,
                  color: AppColors.goldLight,
                  size: 16,
                ),
              ),
              tooltip: 'Hamını Susdur',
              onPressed: _showMuteAllDialog,
            ),
            IconButton(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: AppColors.danger,
                  size: 16,
                ),
              ),
              tooltip: 'Toplantını Bitir',
              onPressed: _showEndMeetingDialog,
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Host Alert Banner
          if (isHost)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE75C).withAlpha(18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFEE75C).withAlpha(45),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Color(0xFFFEE75C),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Siz Hostsunuz • Toxunaraq böyüdün, basıb saxlayaraq səsi idarə edin',
                      style: TextStyle(
                        color: Color(0xFFFEE75C),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Participants Area (Spotlight View or Balanced Grid View)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Stack(
                children: [
                  Builder(
                    builder: (context) {
                      final hasSpotlight = _focusedUserId != null &&
                          participants.any((p) => p.userId == _focusedUserId);

                      if (hasSpotlight) {
                        final focusedP = participants.firstWhere(
                          (p) => p.userId == _focusedUserId,
                        );
                        final others = participants
                            .where((p) => p.userId != _focusedUserId)
                            .toList();

                        return Column(
                          children: [
                            // 🌟 Spotlight / Big Stage View
                            Expanded(
                              flex: 4,
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _focusedUserId = null);
                                    },
                                    onLongPress: () {
                                      if (isHost) {
                                        _showParticipantOptions(
                                          focusedP,
                                          isHost,
                                          currentRoom.hostId,
                                        );
                                      }
                                    },
                                    child: _buildParticipantTile(
                                      participant: focusedP,
                                      isMe: focusedP.userId == currentUserId,
                                      isHost:
                                          focusedP.userId == currentRoom.hostId,
                                      isSpeaking: _speakingUserIds
                                          .contains(focusedP.userId),
                                      videoActive: _isVideoActiveFor(
                                        focusedP,
                                        currentUserId,
                                      ),
                                      loc: loc,
                                      isSpotlight: true,
                                    ),
                                  ),

                                  // Floating Un-Spotlight Pill
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() => _focusedUserId = null);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(180),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border:
                                              Border.all(color: Colors.white24),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.grid_view_rounded,
                                              color: Colors.white,
                                              size: 13,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'Gridə qayıt',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 📱 Horizontal Mini Strip for Other Participants
                            if (others.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 105,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: others.length,
                                  separatorBuilder: (ctx, idx) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, idx) {
                                    final op = others[idx];
                                    return SizedBox(
                                      width: 100,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(
                                            () => _focusedUserId = op.userId,
                                          );
                                        },
                                        onLongPress: () {
                                          if (isHost) {
                                            _showParticipantOptions(
                                              op,
                                              isHost,
                                              currentRoom.hostId,
                                            );
                                          }
                                        },
                                        child: _buildParticipantTile(
                                          participant: op,
                                          isMe: op.userId == currentUserId,
                                          isHost:
                                              op.userId == currentRoom.hostId,
                                          isSpeaking: _speakingUserIds
                                              .contains(op.userId),
                                          videoActive: _isVideoActiveFor(
                                            op,
                                            currentUserId,
                                          ),
                                          loc: loc,
                                          isCompact: true,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        );
                      }

                      // 🔲 Balanced Grid View (Normal)
                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: participants.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: participants.length == 1 ? 1 : 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: participants.length == 1
                              ? (_isVideoRoom ? 1.1 : 1.3)
                              : (_isVideoRoom ? 0.85 : 0.95),
                        ),
                        itemBuilder: (context, index) {
                          final p = participants[index];
                          final isMe = p.userId == currentUserId;
                          final isParticipantHost =
                              p.userId == currentRoom.hostId;
                          final isParticipantSpeaking =
                              _speakingUserIds.contains(p.userId);
                          final videoActive =
                              _isVideoActiveFor(p, currentUserId);

                          return GestureDetector(
                            onTap: () {
                              setState(() => _focusedUserId = p.userId);
                            },
                            onLongPress: () {
                              if (isHost) {
                                _showParticipantOptions(
                                  p,
                                  isHost,
                                  currentRoom.hostId,
                                );
                              }
                            },
                            child: _buildParticipantTile(
                              participant: p,
                              isMe: isMe,
                              isHost: isParticipantHost,
                              isSpeaking: isParticipantSpeaking,
                              videoActive: videoActive,
                              loc: loc,
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Connection indicator banner
                  if (_isJoiningVoiceChannel || !_isConnected)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      child: Center(
                        child: _joinFailed
                            ? GestureDetector(
                                onTap: _manualRetryJoin,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF111214).withAlpha(235),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: AppColors.danger.withAlpha(90),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.wifi_off_rounded,
                                        color: AppColors.danger,
                                        size: 14,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Bağlantı alınmadı — toxunub yenidən cəhd edin',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.refresh_rounded,
                                        color: AppColors.danger,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111214).withAlpha(230),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 13,
                                      height: 13,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF23A55A),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _autoRetries > 0
                                          ? 'Yenidən qoşulur...'
                                          : 'Agora kanalına qoşulur...',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          _buildControlDock(isHost),
        ],
      ),
    );
  }

  // ────────────────────────── PARTICIPANT TILE ──────────────────────────

  Widget _buildParticipantTile({
    required MeetParticipant participant,
    required bool isMe,
    required bool isHost,
    required bool isSpeaking,
    required bool videoActive,
    required AppLocalizations loc,
    bool isSpotlight = false,
    bool isCompact = false,
  }) {
    final engine = _agoraService.engine;
    final int agoraUid;
    if (participant.userId.startsWith('agora_')) {
      agoraUid = int.tryParse(participant.userId.replaceFirst('agora_', '')) ?? 0;
    } else {
      agoraUid = AgoraTokenGenerator.uidFromUserId(participant.userId);
    }

    Widget? videoLayer;
    if (videoActive && engine != null && _isAgoraInitialized) {
      videoLayer = ClipRRect(
        borderRadius: BorderRadius.circular(isCompact ? 12 : 18),
        child: isMe
            ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
            : AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: engine,
                  canvas: VideoCanvas(uid: agoraUid),
                  connection: RtcConnection(channelId: widget.room.id),
                ),
              ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glow = isSpeaking ? (_pulseController.value * 8 + 4) : 0.0;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F22), // Discord Card Dark
            borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
            border: Border.all(
              color: isSpeaking
                  ? const Color(0xFF23A55A) // Discord Speaking Green
                  : (isHost
                      ? const Color(0xFFFEE75C).withAlpha(140) // Discord Gold
                      : (isSpotlight
                          ? AppColors.primaryAccent.withAlpha(120)
                          : Colors.white12)),
              width: isSpeaking ? 2.5 : (isSpotlight ? 2 : 1),
            ),
            boxShadow: isSpeaking
                ? [
                    BoxShadow(
                      color: const Color(0xFF23A55A).withAlpha(120),
                      blurRadius: glow,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video Layer or Avatar
              if (videoLayer != null)
                Positioned.fill(child: videoLayer)
              else
                Padding(
                  padding: EdgeInsets.all(isCompact ? 6 : (isSpotlight ? 16 : 10)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSpeaking)
                            Container(
                              width: isCompact ? 44 : (isSpotlight ? 96 : 64),
                              height: isCompact ? 44 : (isSpotlight ? 96 : 64),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF23A55A).withAlpha(140),
                                  width: 3,
                                ),
                              ),
                            ),
                          CircleAvatar(
                            radius: isCompact ? 18 : (isSpotlight ? 42 : 26),
                            backgroundImage: NetworkImage(
                              participant.photoUrl ??
                                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isCompact ? 4 : 6),

                      // Full Name
                      Text(
                        isMe
                            ? '${participant.fullName} (Siz)'
                            : participant.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 10 : (isSpotlight ? 15 : 12),
                          fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 3),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isHost
                                ? const Color(0xFFFEE75C).withAlpha(25)
                                : (participant.role == 'teacher'
                                    ? AppColors.primaryAccent.withAlpha(25)
                                    : Colors.white.withAlpha(12)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isHost
                                ? '👑 Host'
                                : (participant.role == 'teacher'
                                    ? '👨‍🏫 ${loc.teacher}'
                                    : (participant.className ??
                                        '🎓 ${loc.student}')),
                            style: TextStyle(
                              color: isHost
                                  ? const Color(0xFFFEE75C)
                                  : (participant.role == 'teacher'
                                      ? AppColors.primaryAccent
                                      : Colors.white70),
                              fontSize: isSpotlight ? 11 : 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Video rejimində ad pill (aşağıda)
              if (videoLayer != null)
                Positioned(
                  left: 8,
                  bottom: 8,
                  right: isCompact ? 8 : 34,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 5 : 8,
                      vertical: isCompact ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111214).withAlpha(200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isHost) ...[
                          const Text('👑', style: TextStyle(fontSize: 9)),
                          const SizedBox(width: 3),
                        ],
                        Expanded(
                          child: Text(
                            isMe
                                ? '${participant.fullName} (Siz)'
                                : participant.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isCompact ? 9 : 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Mic Status Icon
              Positioned(
                top: isCompact ? 5 : 8,
                right: isCompact ? 5 : 8,
                child: Container(
                  padding: EdgeInsets.all(isCompact ? 3 : 5),
                  decoration: BoxDecoration(
                    color: participant.isMuted
                        ? const Color(0xFFDA373C) // Discord Red
                        : const Color(0xFF23A55A).withAlpha(40), // Discord Green
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: participant.isMuted
                          ? const Color(0xFFDA373C)
                          : const Color(0xFF23A55A),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    participant.isMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
                    size: isCompact ? 9 : 11,
                  ),
                ),
              ),

              // Local Camera Flip Shortcut Button
              if (isMe && _isCameraOn && !isCompact)
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: _switchCamera,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(170),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Icon(
                        Icons.cameraswitch_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ────────────────────────── CONTROL DOCK ──────────────────────────

  Widget _buildControlDock(bool isHost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withAlpha(15)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. Mic Mute / Unmute Button (Primary Large)
            _DockButton(
              size: 56,
              label: _isLocalMuted ? 'Səssiz' : 'Danışırsınız',
              labelColor: _isLocalMuted ? Colors.white60 : AppColors.success,
              background: _isLocalMuted
                  ? AppColors.danger
                  : AppColors.success,
              icon: _isLocalMuted
                  ? Icons.mic_off_rounded
                  : Icons.mic_rounded,
              onTap: _toggleMute,
            ),

            // 2. Camera Toggle (yalnız görüntülü otaqlarda)
            if (_isVideoRoom) ...[
              _DockButton(
                size: 48,
                label: _isCameraOn ? 'Kamera açıq' : 'Kamera bağlı',
                labelColor: _isCameraOn
                    ? AppColors.primaryAccent
                    : Colors.white70,
                background: _isCameraOn
                    ? AppColors.primaryAccent
                    : Colors.white.withAlpha(15),
                iconBorder: _isCameraOn
                    ? null
                    : Border.all(color: Colors.white24),
                icon: _isCameraOn
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                onTap: _toggleCamera,
                onLongPress: _isCameraOn ? _switchCamera : null,
              ),

              // 2.1 Explicit Camera Flip / Switch Button
              if (_isCameraOn)
                _DockButton(
                  size: 48,
                  label: 'Çevir',
                  labelColor: AppColors.primaryAccent,
                  background: AppColors.primaryAccent.withAlpha(25),
                  iconBorder: Border.all(
                    color: AppColors.primaryAccent.withAlpha(70),
                  ),
                  icon: Icons.cameraswitch_rounded,
                  iconColor: AppColors.primaryAccent,
                  onTap: _switchCamera,
                ),
            ],

            // 3. Speaker Toggle (hoparlör/qulaqlıq)
            _DockButton(
              size: 48,
              label: _isSpeakerOn ? 'Hoparlör' : 'Qulaqlıq',
              labelColor: _isSpeakerOn ? AppColors.goldLight : Colors.white70,
              background: _isSpeakerOn
                  ? AppColors.gold.withAlpha(40)
                  : Colors.white.withAlpha(15),
              iconBorder: _isSpeakerOn
                  ? Border.all(color: AppColors.gold.withAlpha(80))
                  : Border.all(color: Colors.white24),
              icon: _isSpeakerOn
                  ? Icons.volume_up_rounded
                  : Icons.hearing_rounded,
              onTap: _toggleSpeaker,
            ),

            // 4. Raise Hand Button
            _DockButton(
              size: 48,
              label: _isHandRaised ? 'Əl aktiv' : 'Əl qaldır',
              labelColor: _isHandRaised
                  ? AppColors.goldLight
                  : Colors.white70,
              background: _isHandRaised
                  ? AppColors.gold.withAlpha(40)
                  : Colors.white.withAlpha(15),
              iconBorder: Border.all(
                color: _isHandRaised ? AppColors.gold : Colors.white24,
              ),
              icon: Icons.front_hand_rounded,
              iconColor: _isHandRaised ? AppColors.goldLight : Colors.white,
              onTap: () {
                setState(() => _isHandRaised = !_isHandRaised);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isHandRaised
                          ? 'Əl qaldırdınız ✋'
                          : 'Əlinizi endirdiniz',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),

            // 5. Leave Meeting (Red Button)
            _DockButton(
              size: 48,
              label: 'Çıxış',
              labelColor: AppColors.danger,
              background: AppColors.danger.withAlpha(25),
              iconBorder: Border.all(color: AppColors.danger.withAlpha(60)),
              icon: Icons.call_end_rounded,
              iconColor: AppColors.danger,
              onTap: _leaveRoom,
            ),
          ],
        ),
      ),
    );
  }
}

/// Alt idarəetmə panelindəki düymə (Discord tipli yumru düymə + etiket)
class _DockButton extends StatelessWidget {
  final double size;
  final String label;
  final Color labelColor;
  final Color background;
  final Color iconColor;
  final Border? iconBorder;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _DockButton({
    required this.size,
    required this.label,
    required this.labelColor,
    required this.background,
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
    this.iconBorder,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: background,
              border: iconBorder,
              boxShadow: size > 50
                  ? [
                      BoxShadow(
                        color: background.withAlpha(100),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: iconColor, size: size > 50 ? 26 : 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: labelColor,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
