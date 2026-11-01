import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptedPayload {
  final String ciphertextBlob;
  final Map<String, dynamic> headerJson;

  const EncryptedPayload({
    required this.ciphertextBlob,
    required this.headerJson,
  });

  Map<String, dynamic> toJson() => {
        'ciphertextBlob': ciphertextBlob,
        'headerJson': headerJson,
      };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) => EncryptedPayload(
        ciphertextBlob: json['ciphertextBlob']?.toString() ?? '',
        headerJson: json['headerJson'] is Map<String, dynamic>
            ? json['headerJson'] as Map<String, dynamic>
            : {},
      );
}

class E2eeCryptoService {
  /// Derives a consistent 32-byte key from any input key string using SHA-256
  static Uint8List derive32ByteKey(String keyString) {
    final bytes = utf8.encode(keyString);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  /// Encrypts plaintext using AES-256-CBC with a secure random IV
  static EncryptedPayload encrypt(String plaintext, String keyString) {
    final keyBytes = derive32ByteKey(keyString);
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(16);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return EncryptedPayload(
      ciphertextBlob: encrypted.base64,
      headerJson: {
        'iv': iv.base64,
        'algorithm': 'AES-256-CBC',
      },
    );
  }

  /// Decrypts Base64 ciphertextBlob using keyString and Base64 IV
  static String decrypt(String ciphertextBlob, String keyString, String ivBase64) {
    final keyBytes = derive32ByteKey(keyString);
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromBase64(ivBase64);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt64(ciphertextBlob, iv: iv);
  }
}
