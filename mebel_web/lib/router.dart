import 'package:go_router/go_router.dart';

import 'models/category_query.dart';
import 'models/product_query.dart';
import 'screens/category_detail_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_list_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => ProductListScreen(
        initialQuery:
            ProductQuery.fromParameters(state.uri.queryParameters),
      ),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => ProductDetailScreen(
            id: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => CategoryListScreen(
        initialQuery:
            CategoryQuery.fromParameters(state.uri.queryParameters),
      ),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => CategoryDetailScreen(
            id: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      NotFoundScreen(location: state.uri.toString()),
);
