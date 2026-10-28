class ApiConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://niaejpmbotuezuzfjpac.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pYWVqcG1ib3R1ZXp1emZqcGFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxOTAwNzIsImV4cCI6MjEwODc2NjA3Mn0.xyLaatFzl7z19yQj5wGLRXXU6WXWl04zFaJp4N6P1zI',
  );

  static const String baseUrl = '$supabaseUrl/rest/v1/';

  static const String authUrl = '$supabaseUrl/auth/v1';

  static const String emailDomain = 'mebel.local';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const int maxRetries = 3;
  static const Duration retryBaseDelay = Duration(milliseconds: 400);
  static const Duration referenceCacheTtl = Duration(minutes: 5);

  static const Map<String, String> emptyQuery = {};
}
