import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/api_config.dart';
import 'core/api_exceptions.dart';
import 'repositories/api_repositories.dart';
import 'repositories/repositories.dart';
import 'router.dart';
import 'state/category_list_notifier.dart';
import 'state/product_list_notifier.dart';
import 'widgets/state_views.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final client = ApiClient();
  String? loginError;
  try {
    await client.login(ApiConfig.demoUsername, ApiConfig.demoPassword);
    if (kDebugMode) {
      debugPrint('[API] вход выполнен: ${ApiConfig.demoUsername}');
    }
  } on ApiException catch (e) {
    loginError = e.message;
    if (kDebugMode) {
      debugPrint('[API] ошибка входа: ${e.message}');
    }
  }
  runApp(MebelApp(client: client, loginError: loginError));
}

class MebelApp extends StatelessWidget {
  final ApiClient client;
  final String? loginError;

  const MebelApp({super.key, required this.client, this.loginError});

  @override
  Widget build(BuildContext context) {
    if (loginError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
          useMaterial3: true,
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('Мебельный магазин')),
          body: ErrorView(
            message: 'Не удалось войти в API: $loginError',
            onRetry: () {},
          ),
        ),
      );
    }
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: client),
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
      child: const MebelAppView(),
    );
  }
}

class MebelAppView extends StatelessWidget {
  const MebelAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Мебельный магазин',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
