import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'repositories/repositories.dart';
import 'router.dart';
import 'state/category_list_notifier.dart';
import 'state/product_list_notifier.dart';

void main() {
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        Provider<ProductRepository>(
          create: (_) => InMemoryProductRepository(),
        ),
        Provider<CategoryRepository>(
          create: (_) => InMemoryCategoryRepository(),
        ),
        Provider<ReferenceRepository>(
          create: (_) => InMemoryReferenceRepository(),
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
      child: const MebelApp(),
    ),
  );
}

class MebelApp extends StatelessWidget {
  const MebelApp({super.key});

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
