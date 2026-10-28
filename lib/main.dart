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
        Provider<OrderRepository>(
          create: (context) => ApiOrderRepository(context.read<ApiClient>()),
        ),
        Provider<ReviewRepository>(
          create: (context) => ApiReviewRepository(context.read<ApiClient>()),
        ),
        Provider<StatsRepository>(
          create: (context) => ApiStatsRepository(context.read<ApiClient>()),
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
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF855300),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFF59E0B),
      onPrimaryContainer: Color(0xFF613B00),
      secondary: Color(0xFF7D5725),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFCB8F),
      onSecondaryContainer: Color(0xFF795423),
      tertiary: Color(0xFF00658B),
      onTertiary: Colors.white,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: Color(0xFFFFF8F4),
      onSurface: Color(0xFF221A12),
      surfaceContainerHighest: Color(0xFFF0E0D1),
      onSurfaceVariant: Color(0xFF534434),
      outline: Color(0xFF867461),
      outlineVariant: Color(0xFFD8C3AD),
    );
    return MaterialApp.router(
      title: 'Mebel — мебель для дома',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: scheme.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF221A12),
          elevation: 0,
          scrolledUnderElevation: 1,
          titleTextStyle: TextStyle(
            color: Color(0xFF221A12),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD8C3AD)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD8C3AD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD8C3AD)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFFFDDB8),
          elevation: 1,
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFFFDDB8),
        ),
        dividerColor: const Color(0xFFD8C3AD),
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
