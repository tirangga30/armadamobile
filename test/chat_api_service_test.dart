import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';

void main() {
  test('ArmadaApiService exposes conversation and message endpoints', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);
    final socket = SocketRealtimeService(storageService: storage);

    expect(api.getConversations, isNotNull);
    expect(api.createConversation, isNotNull);
    expect(api.getMessages, isNotNull);
    expect(api.sendChatMessage, isNotNull);
    expect(socket.chatMessageStream, isNotNull);
  });
}
