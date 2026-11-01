import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/providers/driver_tracking_provider.dart';
import 'package:armada_mobile/core/services/location_service.dart';
import 'package:armada_mobile/core/services/local_outbox_service.dart';

void main() {
  test('ArmadaApiService exposes syncOutbox endpoint', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);

    expect(api.syncOutbox, isNotNull);
  });

  test('DriverTrackingProvider exposes flushOfflineOutbox method', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);
    final location = LocationService();
    final outbox = LocalOutboxService();
    final provider = DriverTrackingProvider(
      apiService: api,
      locationService: location,
      outboxService: outbox,
    );

    expect(provider.flushOfflineOutbox, isNotNull);
  });
}
