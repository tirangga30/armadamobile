import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/chat_model.dart';
import 'package:armada_mobile/core/services/e2ee_crypto_service.dart';

void main() {
  test('E2eeCryptoService encrypts and decrypts message with shared key', () {
    const key = 'secret_test_key_32_characters_long!';
    const plaintext = 'Instruksi: bongkar di gudang belakang toko';

    final encrypted = E2eeCryptoService.encrypt(plaintext, key);
    expect(encrypted.ciphertextBlob, isNotEmpty);
    expect(encrypted.ciphertextBlob, isNot(contains('Instruksi')));
    expect(encrypted.headerJson, contains('iv'));

    final decrypted = E2eeCryptoService.decrypt(
      encrypted.ciphertextBlob,
      key,
      encrypted.headerJson['iv'] as String,
    );
    expect(decrypted, equals(plaintext));
  });

  test('SendMessageDto serializes ciphertext and headers to backend schema', () {
    final dto = SendMessageDto(
      recipientDeviceId: '550e8400-e29b-41d4-a716-446655440000',
      ciphertextBlob: 'SGVsbG8gV29ybGQ=',
      headerJson: {'iv': 'random_iv_123'},
      idempotencyKey: 'idem-uuid-001',
    );
    final json = dto.toJson();
    expect(json['recipientDeviceId'], '550e8400-e29b-41d4-a716-446655440000');
    expect(json['ciphertextBlob'], 'SGVsbG8gV29ybGQ=');
    expect(json['idempotencyKey'], 'idem-uuid-001');
  });

  test('ConversationModel and ChatMessageModel parse json correctly', () {
    final conv = ConversationModel.fromJson({
      'id': 'conv-01',
      'participantAId': 'user-owner',
      'participantBId': 'user-driver',
      'driverName': 'Driver Utama',
      'lastMessagePreview': 'Terkirim',
      'lastMessageAt': '2026-11-01T08:00:00.000Z',
      'unreadCount': 2,
    });
    expect(conv.id, 'conv-01');
    expect(conv.driverName, 'Driver Utama');
    expect(conv.unreadCount, 2);

    final msg = ChatMessageModel.fromJson({
      'id': 'msg-01',
      'conversationId': 'conv-01',
      'senderId': 'user-driver',
      'ciphertextBlob': 'SGVsbG8=',
      'headerJson': {'iv': 'iv123'},
      'sentAt': '2026-11-01T08:00:00.000Z',
      'isRead': false,
    });
    expect(msg.id, 'msg-01');
    expect(msg.isRead, isFalse);
  });
}
