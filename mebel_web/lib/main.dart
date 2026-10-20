import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/json_store.dart';
import 'repositories/repositories.dart';
import 'router.dart';
import 'state/category_list_notifier.dart';
import 'state/product_list_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  runApp(MebelApp(store: JsonStore(prefs)));
}

class MebelApp extends StatelessWidget {
  final JsonStore store;

  const MebelApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<JsonStore>.value(value: store),
        Provider<ProductRepository>(
          create: (_) => PersistentProductRepository(store),
        ),
        Provider<CategoryRepository>(
          create: (context) => PersistentCategoryRepository(
            store,
            context.read<ProductRepository>(),
          ),
        ),
        Provider<ManufacturerRepository>(
          create: (context) => PersistentManufacturerRepository(
            store,
            context.read<ProductRepository>(),
          ),
        ),
        Provider<MaterialRepository>(
          create: (context) => PersistentMaterialRepository(
            store,
            context.read<ProductRepository>(),
          ),
        ),
        Provider<CustomerRepository>(
          create: (_) => PersistentCustomerRepository(store),
        ),
        Provider<ReferenceRepository>(
          create: (context) => InMemoryReferenceRepository(
            context.read<CategoryRepository>(),
            context.read<ManufacturerRepository>(),
            context.read<MaterialRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ProductListNotifier(context.read<ProductRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CategoryListNotifier(
            context.read<CategoryRepository>(),
            context.read<ProductRepository>(),
          ),
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
