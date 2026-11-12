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

  void Function(RTCIceCandidate candidate)? onIceCandidate;
  void Function(MediaStream stream)? onAddRemoteStream;
  void Function(RTCPeerConnectionState state)? onConnectionState;

  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;
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
        _remoteRenderer.srcObject = _remoteStream;
        onAddRemoteStream?.call(_remoteStream!);
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      onConnectionState?.call(state);
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

  /// Create WebRTC SDP Offer
  Future<String> createOffer() async {
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
    return description.sdp ?? '';
  }

  /// Create WebRTC SDP Answer in response to remote offer
  Future<String> createAnswer(String remoteSdp) async {
    if (_peerConnection == null) {
      throw StateError('PeerConnection not initialized. Call initCall first.');
    }

    final remoteDesc = RTCSessionDescription(remoteSdp, 'offer');
    await _peerConnection!.setRemoteDescription(remoteDesc);

    final answerConstraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    final description = await _peerConnection!.createAnswer(answerConstraints);
    await _peerConnection!.setLocalDescription(description);
    return description.sdp ?? '';
  }

  /// Apply remote answer SDP to local peer connection
  Future<void> setRemoteAnswer(String remoteSdp) async {
    if (_peerConnection == null) {
      throw StateError('PeerConnection not initialized.');
    }
    final answerDesc = RTCSessionDescription(remoteSdp, 'answer');
    await _peerConnection!.setRemoteDescription(answerDesc);
  }

  /// Add received ICE candidate to peer connection
  Future<void> addIceCandidate(Map<String, dynamic> candidateMap) async {
    if (_peerConnection == null) return;

    final candidate = RTCIceCandidate(
      candidateMap['candidate']?.toString() ?? '',
      candidateMap['sdpMid']?.toString() ?? '',
      candidateMap['sdpMLineIndex'] is num
          ? (candidateMap['sdpMLineIndex'] as num).toInt()
          : 0,
    );

    try {
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      debugPrint('Error adding ICE candidate: $e');
    }
  }

  /// Clean up media tracks, renderers, and peer connection
  Future<void> dispose() async {
    try {
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
      }

      if (_remoteStream != null) {
        await _remoteStream!.dispose();
        _remoteStream = null;
      }

      if (_renderersInitialized) {
        _localRenderer.srcObject = null;
        _remoteRenderer.srcObject = null;
        await _localRenderer.dispose();
        await _remoteRenderer.dispose();
        _renderersInitialized = false;
      }

      if (_peerConnection != null) {
        await _peerConnection!.close();
        await _peerConnection!.dispose();
        _peerConnection = null;
      }
    } catch (e) {
      debugPrint('Error during WebRtcService dispose: $e');
    }
  }
}
