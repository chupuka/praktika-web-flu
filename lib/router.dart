import 'package:go_router/go_router.dart';

import 'auth/permissions.dart';
import 'models/category_query.dart';
import 'models/product_query.dart';
import 'screens/admin/admin_stats_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/auth/forbidden_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/category_detail_screen.dart';
import 'screens/category_form_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/customer_form_screen.dart';
import 'screens/entity_pages.dart';
import 'screens/home_screen.dart';
import 'screens/manager_home_screen.dart';
import 'screens/manufacturer_form_screen.dart';
import 'screens/material_form_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/profile_screen.dart';
import 'state/auth_notifier.dart';

String _forbidden(GoRouterState state) {
  return '/forbidden?from=${Uri.encodeComponent(state.uri.toString())}';
}

String _login(AuthNotifier auth, GoRouterState state) {
  final params = <String, String>{
    'from': state.uri.toString(),
  };
  final reason = auth.endedReason;
  if (reason != null && reason != SessionEndReason.manual) {
    params['reason'] = reason.name;
  }
  return Uri(path: '/login', queryParameters: params).toString();
}

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';
      final loggedIn = auth.isAuthenticated;
      final from = state.uri.queryParameters['from'];

      if (!loggedIn && !isPublic) return _login(auth, state);

      if (loggedIn && isPublic) {
        if (from != null &&
            from.startsWith('/') &&
            !from.startsWith('/login') &&
            !from.startsWith('/register')) {
          return from;
        }
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          from: state.uri.queryParameters['from'],
          reason: state.uri.queryParameters['reason'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(
          from: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => ForbiddenScreen(
          path: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        redirect: (context, state) =>
            auth.can(Permission.viewOwnProfile) ? null : _forbidden(state),
      ),
      GoRoute(
        path: '/manage',
        builder: (context, state) => const ManagerHomeScreen(),
        redirect: (context, state) =>
            auth.can(Permission.manageProducts) ? null : _forbidden(state),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
        redirect: (context, state) =>
            auth.can(Permission.manageUsers) ? null : _forbidden(state),
      ),
      GoRoute(
        path: '/admin/stats',
        builder: (context, state) => const AdminStatsScreen(),
        redirect: (context, state) =>
            auth.can(Permission.viewStatistics) ? null : _forbidden(state),
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
            redirect: (context, state) =>
                auth.can(Permission.manageProducts) ? null : _forbidden(state),
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
            redirect: (context, state) =>
                auth.can(Permission.manageProducts) ? null : _forbidden(state),
          ),
        ],
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => CategoryListScreen(
          initialQuery: CategoryQuery.fromParameters(state.uri.queryParameters),
        ),
        redirect: (context, state) =>
            auth.can(Permission.manageReferences) ? null : _forbidden(state),
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
        redirect: (context, state) =>
            auth.can(Permission.manageReferences) ? null : _forbidden(state),
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
        redirect: (context, state) =>
            auth.can(Permission.manageReferences) ? null : _forbidden(state),
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
        redirect: (context, state) =>
            auth.can(Permission.manageCustomers) ? null : _forbidden(state),
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
}
