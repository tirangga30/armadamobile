import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/user_model.dart';

void main() {
  group('UserModel Unit Tests', () {
    test('Correctly identifies Owner role and permissions', () {
      final ownerMap = {
        'id': '91516aab-bff0-452b-8667-604d191c931e',
        'username': 'owner',
        'email': 'owner@armada.local',
        'role': 'OWNER',
        'status': 'ACTIVE',
        'driverId': null,
      };

      final user = UserModel.fromJson(ownerMap);
      expect(user.isOwner, isTrue);
      expect(user.isDriver, isFalse);
      expect(user.isAdmin, isFalse);
      expect(user.displayName, equals('owner'));
    });

    test('Correctly identifies Driver role with DriverProfile', () {
      final driverMap = {
        'id': '57ad17ff-3d88-4601-88b9-17032a131c07',
        'username': 'driver',
        'role': 'DRIVER',
        'driver': {
          'id': '5a3d5134-04dd-4551-a4c7-0907e36e4084',
          'employeeCode': 'EMP-DEFAULT-001',
          'displayName': 'Driver Utama',
          'operationalStatus': 'AVAILABLE',
        },
      };

      final user = UserModel.fromJson(driverMap);
      expect(user.isDriver, isTrue);
      expect(user.isOwner, isFalse);
      expect(user.effectiveDriverId, equals('5a3d5134-04dd-4551-a4c7-0907e36e4084'));
      expect(user.displayName, equals('Driver Utama'));
    });
  });
}
