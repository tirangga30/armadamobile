import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/services/e2ee_crypto_service.dart';
import 'package:armada_mobile/core/services/local_outbox_service.dart';
import 'package:armada_mobile/data/models/webrtc_session_model.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';

void main() {
  test('Phase 5 integrated smoke test: crypto, outbox, and session models', () {
    // 1. E2EE Crypto test
    final enc = E2eeCryptoService.encrypt('Test Plaintext', 'key-32-chars-test-secret-value!!');
    final dec = E2eeCryptoService.decrypt(
      enc.ciphertextBlob,
      'key-32-chars-test-secret-value!!',
      enc.headerJson['iv'] as String,
    );
    expect(dec, 'Test Plaintext');

    // 2. Outbox Queue test
    final outbox = LocalOutboxService();
    outbox.clear();
    expect(outbox.pendingCount, 0);

    // 3. WebRTC Session Model test
    final session = CallSessionModel(
      sessionId: 'ses-1',
      type: 'VOICE_PTT',
      ownerId: 'owner-1',
      driverId: 'drv-1',
      status: 'ACTIVE',
    );
    expect(session.type, 'VOICE_PTT');

    // 4. API & Realtime Services wiring sanity test
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);
    final socket = SocketRealtimeService(storageService: storage);

    expect(api.getConversations, isNotNull);
    expect(api.initiateVoiceSession, isNotNull);
    expect(api.syncOutbox, isNotNull);
    expect(socket.webrtcOfferStream, isNotNull);
  });
}
