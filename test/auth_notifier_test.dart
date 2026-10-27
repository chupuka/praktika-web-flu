import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/core/api_client.dart';
import 'package:mebel_web/core/api_exceptions.dart';
import 'package:mebel_web/models/app_user.dart';
import 'package:mebel_web/models/role.dart';
import 'package:mebel_web/repositories/auth_repository.dart';
import 'package:mebel_web/state/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthRepository implements AuthRepository {
  AppUser user = const AppUser(
    id: 3,
    username: 'customer',
    fullName: 'Иванова Мария Петровна',
    email: 'kreslo.ivanovna@gmail.com',
    role: Role.customer,
    customerId: 1,
  );

  int loginCalls = 0;
  int refreshCalls = 0;
  int meCalls = 0;
  int logoutCalls = 0;
  bool failRefresh = false;
  Completer<void>? refreshGate;

  AuthSession get session => AuthSession(
        accessToken: 'access-${loginCalls + refreshCalls}',
        refreshToken: 'refresh-${loginCalls + refreshCalls}',
        expiresIn: 900,
        user: user,
      );

  @override
  Future<AuthSession> login(String username, String password) async {
    loginCalls += 1;
    return session;
  }

  @override
  Future<AuthSession> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) async {
    return session;
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    refreshCalls += 1;
    if (refreshGate != null) await refreshGate!.future;
    if (failRefresh) throw const UnauthorizedException('Токен отозван');
    return session;
  }

  @override
  Future<AppUser> me() async {
    meCalls += 1;
    return user;
  }

  @override
  Future<void> logout(String? refreshToken) async {
    logoutCalls += 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository api;
  late ApiClient client;
  late AuthNotifier auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api = FakeAuthRepository();
    client = ApiClient();
    auth = AuthNotifier(
      prefs: await SharedPreferences.getInstance(),
      api: api,
      client: client,
    );
  });

  tearDown(() => auth.dispose());

  test('вход сохраняет токены и пользователя в localStorage', () async {
    await auth.login('customer', 'customer123');

    final prefs = await SharedPreferences.getInstance();
    expect(auth.isAuthenticated, isTrue);
    expect(auth.user?.role, Role.customer);
    expect(prefs.getString('auth_access_token'), isNotEmpty);
    expect(prefs.getString('auth_refresh_token'), isNotEmpty);
    expect(
      jsonDecode(prefs.getString('auth_user')!)['role'],
      'customer',
    );
    expect(client.accessToken, prefs.getString('auth_access_token'));
    expect(auth.sessionExpiresAt, isNotNull);
  });

  test('сессия восстанавливается из localStorage без запроса к серверу',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_access_token', 'access-1');
    await prefs.setString('auth_refresh_token', 'refresh-1');
    await prefs.setString('auth_started_at', DateTime.now().toIso8601String());
    await prefs.setString(
      'auth_user',
      jsonEncode(api.user.toJson()),
    );

    final restored = AuthNotifier(
      prefs: prefs,
      api: api,
      client: ApiClient(),
    );
    addTearDown(restored.dispose);
    await restored.restore();

    expect(restored.isAuthenticated, isTrue);
    expect(restored.user?.username, 'customer');
    expect(api.meCalls, 0);
  });

  test('выход очищает токены и возвращает причину', () async {
    await auth.login('customer', 'customer123');
    await auth.logout(reason: SessionEndReason.idle);

    final prefs = await SharedPreferences.getInstance();
    expect(auth.isAuthenticated, isFalse);
    expect(auth.endedReason, SessionEndReason.idle);
    expect(prefs.getString('auth_access_token'), isNull);
    expect(prefs.getString('auth_refresh_token'), isNull);
    expect(prefs.getString('auth_user'), isNull);
    expect(api.logoutCalls, 1);
  });

  test('обновление токена выполняется один раз при параллельных вызовах',
      () async {
    await auth.login('customer', 'customer123');
    api.refreshGate = Completer<void>();

    final first = auth.refreshTokens();
    final second = auth.refreshTokens();
    expect(api.refreshCalls, 1);
    api.refreshGate!.complete();
    await Future.wait([first, second]);

    expect(api.refreshCalls, 1);
    expect(auth.accessToken, startsWith('access-'));
  });

  test('неудачное обновление завершает сессию без цикла', () async {
    await auth.login('customer', 'customer123');
    api.failRefresh = true;

    final refreshed = await client.onUnauthorized!();

    expect(refreshed, isFalse);
    expect(auth.isAuthenticated, isFalse);
    expect(auth.endedReason, SessionEndReason.expired);
  });

  test('просроченный лимит сессии при восстановлении завершает её', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_access_token', 'access-1');
    await prefs.setString('auth_refresh_token', 'refresh-1');
    await prefs.setString(
      'auth_started_at',
      DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    );
    await prefs.setString('auth_user', jsonEncode(api.user.toJson()));

    final expired = AuthNotifier(
      prefs: prefs,
      api: api,
      client: ApiClient(),
    );
    addTearDown(expired.dispose);
    await expired.restore();

    expect(expired.isAuthenticated, isFalse);
    expect(expired.endedReason, SessionEndReason.absolute);
    expect(prefs.getString('auth_access_token'), isNull);
  });
}
