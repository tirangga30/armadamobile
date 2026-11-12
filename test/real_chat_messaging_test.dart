import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';
import 'package:armada_mobile/data/models/chat_model.dart';

void main() {
  test('ArmadaApiService exposes getMyDevices and SocketRealtimeService exposes chatMessageAckStream', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);
    final socket = SocketRealtimeService(storageService: storage);

    expect(api.getMyDevices, isNotNull);
    expect(socket.chatMessageAckStream, isNotNull);
    expect(socket.sendChatMessageWs, isNotNull);
  });

  test('ChatMessageModel correctly serializes and deserializes device routing IDs', () {
    final json = {
      'id': 'msg-uuid-1',
      'conversationId': 'conv-uuid-1',
      'senderUserId': 'user-uuid-1',
      'senderDeviceId': 'dev-sender-uuid',
      'recipientDeviceId': 'dev-recipient-uuid',
      'protocolVersion': 1,
      'ciphertextBlob': 'SGVsbG8=',
      'headerJson': {'iv': 'iv-base64'},
      'createdAt': '2026-11-12T10:00:00.000Z',
      'deliveredAt': '2026-11-12T10:00:01.000Z',
      'readAt': null,
    };

    final model = ChatMessageModel.fromJson(json);
    expect(model.id, 'msg-uuid-1');
    expect(model.senderUserId, 'user-uuid-1');
    expect(model.senderDeviceId, 'dev-sender-uuid');
    expect(model.recipientDeviceId, 'dev-recipient-uuid');
    expect(model.isDelivered, isTrue);
    expect(model.isRead, isFalse);

    final out = model.toJson();
    expect(out['senderDeviceId'], 'dev-sender-uuid');
    expect(out['recipientDeviceId'], 'dev-recipient-uuid');
  });
}
