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

      await storage.saveAuthSession(
        accessToken: authData.accessToken,
        refreshToken: authData.refreshToken,
        user: authData.user,
      );

      final me = await apiService.getMe();
      expect(me.username, equals('owner'));
      expect(me.isOwner, isTrue);
    });

    test('Driver login, SOS trigger (POST me/emergencies), and Owner resolve', () async {
      // 1. Driver Login
      final authData = await apiService.login('driver', 'DriverPass123!');
      expect(authData.user.role, equals('DRIVER'));

      await storage.saveAuthSession(
        accessToken: authData.accessToken,
        refreshToken: authData.refreshToken,
        user: authData.user,
      );

      // 2. Driver triggers SOS
      final emergency = await apiService.triggerEmergency(
        latitude: -6.2088,
        longitude: 106.8456,
        emergencyType: 'ACCIDENT',
        note: 'Live automated test emergency alert',
      );
      expect(emergency.id, isNotEmpty);
      expect(emergency.status, equals('TRIGGERED'));

      // 3. Driver checks active emergency
      final activeEm = await apiService.getActiveDriverEmergency();
      expect(activeEm?.id, equals(emergency.id));

      // 4. Owner logs in and resolves the emergency
      final ownerAuth = await apiService.login('owner', 'OwnerPass123!');
      await storage.saveAuthSession(
        accessToken: ownerAuth.accessToken,
        refreshToken: ownerAuth.refreshToken,
        user: ownerAuth.user,
      );

      await apiService.updateEmergencyStatus(emergency.id, 'RESOLVED');

      final list = await apiService.getEmergencies();
      final resolved = list.firstWhere((e) => e.id == emergency.id);
      expect(resolved.status, equals('RESOLVED'));
    });
  });
}
