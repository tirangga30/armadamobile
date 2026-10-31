import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/owner/views/owner_delivery_detail_view.dart';
import 'package:armada_mobile/data/models/delivery_model.dart';

void main() {
  testWidgets('OwnerDeliveryDetailView renders delivery status, items, and stops timeline', (tester) async {
    final delivery = DeliveryModel(
      id: 'del-001',
      orderNumber: 'DO-2026-0901',
      clientName: 'PT Logistik Makmur',
      origin: 'Gudang Pusat Cakung',
      destination: 'Outlet Sudirman',
      status: 'ASSIGNED',
      assignedDriver: 'Driver Utama',
      plateNumber: 'B 9281 SXZ',
      totalItems: 12,
      totalWeightKg: 450,
      createdAt: '2026-09-30 08:30:00',
      stops: [
        DeliveryStop(
          id: 'st-01',
          sequence: 1,
          destinationName: 'Toko Sumber Rejeki',
          address: 'Jl. Merdeka No. 10',
          status: 'PENDING',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OwnerDeliveryDetailView(delivery: delivery),
      ),
    );

    expect(find.text('DO-2026-0901'), findsOneWidget);
    expect(find.text('Rincian Titik Pengantaran'), findsOneWidget);
    expect(find.text('Toko Sumber Rejeki'), findsOneWidget);
  });
}
