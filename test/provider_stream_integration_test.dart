import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/providers/fleet_provider.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';

void main() {
  test('FleetProvider can ingest SocketRealtimeService', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);
    final socketService = SocketRealtimeService(storageService: storage);
    final provider = FleetProvider(apiService: api, socketService: socketService);

    expect(provider, isNotNull);
  });
}
