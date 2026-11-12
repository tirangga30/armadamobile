import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/features/communication/call_session_screen.dart';
import 'package:armada_mobile/data/models/webrtc_session_model.dart';

void main() {
  test('SocketRealtimeService exposes callInviteStream and builds anti-replay signaling payloads', () {
    final service = SocketRealtimeService(storageService: SecureStorageService());
    expect(service.callInviteStream, isNotNull);
    expect(service.callRespondStream, isNotNull);

    final offerPayload = service.buildSignalingOfferPayload('ses-uuid-1', 'v=0...');
    expect(offerPayload['sessionId'], 'ses-uuid-1');
    expect(offerPayload['sdp'], 'v=0...');
    expect(offerPayload['nonce'], isNotEmpty);
    expect(offerPayload['seq'], isA<int>());
    expect(offerPayload['timestamp'], isA<int>());
  });

  testWidgets('CallSessionScreen renders PTT Walkie-Talkie controls and hangup button', (tester) async {
    final session = CallSessionModel(
      sessionId: 'ses-01',
      type: 'VOICE_PTT',
      ownerId: 'owner-1',
      driverId: 'drv-1',
      driverName: 'Driver Utama',
      status: 'ACTIVE',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CallSessionScreen(
          session: session,
          isCaller: true,
          skipMediaInitForTest: true,
        ),
      ),
    );

    expect(find.text('TEKAN UNTUK BICARA'), findsOneWidget);
    expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);
  });
}
