import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/driver/widgets/pod_capture_sheet.dart';
import 'package:armada_mobile/features/driver/widgets/stop_failure_dialog.dart';

void main() {
  testWidgets('PodCaptureSheet renders receiver name input, camera button, and signature canvas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PodCaptureSheet(
            stopId: 'stop-001',
            destinationName: 'Toko Sumber Rejeki',
            onSubmit: ({
              required String receiverName,
              required dynamic photoBytes,
              required dynamic signatureBytes,
              String? notes,
            }) async {},
          ),
        ),
      ),
    );

    expect(find.text('Bukti Serah Terima (POD)'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Ambil Foto Fisik'), findsOneWidget);
    expect(find.text('Tanda Tangan Penerima'), findsOneWidget);
  });

  testWidgets('StopFailureDialog renders reason dropdown and submit button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StopFailureDialog(
            stopId: 'stop-001',
            destinationName: 'Toko Sumber Rejeki',
            onSubmit: ({required String reason, String? notes}) async {},
          ),
        ),
      ),
    );

    expect(find.text('Laporkan Kendala Pengantaran'), findsOneWidget);
    expect(find.text('Alasan Pengiriman Gagal'), findsOneWidget);
    expect(find.text('Kirim Laporan Kendala'), findsOneWidget);
  });
}
