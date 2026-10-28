import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mebel_web/core/api_client.dart';
import 'package:mebel_web/models/app_user.dart';
import 'package:mebel_web/models/role.dart';
import 'package:mebel_web/repositories/auth_repository.dart';
import 'package:mebel_web/screens/home_screen.dart';
import 'package:mebel_web/state/auth_notifier.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  AppUser user;

  AuthSession get session => AuthSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresIn: 900,
        user: user,
      );

  @override
  Future<AuthSession> login(String username, String password) async => session;

  @override
  Future<AuthSession> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) async =>
      session;

  @override
  Future<AuthSession> refresh(String refreshToken) async => session;

  @override
  Future<AppUser> me() async => user;

  @override
  Future<void> logout(String? refreshToken) async {}
}

Future<AuthNotifier> _pumpHome(WidgetTester tester, AppUser user) async {
  SharedPreferences.setMockInitialValues({});
  final auth = AuthNotifier(
    prefs: await SharedPreferences.getInstance(),
    api: _FakeAuthRepository(user),
    client: ApiClient(),
  );
  await auth.login(user.username, 'password');

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<AuthNotifier>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets('покупателю не показываются разделы администратора',
      (tester) async {
    final auth = await _pumpHome(
      tester,
      const AppUser(
        id: '3',
        username: 'customer',
        fullName: 'Иванова Мария Петровна',
        email: 'kreslo.ivanovna@gmail.com',
        role: Role.customer,
        customerId: 1,
      ),
    );

    expect(find.text('Каталог товаров'), findsOneWidget);
    expect(find.text('Моя карточка'), findsOneWidget);
    expect(find.text('Пользователи и роли'), findsNothing);
    expect(find.text('Статистика'), findsNothing);
    expect(find.text('Рабочее место менеджера'), findsNothing);

    auth.dispose();
  });

  testWidgets('администратору показываются разделы управления', (tester) async {
    final auth = await _pumpHome(
      tester,
      const AppUser(
        id: '1',
        username: 'admin',
        fullName: 'Администратор',
        email: 'admin.za.divan@gmail.com',
        role: Role.admin,
      ),
    );

    expect(find.text('Пользователи и роли'), findsWidgets);
    expect(find.text('Статистика'), findsWidgets);
    expect(find.text('Рабочее место менеджера'), findsWidgets);

    auth.dispose();
  });
}
