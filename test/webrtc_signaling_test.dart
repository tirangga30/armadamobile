import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('SocketRealtimeService exposes WebRTC signaling streams and senders', () {
    final storage = SecureStorageService();
    final service = SocketRealtimeService(storageService: storage);

    expect(service.webrtcOfferStream, isNotNull);
    expect(service.webrtcAnswerStream, isNotNull);
    expect(service.webrtcIceCandidateStream, isNotNull);
    expect(service.webrtcCallEndedStream, isNotNull);
    expect(service.sendWebrtcOffer, isNotNull);
    expect(service.sendWebrtcAnswer, isNotNull);
    expect(service.sendWebrtcIceCandidate, isNotNull);
    expect(service.hangupCall, isNotNull);
  });
}
