import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('ArmadaApiService defines all stop execution methods', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);

    expect(api.departStop, isNotNull);
    expect(api.arriveStop, isNotNull);
    expect(api.unloadStop, isNotNull);
    expect(api.failStop, isNotNull);
    expect(api.submitStopPod, isNotNull);
    expect(api.completeDelivery, isNotNull);
    expect(api.uploadFile, isNotNull);
  });
}
