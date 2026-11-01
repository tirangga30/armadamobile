import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('SocketRealtimeService handles initialization and connection options', () {
    final storage = SecureStorageService();
    final service = SocketRealtimeService(storageService: storage);

    expect(service.isConnected, isFalse);
    expect(service.locationStream, isNotNull);
    expect(service.deliveryStatusStream, isNotNull);
    expect(service.emergencyStream, isNotNull);
  });
}
