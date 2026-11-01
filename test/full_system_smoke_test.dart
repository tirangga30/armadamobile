import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';

class _AllowAllHttpOverrides extends HttpOverrides {}

void main() {
  HttpOverrides.global = _AllowAllHttpOverrides();

  test('Full system initialization and service dependency graph sanity', () async {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);
    final socket = SocketRealtimeService(storageService: storage);

    expect(storage, isNotNull);
    expect(dio, isNotNull);
    expect(api, isNotNull);
    expect(socket, isNotNull);
    expect(socket.isConnected, isFalse);
  });
}
