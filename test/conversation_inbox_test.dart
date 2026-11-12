import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/chat/conversation_inbox_view.dart';
import 'package:armada_mobile/data/models/chat_model.dart';

void main() {
  testWidgets('ConversationInboxView renders active conversations and driver names', (tester) async {
    final conversations = [
      ConversationModel(
        id: 'conv-uuid-1',
        driverId: 'drv-uuid-1',
        driverName: 'Driver Utama',
        plateNumber: 'B 9281 SXZ',
        lastMessagePreview: 'Siap berangkat ke tujuan',
        unreadCount: 2,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationInboxView(
          initialConversations: conversations,
        ),
      ),
    );

    expect(find.text('Pesan & Obrolan E2EE'), findsOneWidget);
    expect(find.text('Driver Utama'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
