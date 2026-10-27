class AuthConfig {
  const AuthConfig._();

  static const Duration idleTimeout = Duration(
    seconds: int.fromEnvironment('AUTH_IDLE_SECONDS', defaultValue: 180),
  );

  static const Duration idleWarning = Duration(
    seconds: int.fromEnvironment('AUTH_WARNING_SECONDS', defaultValue: 30),
  );

  static const Duration sessionLimit = Duration(
    seconds: int.fromEnvironment('AUTH_SESSION_SECONDS', defaultValue: 3600),
  );
}
