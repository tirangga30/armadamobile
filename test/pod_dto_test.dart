import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/pod_dto.dart';
import 'package:armada_mobile/data/models/delivery_model.dart';

void main() {
  test('SubmitPodDto serializes to JSON with idempotencyKey and optional notes', () {
    final dto = SubmitPodDto(
      receiverName: 'Budi Santoso',
      photoFileId: 'f-123',
      signatureFileId: 's-456',
      notes: 'Diterima utuh',
      idempotencyKey: 'idem-uuid-001',
    );
    final json = dto.toJson();
    expect(json['receiverName'], 'Budi Santoso');
    expect(json['photoFileId'], 'f-123');
    expect(json['signatureFileId'], 's-456');
    expect(json['notes'], 'Diterima utuh');
    expect(json['idempotencyKey'], 'idem-uuid-001');
  });

  test('FailStopDto serializes to JSON with structured reason and notes', () {
    final dto = FailStopDto(
      reason: 'STORE_CLOSED',
      notes: 'Toko tutup pukul 17:00',
    );
    final json = dto.toJson();
    expect(json['reason'], 'STORE_CLOSED');
    expect(json['notes'], 'Toko tutup pukul 17:00');
  });

  test('UploadedFileResponse parses server response correctly', () {
    final res = UploadedFileResponse.fromJson({
      'fileId': 'file-01',
      'objectKey': 'pod/2026/10/file-01.jpg',
      'mediaType': 'image/jpeg',
      'sizeBytes': 204800,
    });
    expect(res.fileId, 'file-01');
    expect(res.sizeBytes, 204800);
  });

  test('DeliveryStop parses nested pod and failReason correctly', () {
    final stop = DeliveryStop.fromJson({
      'id': 'stop-99',
      'sequence': 2,
      'destinationName': 'Toko Berkah',
      'address': 'Jl. Kenanga No. 12',
      'status': 'DELIVERED',
      'failReason': null,
      'pod': {
        'receiverName': 'Ahmad',
        'photoFileId': 'photo-99',
        'signatureFileId': 'sig-99',
      }
    });
    expect(stop.id, 'stop-99');
    expect(stop.status, 'DELIVERED');
    expect(stop.pod, isNotNull);
    expect(stop.pod?.receiverName, 'Ahmad');
  });
}
