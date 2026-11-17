import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/socket_realtime_service.dart';
import '../../core/services/webrtc_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/models/webrtc_session_model.dart';
import '../../data/repositories/armada_api_service.dart';
import '../../providers/auth_provider.dart';
import 'widgets/ptt_walkie_talkie_button.dart';

class CallSessionScreen extends StatefulWidget {
  final CallSessionModel session;
  final bool isCaller;
  final bool skipMediaInitForTest;
  final WebRtcService? webRtcService;
  final SocketRealtimeService? socketService;
  final ArmadaApiService? apiService;

  const CallSessionScreen({
    super.key,
    required this.session,
    required this.isCaller,
    this.skipMediaInitForTest = false,
    this.webRtcService,
    this.socketService,
    this.apiService,
  });

  @override
  State<CallSessionScreen> createState() => _CallSessionScreenState();
}

class _CallSessionScreenState extends State<CallSessionScreen> {
  late final WebRtcService _webRtcService;
  SocketRealtimeService? _socketService;
  ArmadaApiService? _apiService;
  String? _currentUserId;

  bool _initialized = false;
  bool _isTransmitting = false;
  bool _isEnding = false;
  bool _hasRemoteVideo = false;
  bool _offerSent = false;
  bool _answerReceived = false;
  int _offerRetries = 0;
  Timer? _offerRetryTimer;
  String? _lastOfferSdp;
  final Completer<void> _mediaReady = Completer<void>();
  String _statusText = 'Menghubungkan...';

  StreamSubscription? _respondSub;
  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _iceSub;
  StreamSubscription? _endedSub;

  @override
  void initState() {
    super.initState();
    _webRtcService = widget.webRtcService ?? WebRtcService();
    _statusText = widget.session.status == 'ACTIVE'
        ? 'Terhubung'
        : (widget.isCaller ? 'Memanggil...' : 'Menghubungkan...');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _resolveDependencies();
      if (!widget.skipMediaInitForTest) {
        _setupCallSession();
      }
    }
  }

  void _resolveDependencies() {
    if (widget.socketService != null) {
      _socketService = widget.socketService;
    } else {
      try {
        _socketService = context.read<SocketRealtimeService>();
      } catch (_) {}
    }

    if (widget.apiService != null) {
      _apiService = widget.apiService;
    } else {
      try {
        _apiService = context.read<ArmadaApiService>();
      } catch (_) {
        _apiService = ArmadaApiService(
          client: DioClient(storageService: SecureStorageService()),
        );
      }
    }

    try {
      _currentUserId = context.read<AuthProvider>().user?.id;
    } catch (_) {}
  }

  Future<void> _setupCallSession() async {
    // Register the signaling listeners *before* touching media. Opening the
    // camera/microphone takes several seconds; the caller starts firing offers
    // the moment the session turns ACTIVE, and anything that arrives before
    // these listeners exist is lost forever.
    _bindSignalingStreams();
    _socketService?.joinRoom('session:${widget.session.sessionId}');

    // If caller and session already active, initiate offer immediately once
    // media is ready (handled at the end of _prepareMedia).
    await _prepareMedia();
  }

  Future<void> _prepareMedia() async {
    final isVideo = widget.session.type == 'VIDEO';
    final granted = await WebRtcService.requestCallPermissions(isVideo: isVideo);
    if (!granted) {
      if (mounted) {
        setState(() => _statusText = 'Izin mikrofon/kamera ditolak');
      }
      if (!_mediaReady.isCompleted) _mediaReady.complete();
      return;
    }

    try {
      await _webRtcService.initCall(
        isVideo: isVideo,
        turnCredentials: widget.session.turnCredentials,
      );

      // Default PTT mic muted until user holds talk button
      if (!isVideo) {
        _webRtcService.setMicrophoneEnabled(false);
      }

      _webRtcService.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null) {
          _socketService?.sendWebrtcIceCandidate(
            widget.session.sessionId,
            {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
          );
        }
      };

      _webRtcService.onAddRemoteStream = (_) {
        if (mounted) {
          setState(() {
            _hasRemoteVideo = true;
          });
        }
      };

      _webRtcService.onConnectionState = (RTCPeerConnectionState state) {
        if (!mounted) return;
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _offerRetryTimer?.cancel();
          setState(() => _statusText = 'Terhubung');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          setState(() => _statusText = 'Koneksi WebRTC gagal');
        }
      };

      if (!_mediaReady.isCompleted) _mediaReady.complete();

      if (widget.isCaller && widget.session.status == 'ACTIVE' && !_offerSent) {
        await _sendOffer();
      }
    } catch (e) {
      if (!_mediaReady.isCompleted) _mediaReady.complete();
      if (mounted) {
        setState(() => _statusText = 'Gagal menyiapkan panggilan: $e');
      }
    }
  }

  void _bindSignalingStreams() {
    final socket = _socketService;
    if (socket == null) return;

    _respondSub = socket.callRespondStream.listen((data) async {
      if (data['sessionId'] != widget.session.sessionId) return;
      final status = data['status']?.toString();
      if (status == 'ACTIVE') {
        if (mounted) setState(() => _statusText = 'Menyambungkan WebRTC...');
        if (widget.isCaller && !_offerSent) {
          await _sendOffer();
        }
      } else if (status == 'DECLINED') {
        if (mounted) {
          setState(() => _statusText = 'Panggilan ditolak');
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      }
    });

    _offerSub = socket.webrtcOfferStream.listen((data) async {
      if (data['sessionId'] != widget.session.sessionId) return;
      if (_currentUserId != null && data['_actorUserId'] == _currentUserId) return;
      if (widget.isCaller) return;

      final sdp = data['sdp']?.toString();
      if (sdp == null || sdp.isEmpty) return;

      if (mounted) setState(() => _statusText = 'Menyambungkan WebRTC...');
      await _mediaReady.future.timeout(const Duration(seconds: 20), onTimeout: () {});
      if (_isEnding) return;

      try {
        final answerSdp = await _webRtcService.createAnswer(sdp, waitForCandidates: true);
        if (answerSdp.isEmpty) return;
        _socketService?.sendWebrtcAnswer(widget.session.sessionId, answerSdp);
        if (mounted) setState(() => _statusText = 'Menyambungkan WebRTC...');
      } catch (e) {
        debugPrint('createAnswer failed: $e');
      }
    });

    _answerSub = socket.webrtcAnswerStream.listen((data) async {
      if (data['sessionId'] != widget.session.sessionId) return;
      if (_currentUserId != null && data['_actorUserId'] == _currentUserId) return;
      if (!widget.isCaller) return;

      final sdp = data['sdp']?.toString();
      if (sdp == null || sdp.isEmpty) return;

      _answerReceived = true;
      _offerRetryTimer?.cancel();
      try {
        await _webRtcService.setRemoteAnswer(sdp);
      } catch (e) {
        debugPrint('setRemoteAnswer failed: $e');
      }
    });

    _iceSub = socket.webrtcIceCandidateStream.listen((data) async {
      if (data['sessionId'] != widget.session.sessionId) return;
      if (_currentUserId != null && data['_actorUserId'] == _currentUserId) return;

      final candidate = data['candidate'];
      if (candidate is Map) {
        await _webRtcService.addIceCandidate(Map<String, dynamic>.from(candidate));
      }
    });

    _endedSub = socket.webrtcCallEndedStream.listen((endedSessionId) {
      if (endedSessionId == widget.session.sessionId && mounted && !_isEnding) {
        _cleanupAndPop();
      }
    });
  }

  Future<void> _sendOffer() async {
    if (!widget.isCaller || _answerReceived || _isEnding) return;
    try {
      await _mediaReady.future.timeout(const Duration(seconds: 20), onTimeout: () {});
      if (_answerReceived || _isEnding) return;
      final offerSdp = await _webRtcService.createOffer(waitForCandidates: true);
      if (offerSdp.isEmpty || _answerReceived || _isEnding) return;
      _offerSent = true;
      _lastOfferSdp = offerSdp;
      _socketService?.sendWebrtcOffer(widget.session.sessionId, offerSdp);
      _scheduleOfferRetries();
    } catch (e) {
      debugPrint('createOffer failed: $e');
    }
  }

  /// The callee joins the session room a few seconds after the caller (it has
  /// to open the call screen, get permissions and start the camera first), so
  /// the first offer usually lands before anyone is listening. Re-send the same
  /// SDP until an answer arrives instead of hanging on "Menyambungkan...".
  void _scheduleOfferRetries() {
    _offerRetryTimer?.cancel();
    _offerRetryTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_answerReceived || _isEnding || !mounted || _offerRetries >= 8) {
        timer.cancel();
        return;
      }
      _offerRetries++;
      final cached = _lastOfferSdp;
      if (cached == null || cached.isEmpty) return;
      _socketService?.sendWebrtcOffer(widget.session.sessionId, cached);
    });
  }

  Future<void> _hangup() async {
    if (_isEnding) return;
    _isEnding = true;

    try {
      await _apiService?.endCallSession(widget.session.sessionId);
    } catch (_) {}
    _socketService?.hangupCall(widget.session.sessionId);
    await _cleanupAndPop();
  }

  Future<void> _cleanupAndPop() async {
    _isEnding = true;
    _socketService?.leaveRoom('session:${widget.session.sessionId}');
    await _webRtcService.dispose();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _offerRetryTimer?.cancel();
    _respondSub?.cancel();
    _offerSub?.cancel();
    _answerSub?.cancel();
    _iceSub?.cancel();
    _endedSub?.cancel();
    if (!_isEnding && !widget.skipMediaInitForTest) {
      _webRtcService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.session.type == 'VIDEO';
    final peerName = widget.session.driverName ?? 'Rekan Armada';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            if (isVideo && !widget.skipMediaInitForTest)
              Positioned.fill(
                child: _hasRemoteVideo
                    ? RTCVideoView(
                        _webRtcService.remoteRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              _statusText,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

            if (isVideo && !widget.skipMediaInitForTest)
              Positioned(
                top: 84,
                right: 20,
                width: 110,
                height: 155,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30),
                      color: Colors.black,
                    ),
                    child: RTCVideoView(
                      _webRtcService.localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVideo ? Icons.videocam_rounded : Icons.settings_voice_rounded,
                              color: AppTheme.statusSuccess,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isVideo ? 'Video Call' : 'PTT Walkie-Talkie',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _statusText,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (!isVideo) ...[
                  const Spacer(),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      border: Border.all(
                        color: _isTransmitting ? AppTheme.statusDanger : AppTheme.primaryBlue,
                        width: 2.5,
                      ),
                    ),
                    child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    peerName,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusText,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PttWalkieTalkieButton(
                          isTransmitting: _isTransmitting,
                          onPressStart: () {
                            setState(() => _isTransmitting = true);
                            if (!widget.skipMediaInitForTest) {
                              _webRtcService.setMicrophoneEnabled(true);
                            }
                          },
                          onPressEnd: () {
                            setState(() => _isTransmitting = false);
                            if (!widget.skipMediaInitForTest) {
                              _webRtcService.setMicrophoneEnabled(false);
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _hangup,
                            icon: const Icon(Icons.call_end_rounded),
                            label: const Text('Akhiri Sesi PTT'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.statusDanger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          heroTag: 'btn_mic_video',
                          backgroundColor: Colors.white24,
                          onPressed: () {
                            setState(() => _isTransmitting = !_isTransmitting);
                            if (!widget.skipMediaInitForTest) {
                              _webRtcService.setMicrophoneEnabled(!_isTransmitting);
                            }
                          },
                          child: Icon(
                            _isTransmitting ? Icons.mic_off_rounded : Icons.mic_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 24),
                        FloatingActionButton.large(
                          heroTag: 'btn_hangup_video',
                          backgroundColor: AppTheme.statusDanger,
                          onPressed: _hangup,
                          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
