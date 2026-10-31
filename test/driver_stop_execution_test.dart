import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/providers/driver_tracking_provider.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/services/location_service.dart';

void main() {
  test('DriverTrackingProvider exposes stop-level mutation methods', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);
    final location = LocationService();
    final provider = DriverTrackingProvider(
      apiService: api,
      locationService: location,
    );

    expect(provider.executeDepartStop, isNotNull);
    expect(provider.executeArriveStop, isNotNull);
    expect(provider.executeUnloadStop, isNotNull);
    expect(provider.executeFailStop, isNotNull);
    expect(provider.executeSubmitPod, isNotNull);
  });
}
