import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/owner/widgets/assign_driver_modal_sheet.dart';
import 'package:armada_mobile/data/models/fleet_driver_model.dart';
import 'package:armada_mobile/data/models/create_delivery_dto.dart';

void main() {
  testWidgets('AssignDriverModalSheet lists drivers and displays overload alert when capacity exceeded', (tester) async {
    final drivers = [
      FleetDriver(
        id: 'drv-01',
        employeeCode: 'EMP-001',
        driverName: 'Pak Budi',
        phone: '+62811111111',
        operationalStatus: 'AVAILABLE',
        assignedVehicle: 'Truk Box Engkel (B 1234 CD)',
        vehicleCapacityKg: 1000.0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssignDriverModalSheet(
            deliveryId: 'del-001',
            deliveryCode: 'DO-2026-0901',
            totalCargoWeightKg: 1200.0, // Overload (> 1000kg)
            availableDrivers: drivers,
            onAssign: (AssignDeliveryDto dto) async {},
          ),
        ),
      ),
    );

    expect(find.text('Penugasan Driver & Armada'), findsOneWidget);
    expect(find.text('Pak Budi'), findsOneWidget);
    expect(find.text('PERINGATAN: MUATAN MELEBIHI KAPASITAS!'), findsOneWidget);
  });
}
