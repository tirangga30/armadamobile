import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/owner/widgets/route_optimizer_sheet.dart';
import 'package:armada_mobile/data/models/route_geometry_model.dart';

void main() {
  testWidgets('RouteOptimizerSheet shows recommendation comparison and apply button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteOptimizerSheet(
            deliveryId: 'del-001',
            currentDistanceM: 15000,
            currentDurationS: 2100,
            recommendedDistanceM: 12500,
            recommendedDurationS: 1750,
            reorderedStopNames: const ['Warehouse Cakung', 'Toko Sumber Rejeki', 'Supermarket Puri'],
            onApply: (SelectRouteDto dto) async {},
          ),
        ),
      ),
    );

    expect(find.text('Optimasi Rute (2-Opt TSP)'), findsOneWidget);
    expect(find.text('Terapkan Rute Rekomendasi'), findsOneWidget);
    expect(find.text('Supermarket Puri'), findsOneWidget);
  });
}
