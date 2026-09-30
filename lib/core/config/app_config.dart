class AppConfig {
  static const String appName = 'Armada Mobile';
  static const String appVersion = '1.0.0';
  static const String clientPlatform = 'Flutter-Mobile';

  /// Live Production API Base URL
  static const String apiBaseUrl = 'https://armada-api.prizftm.my.id/v1/';

  /// Network Timeout Configurations
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Official Testing Credentials
  static const String defaultOwnerUsername = 'owner';
  static const String defaultOwnerPassword = 'OwnerPass123!';

  static const String defaultDriverUsername = 'driver';
  static const String defaultDriverPassword = 'DriverPass123!';

  static const String defaultAdminUsername = 'admin';
  static const String defaultAdminPassword = 'AdminPass123!';
}
