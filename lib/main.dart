import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_config.dart';
import 'core/api_client.dart';
import 'repositories/api_auth_repository.dart';
import 'repositories/api_repositories.dart';
import 'repositories/auth_repository.dart';
import 'repositories/repositories.dart';
import 'router.dart';
import 'state/auth_notifier.dart';
import 'state/category_list_notifier.dart';
import 'state/product_list_notifier.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  final client = ApiClient();
  final auth = AuthNotifier(
    prefs: prefs,
    api: ApiAuthRepository(client),
    client: client,
  );
  await auth.restore();
  runApp(MebelApp(client: client, auth: auth));
}

class MebelApp extends StatelessWidget {
  final ApiClient client;
  final AuthNotifier auth;

  const MebelApp({super.key, required this.client, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: client),
        ChangeNotifierProvider<AuthNotifier>.value(value: auth),
        Provider<UserRepository>(
          create: (context) => ApiUserRepository(context.read<ApiClient>()),
        ),
        Provider<ProductRepository>(
          create: (context) => ApiProductRepository(context.read<ApiClient>()),
        ),
        Provider<CategoryRepository>(
          create: (context) => ApiCategoryRepository(context.read<ApiClient>()),
        ),
        Provider<ManufacturerRepository>(
          create: (context) =>
              ApiManufacturerRepository(context.read<ApiClient>()),
        ),
        Provider<MaterialRepository>(
          create: (context) => ApiMaterialRepository(context.read<ApiClient>()),
        ),
        Provider<CustomerRepository>(
          create: (context) => ApiCustomerRepository(context.read<ApiClient>()),
        ),
        ListenableProvider<ReferenceRepository>(
          create: (context) => ApiReferenceRepository(
            products: context.read<ProductRepository>(),
            categories: context.read<CategoryRepository>(),
            manufacturers: context.read<ManufacturerRepository>(),
            materials: context.read<MaterialRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ProductListNotifier(context.read<ProductRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CategoryListNotifier(context.read<CategoryRepository>()),
        ),
      ],
      child: MebelAppView(auth: auth),
    );
  }
}

class MebelAppView extends StatelessWidget {
  final AuthNotifier auth;

  const MebelAppView({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Мебельный магазин',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      routerConfig: buildRouter(auth),
      builder: (context, child) {
        return Consumer<AuthNotifier>(
          builder: (context, auth, _) {
            return InactivityWatcher(
              enabled: auth.isAuthenticated,
              timeout: AuthConfig.idleTimeout,
              warning: AuthConfig.idleWarning,
              onTimeout: () {
                if (auth.isAuthenticated) {
                  auth.logout(reason: SessionEndReason.idle);
                }
              },
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
