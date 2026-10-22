import 'package:go_router/go_router.dart';

import 'models/category_query.dart';
import 'models/product_query.dart';
import 'screens/category_detail_screen.dart';
import 'screens/category_form_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/customer_form_screen.dart';
import 'screens/entity_pages.dart';
import 'screens/home_screen.dart';
import 'screens/manufacturer_form_screen.dart';
import 'screens/material_form_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_form_screen.dart';
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
        initialQuery: ProductQuery.fromParameters(state.uri.queryParameters),
      ),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const ProductFormScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) => ProductDetailScreen(
            id: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => ProductFormScreen(
            id: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => CategoryListScreen(
        initialQuery: CategoryQuery.fromParameters(state.uri.queryParameters),
      ),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const CategoryFormScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) => CategoryDetailScreen(
            id: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => CategoryFormScreen(
            id: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/manufacturers',
      builder: (context, state) => const ManufacturerListPage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const ManufacturerFormScreen(),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => ManufacturerFormScreen(
            id: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/materials',
      builder: (context, state) => const MaterialListPage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const MaterialFormScreen(),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => MaterialFormScreen(
            id: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomerListPage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const CustomerFormScreen(),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => CustomerFormScreen(
            id: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      NotFoundScreen(location: state.uri.toString()),
);
