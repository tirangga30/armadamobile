import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/owner/widgets/create_delivery_modal_sheet.dart';
import 'package:armada_mobile/data/models/create_delivery_dto.dart';

void main() {
  testWidgets('CreateDeliveryModalSheet renders DO Number, Add Item, and Add Stop buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreateDeliveryModalSheet(
            onSubmit: (CreateDeliveryDto dto) async {},
          ),
        ),
      ),
    );

    expect(find.text('Buat Perintah Kirim (DO) Baru'), findsOneWidget);
    expect(find.text('Tambah Barang'), findsOneWidget);
    expect(find.text('Tambah Titik Tujuan (Stop)'), findsOneWidget);
    expect(find.text('Simpan & Terbitkan DO'), findsOneWidget);
  });
}
