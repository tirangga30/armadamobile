import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/webrtc_session_model.dart';

/// WebRTC Service managing peer connections, media streams, and ICE candidates
class WebRtcService {
  static const String defaultStunServer = 'stun:stun.l.google.com:19302';

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;
  bool _isDisposing = false;
  bool _isDisposed = false;

  /// ICE candidates that arrived before the remote description was applied.
  /// Candidates are trickled by the peer as soon as it gathers them, which is
  /// usually before our SDP answer/remote-offer is set; addCandidate() throws
  /// in that window and the candidate would be lost for good.
  final List<RTCIceCandidate> _pendingRemoteCandidates = <RTCIceCandidate>[];
  bool _remoteDescriptionSet = false;
  RTCIceGatheringState? _gatheringState;
  Completer<void>? _gatheringCompleter;

  void Function(RTCIceCandidate candidate)? onIceCandidate;
  void Function(MediaStream stream)? onAddRemoteStream;
  void Function(RTCPeerConnectionState state)? onConnectionState;

  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;
  bool get renderersInitialized => _renderersInitialized;
  bool get isDisposed => _isDisposed;
  RTCPeerConnection? get peerConnection => _peerConnection;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  /// Builds STUN fallback and RFC 7635 TURN iceServers configuration map
  static Map<String, dynamic> buildIceServersConfig(TurnCredentialsModel? turnCredentials) {
    final List<Map<String, dynamic>> iceServers = [
      {
        'urls': [defaultStunServer],
      },
    ];

    if (turnCredentials != null && turnCredentials.urls.isNotEmpty) {
      final turnEntry = <String, dynamic>{
        'urls': turnCredentials.urls,
        'username': turnCredentials.username,
        'credential': turnCredentials.credential,
      };
      iceServers.add(turnEntry);
    }

    return {
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    };
  }

  /// Request runtime permissions for audio and optionally camera
  static Future<bool> requestCallPermissions({bool isVideo = false}) async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      return false;
    }

    if (isVideo) {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        return false;
      }
    }

    return true;
  }

  /// Initialize local audio/video renderers
  Future<void> initRenderers() async {
    if (!_renderersInitialized) {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      _renderersInitialized = true;
    }
  }

  /// Initialize call with local media capture and peer connection configuration
  Future<void> initCall({
    required bool isVideo,
    TurnCredentialsModel? turnCredentials,
  }) async {
    await initRenderers();

    final config = buildIceServersConfig(turnCredentials);
    final constraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    _peerConnection = await createPeerConnection(config, constraints);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        onIceCandidate?.call(candidate);
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        if (isVideo || event.track.kind == 'video') {
          _remoteRenderer.srcObject = _remoteStream;
        }
        onAddRemoteStream?.call(_remoteStream!);
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      onConnectionState?.call(state);
    };

    _peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
      _gatheringState = state;
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
          _gatheringCompleter != null &&
          !_gatheringCompleter!.isCompleted) {
        _gatheringCompleter!.complete();
      }
    };

    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': isVideo
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = _localStream;

    for (var track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }
  }

  /// Enable or mute microphone track (used for PTT Walkie-Talkie hold-to-talk)
  void setMicrophoneEnabled(bool enabled) {
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = enabled;
      }
    }
  }

  /// Wait until ICE gathering finishes so the SDP already carries every
  /// candidate. Trickling alone is unreliable here because the peer's room
  /// listeners may still be registering when the first candidates fly out.
  Future<String> waitForIceGathering({Duration timeout = const Duration(seconds: 4)}) async {
    final pc = _peerConnection;
    if (pc == null) return '';
    if (_gatheringState != RTCIceGatheringState.RTCIceGatheringStateComplete) {
      _gatheringCompleter ??= Completer<void>();
      if (!_gatheringCompleter!.isCompleted) {
        await _gatheringCompleter!.future.timeout(timeout, onTimeout: () {});
      }
    }
    final local = await pc.getLocalDescription();
    return local?.sdp ?? '';
  }

  /// Create WebRTC SDP Offer
  Future<String> createOffer({bool waitForCandidates = false}) async {
    if (_peerConnection == null) {
      throw StateError('PeerConnection not initialized. Call initCall first.');
    }

    final offerConstraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    final description = await _peerConnection!.createOffer(offerConstraints);
    await _peerConnection!.setLocalDescription(description);

    if (waitForCandidates) {
      final gathered = await waitForIceGathering();
      if (gathered.isNotEmpty) return gathered;
    }
    return description.sdp ?? '';
  }

  /// Create WebRTC SDP Answer in response to remote offer
  Future<String> createAnswer(String remoteSdp, {bool waitForCandidates = false}) async {
    if (_peerConnection == null) {
      throw StateError('PeerConnection not initialized. Call initCall first.');
    }

    final remoteDesc = RTCSessionDescription(remoteSdp, 'offer');
    await _peerConnection!.setRemoteDescription(remoteDesc);
    _remoteDescriptionSet = true;
    await _flushPendingRemoteCandidates();

    final answerConstraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    final description = await _peerConnection!.createAnswer(answerConstraints);
    await _peerConnection!.setLocalDescription(description);

    if (waitForCandidates) {
      final gathered = await waitForIceGathering();
      if (gathered.isNotEmpty) return gathered;
    }
    return description.sdp ?? '';
  }

  /// Apply remote answer SDP to local peer connection
  Future<void> setRemoteAnswer(String remoteSdp) async {
    if (_peerConnection == null) {
      throw StateError('PeerConnection not initialized.');
    }
    final answerDesc = RTCSessionDescription(remoteSdp, 'answer');
    await _peerConnection!.setRemoteDescription(answerDesc);
    _remoteDescriptionSet = true;
    await _flushPendingRemoteCandidates();
  }

  /// Add received ICE candidate to peer connection
  Future<void> addIceCandidate(Map<String, dynamic> candidateMap) async {
    if (_peerConnection == null || _isDisposed || _isDisposing) return;

    final candidate = RTCIceCandidate(
      candidateMap['candidate']?.toString() ?? '',
      candidateMap['sdpMid']?.toString() ?? '',
      candidateMap['sdpMLineIndex'] is num
          ? (candidateMap['sdpMLineIndex'] as num).toInt()
          : 0,
    );

    if (candidate.candidate == null || candidate.candidate!.isEmpty) return;

    // The remote description must exist before a candidate can be attached.
    if (!_remoteDescriptionSet) {
      _pendingRemoteCandidates.add(candidate);
      return;
    }

    try {
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      debugPrint('Error adding ICE candidate: $e');
    }
  }

  Future<void> _flushPendingRemoteCandidates() async {
    if (_pendingRemoteCandidates.isEmpty || _isDisposed || _isDisposing) return;
    final queued = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();
    for (final candidate in queued) {
      if (_isDisposed || _isDisposing) break;
      try {
        await _peerConnection?.addCandidate(candidate);
      } catch (e) {
        debugPrint('Error flushing pending ICE candidate: $e');
      }
    }
  }

  /// Clean up media tracks, renderers, and peer connection in safe native order
  Future<void> dispose() async {
    if (_isDisposed || _isDisposing) return;
    _isDisposing = true;

    try {
      // 1. Detach external event callbacks to prevent firing during teardown
      onIceCandidate = null;
      onAddRemoteStream = null;
      onConnectionState = null;

      // 2. Detach callbacks and close/dispose PeerConnection FIRST.
      // On Android native WebRTC, closing peer connection first detaches all
      // native audio/video sinks. Disposing renderers before peer connection
      // causes SIGSEGV when incoming frames attempt to hit destroyed texture sinks.
      if (_peerConnection != null) {
        _peerConnection!.onIceCandidate = null;
        _peerConnection!.onTrack = null;
        _peerConnection!.onConnectionState = null;
        _peerConnection!.onIceGatheringState = null;
        try {
          await _peerConnection!.close();
          await _peerConnection!.dispose();
        } catch (e) {
          debugPrint('Error closing peer connection: $e');
        }
        _peerConnection = null;
      }

      // 3. Stop tracks and dispose media streams
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          try {
            track.stop();
          } catch (_) {}
        }
        try {
          await _localStream!.dispose();
        } catch (_) {}
        _localStream = null;
      }

      if (_remoteStream != null) {
        for (var track in _remoteStream!.getTracks()) {
          try {
            track.stop();
          } catch (_) {}
        }
        try {
          await _remoteStream!.dispose();
        } catch (_) {}
        _remoteStream = null;
      }

      // 4. Detach srcObject and dispose renderers LAST
      if (_renderersInitialized) {
        try {
          _localRenderer.srcObject = null;
          _remoteRenderer.srcObject = null;
          await _localRenderer.dispose();
          await _remoteRenderer.dispose();
        } catch (e) {
          debugPrint('Error disposing renderers: $e');
        }
        _renderersInitialized = false;
      }

      // 5. Clear pending state and uncompleted completers
      _pendingRemoteCandidates.clear();
      _remoteDescriptionSet = false;
      _gatheringState = null;
      if (_gatheringCompleter != null && !_gatheringCompleter!.isCompleted) {
        _gatheringCompleter!.complete();
      }
      _gatheringCompleter = null;
    } catch (e) {
      debugPrint('Error during WebRtcService dispose: $e');
    } finally {
      _isDisposed = true;
      _isDisposing = false;
    }
  }
}
