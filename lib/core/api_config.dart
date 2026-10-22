class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  static const String demoUsername = String.fromEnvironment(
    'API_USERNAME',
    defaultValue: 'manager',
  );

  static const String demoPassword = String.fromEnvironment(
    'API_PASSWORD',
    defaultValue: 'manager123',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const int maxRetries = 3;
  static const Duration retryBaseDelay = Duration(milliseconds: 400);
  static const Duration referenceCacheTtl = Duration(minutes: 5);

  static const Map<String, String> emptyQuery = {};
}
