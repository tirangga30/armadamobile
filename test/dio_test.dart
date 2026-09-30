import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';

class _AllowAllHttpOverrides extends HttpOverrides {}

void main() {
  HttpOverrides.global = _AllowAllHttpOverrides();

  group('Live API Integration Tests', () {
    late SecureStorageService storage;
    late DioClient dioClient;
    late ArmadaApiService apiService;

    setUp(() {
      storage = SecureStorageService();
      dioClient = DioClient(storageService: storage);
      apiService = ArmadaApiService(client: dioClient);
    });

    test('Owner login and profile retrieval against live backend', () async {
      final authData = await apiService.login('owner', 'OwnerPass123!');
      expect(authData.accessToken, isNotEmpty);
      expect(authData.user.role, equals('OWNER'));

      // Save token in storage
      await storage.saveAuthSession(
        accessToken: authData.accessToken,
        refreshToken: authData.refreshToken,
        user: authData.user,
      );

      // Verify users/me with bearer token
      final me = await apiService.getMe();
      expect(me.username, equals('owner'));
      expect(me.isOwner, isTrue);
    });

    test('Driver login and profile retrieval against live backend', () async {
      final authData = await apiService.login('driver', 'DriverPass123!');
      expect(authData.accessToken, isNotEmpty);
      expect(authData.user.role, equals('DRIVER'));
      expect(authData.user.driverId, equals('5a3d5134-04dd-4551-a4c7-0907e36e4084'));

      // Save token in storage
      await storage.saveAuthSession(
        accessToken: authData.accessToken,
        refreshToken: authData.refreshToken,
        user: authData.user,
      );

      // Verify users/me with bearer token
      final me = await apiService.getMe();
      expect(me.username, equals('driver'));
      expect(me.isDriver, isTrue);
      expect(me.driver?.employeeCode, equals('EMP-DEFAULT-001'));
    });
  });
}
