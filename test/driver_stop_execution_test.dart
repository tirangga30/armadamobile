import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/providers/driver_tracking_provider.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/data/models/delivery_model.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/services/location_service.dart';

class _MockDeliveryApiService extends ArmadaApiService {
  bool shouldSucceed = true;
  String? lastId;
  String? lastStatus;

  _MockDeliveryApiService() : super(client: DioClient(storageService: SecureStorageService()));

  @override
  Future<bool> updateDeliveryStatus(String id, String status) async {
    lastId = id;
    lastStatus = status;
    return shouldSucceed;
  }

  @override
  Future<List<DeliveryModel>> getDeliveries({String? driverId}) async {
    return [
      DeliveryModel(
        id: 'del-1',
        orderNumber: 'DO-001',
        clientName: 'Test Client',
        origin: 'Origin',
        destination: 'Dest',
        status: 'ASSIGNED',
      ),
    ];
  }
}

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

  test('ArmadaApiService.updateDeliveryStatus returns false for unsupported status', () async {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);

    final result = await api.updateDeliveryStatus('del-1', 'INVALID_STATUS');
    expect(result, isFalse);
  });

  test('DriverTrackingProvider.updateDeliveryState rolls back on API failure and sets lastError', () async {
    final mockApi = _MockDeliveryApiService();
    final location = LocationService();
    final provider = DriverTrackingProvider(
      apiService: mockApi,
      locationService: location,
    );

    await provider.loadDriverDeliveries();
    expect(provider.assignedDeliveries.first.status, 'ASSIGNED');

    // Case 1: Server fails
    mockApi.shouldSucceed = false;
    await provider.updateDeliveryState('del-1', 'ACCEPTED');

    // Rolls back to ASSIGNED and sets lastError
    expect(provider.assignedDeliveries.first.status, 'ASSIGNED');
    expect(provider.lastError, 'Gagal memperbarui status tugas. Coba lagi.');

    // Case 2: Server succeeds
    mockApi.shouldSucceed = true;
    await provider.updateDeliveryState('del-1', 'ACCEPTED');

    expect(provider.assignedDeliveries.first.status, 'ACCEPTED');
  });
}
