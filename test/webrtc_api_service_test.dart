import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/webrtc_session_model.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('CallSessionModel parses session data and TURN credentials', () {
    final json = {
      'sessionId': 'session-001',
      'type': 'VOICE_PTT',
      'ownerId': 'owner-01',
      'driverId': 'drv-01',
      'status': 'PENDING',
      'turnCredentials': {
        'urls': ['turn:turn.armada.net:3478?transport=udp'],
        'username': '1788352800:owner-01',
        'credential': 'hmac_sha1_secret',
        'ttlSeconds': 3600,
      },
    };

    final model = CallSessionModel.fromJson(json);
    expect(model.sessionId, 'session-001');
    expect(model.type, 'VOICE_PTT');
    expect(model.turnCredentials?.urls.first, contains('turn:turn.armada.net'));
  });

  test('ArmadaApiService exposes WebRTC session management methods', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);

    expect(api.initiateVoiceSession, isNotNull);
    expect(api.initiateVideoSession, isNotNull);
    expect(api.respondToCallSession, isNotNull);
    expect(api.endCallSession, isNotNull);
  });
}
