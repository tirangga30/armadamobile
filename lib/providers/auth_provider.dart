import 'package:flutter/foundation.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/armada_api_service.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final ArmadaApiService _apiService;
  final SecureStorageService _storageService;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthProvider({
    required ArmadaApiService apiService,
    required SecureStorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isOwner => _user?.isOwner ?? false;
  bool get isDriver => _user?.isDriver ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;

  /// Check stored session on application launch
  Future<void> checkSession() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final hasSession = await _storageService.hasValidSession();
      if (!hasSession) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Try fetching active profile from backend
      try {
        final profile = await _apiService.getMe();
        _user = profile;
        await _storageService.updateUserData(profile);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('⚠️ Network profile sync failed, falling back to cached user: $e');
        final cachedUser = await _storageService.getUserData();
        if (cachedUser != null) {
          _user = cachedUser;
          _status = AuthStatus.authenticated;
          notifyListeners();
          return;
        }
      }

      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      debugPrint('Session check error: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Perform login against backend API
  Future<bool> login(String username, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final authData = await _apiService.login(username, password);

      // Persist auth tokens
      await _storageService.saveAuthSession(
        accessToken: authData.accessToken,
        refreshToken: authData.refreshToken,
        user: authData.user,
      );

      // Fetch comprehensive profile details (driver details, phone, etc)
      UserModel fullUser = authData.user;
      try {
        final me = await _apiService.getMe();
        fullUser = me;
        await _storageService.updateUserData(fullUser);
      } catch (e) {
        debugPrint('Notice loading full profile: $e');
      }

      _user = fullUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Gagal melakukan login: $e';
      notifyListeners();
      return false;
    }
  }

  /// Logout and wipe tokens
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (_) {}

    await _storageService.clearSession();
    _user = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
