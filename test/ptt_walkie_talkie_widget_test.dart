import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/communication/widgets/ptt_walkie_talkie_button.dart';
import 'package:armada_mobile/features/communication/widgets/incoming_call_dialog.dart';

void main() {
  testWidgets('PttWalkieTalkieButton renders hold-to-talk button and label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PttWalkieTalkieButton(
            onPressStart: () {},
            onPressEnd: () {},
          ),
        ),
      ),
    );

    expect(find.text('TEKAN UNTUK BICARA'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });

  testWidgets('IncomingCallDialog displays caller name and Accept/Decline actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IncomingCallDialog(
            callerName: 'Owner Dispatcher',
            callType: 'VOICE_PTT',
            onAccept: () {},
            onDecline: () {},
          ),
        ),
      ),
    );

    expect(find.text('Panggilan Masuk: VOICE_PTT'), findsOneWidget);
    expect(find.text('Owner Dispatcher'), findsOneWidget);
    expect(find.text('Terima'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);
  });
}
