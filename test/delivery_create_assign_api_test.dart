import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('ArmadaApiService exposes createDelivery, assignDelivery, and getDeliveryDetail methods', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);

    expect(api.createDelivery, isNotNull);
    expect(api.assignDelivery, isNotNull);
    expect(api.getDeliveryDetail, isNotNull);
  });
}
