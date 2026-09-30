import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/user_model.dart';

class SecureStorageService {
  static const String _keyAccessToken = 'armada_access_token';
  static const String _keyRefreshToken = 'armada_refresh_token';
  static const String _keyUserData = 'armada_user_data';
  static const String _keyUserRole = 'armada_user_role';
  static const String _keyDriverId = 'armada_driver_id';

  final FlutterSecureStorage _storage;

  // In-memory fallback for environments where secure platform storage might have restrictions
  final Map<String, String> _memoryCache = {};

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  Future<void> saveAuthSession({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) async {
    await _write(_keyAccessToken, accessToken);
    await _write(_keyRefreshToken, refreshToken);
    await _write(_keyUserRole, user.role);
    await _write(_keyUserData, jsonEncode(user.toJson()));
    if (user.driverId != null) {
      await _write(_keyDriverId, user.driverId!);
    }
  }

  Future<String?> getAccessToken() async {
    return await _read(_keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _read(_keyRefreshToken);
  }

  Future<String?> getUserRole() async {
    return await _read(_keyUserRole);
  }

  Future<String?> getDriverId() async {
    return await _read(_keyDriverId);
  }

  Future<UserModel?> getUserData() async {
    final rawJson = await _read(_keyUserData);
    if (rawJson == null || rawJson.isEmpty) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(rawJson);
      return UserModel.fromJson(map);
    } catch (e) {
      debugPrint('Error parsing stored user data: $e');
      return null;
    }
  }

  Future<void> updateUserData(UserModel user) async {
    await _write(_keyUserData, jsonEncode(user.toJson()));
    await _write(_keyUserRole, user.role);
    if (user.driverId != null) {
      await _write(_keyDriverId, user.driverId!);
    }
  }

  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing secure storage: $e');
    }
    _memoryCache.clear();
  }

  // Internal read/write with memory fallback
  Future<void> _write(String key, String value) async {
    _memoryCache[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('SecureStorage write error for $key (falling back to memory): $e');
    }
  }

  Future<String?> _read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) {
        _memoryCache[key] = value;
        return value;
      }
    } catch (e) {
      debugPrint('SecureStorage read error for $key (using memory cache): $e');
    }
    return _memoryCache[key];
  }
}
