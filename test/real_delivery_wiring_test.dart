import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/providers/fleet_provider.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/data/models/create_delivery_dto.dart';
import 'package:armada_mobile/data/models/delivery_model.dart';
import 'package:armada_mobile/data/models/fleet_driver_model.dart';
import 'package:armada_mobile/data/models/emergency_model.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

class _FakeApiService extends ArmadaApiService {
  bool createCalled = false;
  bool assignCalled = false;
  _FakeApiService() : super(client: DioClient(storageService: SecureStorageService()));

  @override
  Future<DeliveryModel> createDelivery(CreateDeliveryDto dto) async {
    createCalled = true;
    return DeliveryModel(
      id: 'del-uuid-real-01',
      orderNumber: dto.deliveryCode,
      clientName: dto.customerName ?? 'Klien',
      origin: 'Gudang Utama',
      destination: dto.stops.first.destinationName,
      status: 'DRAFT',
    );
  }

  @override
  Future<void> assignDelivery(String deliveryId, AssignDeliveryDto dto) async {
    assignCalled = true;
  }

  @override
  Future<List<DeliveryModel>> getDeliveries({String? driverId}) async {
    // Return standard base delivery
    return [
      DeliveryModel(
        id: 'del-base-1',
        orderNumber: 'DO-BASE-01',
        clientName: 'Base Client',
        origin: 'Origin',
        destination: 'Dest',
        status: 'ASSIGNED',
      ),
    ];
  }

  @override
  Future<List<FleetDriver>> getFleetLocations() async => [];

  @override
  Future<List<EmergencyModel>> getEmergencies() async => [];
}

void main() {
  test('FleetProvider.createDelivery calls API and prepends created delivery', () async {
    final fakeApi = _FakeApiService();
    final provider = FleetProvider(apiService: fakeApi);

    final dto = CreateDeliveryDto(
      deliveryCode: 'DO-REAL-001',
      items: [CreateDeliveryItemDto(itemCode: 'I1', itemName: 'Box', quantity: 5)],
      stops: [CreateDeliveryStopDto(sequence: 1, destinationName: 'Toko A', address: 'Jl. 1', latitude: -6.2, longitude: 106.8)],
    );

    final created = await provider.createDelivery(dto);
    expect(fakeApi.createCalled, isTrue);
    expect(created.id, 'del-uuid-real-01');
    expect(provider.deliveries.any((d) => d.id == 'del-uuid-real-01'), isTrue);
    expect(provider.deliveries.first.id, 'del-uuid-real-01');
  });

  test('FleetProvider.assignDelivery calls API and updates local delivery state', () async {
    final fakeApi = _FakeApiService();
    final provider = FleetProvider(apiService: fakeApi);
    final dto = CreateDeliveryDto(
      deliveryCode: 'DO-REAL-002',
      items: [CreateDeliveryItemDto(itemCode: 'I1', itemName: 'Box', quantity: 5)],
      stops: [CreateDeliveryStopDto(sequence: 1, destinationName: 'Toko B', address: 'Jl. 2', latitude: -6.2, longitude: 106.8)],
    );
    final created = await provider.createDelivery(dto);

    await provider.assignDelivery(
      created.id,
      AssignDeliveryDto(driverId: 'drv-1', vehicleId: 'veh-1'),
      driverName: 'Pak Budi',
      plateNumber: 'B 9999 XX',
    );
    expect(fakeApi.assignCalled, isTrue);
    final updated = provider.deliveries.firstWhere((d) => d.id == created.id);
    expect(updated.status, 'ASSIGNED');
    expect(updated.assignedDriver, 'Pak Budi');
    expect(updated.plateNumber, 'B 9999 XX');
  });

  test('FleetProvider preserves user-created deliveries across fetchAllData refreshes', () async {
    final fakeApi = _FakeApiService();
    final provider = FleetProvider(apiService: fakeApi);

    final dto = CreateDeliveryDto(
      deliveryCode: 'DO-PRESERVE-01',
      items: [CreateDeliveryItemDto(itemCode: 'I1', itemName: 'Box', quantity: 5)],
      stops: [CreateDeliveryStopDto(sequence: 1, destinationName: 'Toko C', address: 'Jl. 3', latitude: -6.2, longitude: 106.8)],
    );
    await provider.createDelivery(dto);

    // Refresh data
    await provider.fetchAllData();

    // Verify user-created delivery is retained alongside fetched base deliveries
    expect(provider.deliveries.any((d) => d.id == 'del-uuid-real-01'), isTrue);
    expect(provider.deliveries.any((d) => d.id == 'del-base-1'), isTrue);
  });
}
