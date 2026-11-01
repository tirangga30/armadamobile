import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/chat/chat_conversation_view.dart';
import 'package:armada_mobile/features/chat/widgets/chat_bubble.dart';
import 'package:armada_mobile/data/models/chat_model.dart';

void main() {
  testWidgets('ChatBubble renders outgoing and incoming styles with timestamp', (tester) async {
    final msg = ChatMessageModel(
      id: 'msg-01',
      conversationId: 'conv-01',
      senderId: 'user-01',
      ciphertextBlob: 'blob',
      headerJson: {},
      plaintextBody: 'Halo, muatan siap diambil di Cakung.',
      isOutgoing: true,
      isDelivered: true,
      isRead: false,
      sentAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatBubble(message: msg),
        ),
      ),
    );

    expect(find.text('Halo, muatan siap diambil di Cakung.'), findsOneWidget);
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
  });

  testWidgets('ChatConversationView renders driver title, messages, and input bar', (tester) async {
    final conv = ConversationModel(
      id: 'conv-01',
      driverName: 'Pak Budi Santoso',
      plateNumber: 'B 1234 CD',
    );

    final messages = [
      ChatMessageModel(
        id: 'msg-01',
        conversationId: 'conv-01',
        senderId: 'user-01',
        ciphertextBlob: 'blob',
        plaintextBody: 'Tolong pastikan surat jalan ditandatangani toko',
        headerJson: {},
        isOutgoing: false,
        sentAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ChatConversationView(
          conversation: conv,
          initialMessages: messages,
        ),
      ),
    );

    expect(find.text('Pak Budi Santoso'), findsOneWidget);
    expect(find.text('Tolong pastikan surat jalan ditandatangani toko'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });
}
