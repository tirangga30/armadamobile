import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/services/webrtc_service.dart';
import 'package:armada_mobile/data/models/webrtc_session_model.dart';

void main() {
  test('WebRtcService builds STUN fallback and RFC 7635 TURN iceServers config', () {
    final turn = TurnCredentialsModel(
      urls: ['turn:turn.armada.local:3478?transport=udp'],
      username: '1788352800:owner-1',
      credential: 'hmac-secret-123',
      ttlSeconds: 3600,
    );

    final config = WebRtcService.buildIceServersConfig(turn);
    final iceServers = config['iceServers'] as List<Map<String, dynamic>>;

    expect(iceServers.length, greaterThanOrEqualTo(2));
    expect(
      iceServers.any((s) => (s['urls'] as List).first.toString().startsWith('stun:')),
      isTrue,
    );
    expect(iceServers.any((s) => s['username'] == '1788352800:owner-1'), isTrue);
  });

  test('WebRtcService builds STUN-only config when turnCredentials is null', () {
    final config = WebRtcService.buildIceServersConfig(null);
    final iceServers = config['iceServers'] as List<Map<String, dynamic>>;

    expect(iceServers.length, 1);
    expect(
      (iceServers.first['urls'] as List).first.toString(),
      'stun:stun.l.google.com:19302',
    );
  });
}
