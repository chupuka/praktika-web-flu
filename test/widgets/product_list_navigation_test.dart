import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mebel_web/core/api_client.dart';
import 'package:mebel_web/models/app_user.dart';
import 'package:mebel_web/models/category.dart';
import 'package:mebel_web/models/manufacturer.dart';
import 'package:mebel_web/models/material.dart';
import 'package:mebel_web/models/page_result.dart';
import 'package:mebel_web/models/product.dart';
import 'package:mebel_web/models/product_query.dart';
import 'package:mebel_web/models/role.dart';
import 'package:mebel_web/repositories/auth_repository.dart';
import 'package:mebel_web/repositories/repositories.dart';
import 'package:mebel_web/screens/product_list_screen.dart';
import 'package:mebel_web/state/auth_notifier.dart';
import 'package:mebel_web/state/product_list_notifier.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepository implements AuthRepository {
  AuthSession get session => const AuthSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresIn: 900,
        user: AppUser(
          id: '1',
          username: 'admin',
          fullName: 'Администратор',
          email: 'admin@example.com',
          role: Role.admin,
        ),
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
  Future<AppUser> me() async => session.user;

  @override
  Future<void> logout(String? refreshToken) async {}
}

class _FakeProductRepository implements ProductRepository {
  @override
  Future<PageResult<Product>> find(
    ProductQuery query, {
    CancelToken? cancelToken,
  }) async {
    return PageResult<Product>(
      items: [
        Product(
          id: query.page,
          name: 'Товар ${query.page}',
          price: 100,
          categoryId: 1,
          manufacturerId: 1,
        ),
      ],
      page: query.page,
      size: query.size,
      total: 25,
    );
  }

  @override
  Future<int> create(Product product) async => 1;

  @override
  Future<int> deleteMany(List<int> ids) async => ids.length;

  @override
  Future<Product?> findById(int id) async => null;

  @override
  Future<void> hardDelete(int id) async {}

  @override
  Future<void> restore(int id) async {}

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> update(Product product) async {}
}

class _FakeReferenceRepository extends ChangeNotifier
    implements ReferenceRepository {
  @override
  List<Category> categories() => const [];

  @override
  String categoryName(int id) => 'Категория';

  @override
  int countProductsByCategory(int categoryId) => 0;

  @override
  int countProductsByManufacturer(int manufacturerId) => 0;

  @override
  int countProductsByMaterial(int materialId) => 0;

  @override
  Future<void> ensureLoaded() async {}

  @override
  List<Manufacturer> manufacturers() => const [];

  @override
  String manufacturerName(int id) => 'Производитель';

  @override
  List<String> materialNames(List<int> ids) => const [];

  @override
  List<FurnitureMaterial> materials() => const [];

  @override
  Future<void> refresh() async {}
}

void main() {
  testWidgets('переход на другую страницу показывает её данные',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthNotifier(
      prefs: await SharedPreferences.getInstance(),
      api: _FakeAuthRepository(),
      client: ApiClient(),
    );
    await auth.login('admin', 'password');

    final notifier = ProductListNotifier(_FakeProductRepository());
    final refs = _FakeReferenceRepository();
    final router = GoRouter(
      initialLocation: '/products',
      routes: [
        GoRoute(
          path: '/products',
          builder: (context, state) => ProductListScreen(
            initialQuery:
                ProductQuery.fromParameters(state.uri.queryParameters),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthNotifier>.value(value: auth),
          ChangeNotifierProvider<ProductListNotifier>.value(value: notifier),
          ListenableProvider<ReferenceRepository>.value(value: refs),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Товар 1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    router.go('/products?page=2');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Товар 2'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Страница 2 из 3 • Всего: 25'), findsOneWidget);

    auth.dispose();
    notifier.dispose();
  });
}
