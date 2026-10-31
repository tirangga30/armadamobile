import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/create_delivery_dto.dart';

void main() {
  test('CreateDeliveryDto serializes nested items and stops to backend schema', () {
    final dto = CreateDeliveryDto(
      deliveryCode: 'DO-2026-1001',
      items: [
        CreateDeliveryItemDto(
          itemCode: 'ITM-01',
          itemName: 'Minyak Goreng 2L',
          quantity: 20,
          unit: 'DUS',
          weightKg: 240.0,
        ),
      ],
      stops: [
        CreateDeliveryStopDto(
          sequence: 1,
          destinationName: 'Toko Makmur',
          address: 'Jl. Merdeka No. 10',
          latitude: -6.18,
          longitude: 106.82,
        ),
      ],
    );

    final json = dto.toJson();
    expect(json['deliveryCode'], 'DO-2026-1001');
    expect((json['items'] as List).length, 1);
    expect((json['stops'] as List).length, 1);
    expect(json['items'][0]['itemName'], 'Minyak Goreng 2L');
    expect(json['stops'][0]['destinationName'], 'Toko Makmur');
  });

  test('AssignDeliveryDto serializes driver and vehicle with optional notes', () {
    final dto = AssignDeliveryDto(
      driverId: 'drv-uuid-001',
      vehicleId: 'veh-uuid-001',
      notes: 'Segera kirim pagi',
    );

    final json = dto.toJson();
    expect(json['driverId'], 'drv-uuid-001');
    expect(json['vehicleId'], 'veh-uuid-001');
    expect(json['notes'], 'Segera kirim pagi');
  });
}
