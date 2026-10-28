import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/permissions.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class ShellDestination {
  final String path;
  final String label;
  final String shortLabel;
  final IconData icon;
  final IconData selectedIcon;

  const ShellDestination({
    required this.path,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.selectedIcon,
  });
}

class AppShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? leading;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.leading,
    this.floatingActionButton,
  });

  static const double _railBreakpoint = 600;
  static const double _extendedBreakpoint = 1000;

  List<ShellDestination> _destinations(AuthNotifier auth) {
    return [
      const ShellDestination(
        path: '/',
        label: 'Главная',
        shortLabel: 'Главная',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
      ),
      const ShellDestination(
        path: '/products',
        label: 'Каталог',
        shortLabel: 'Каталог',
        icon: Icons.chair_outlined,
        selectedIcon: Icons.chair,
      ),
      if (auth.can(Permission.viewOwnProfile))
        const ShellDestination(
          path: '/profile',
          label: 'Моя карточка',
          shortLabel: 'Карточка',
          icon: Icons.card_membership_outlined,
          selectedIcon: Icons.card_membership,
        ),
      if (auth.can(Permission.viewOwnOrders))
        const ShellDestination(
          path: '/my-orders',
          label: 'Мои заказы',
          shortLabel: 'Заказы',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
        ),
      if (auth.can(Permission.viewOrders))
        const ShellDestination(
          path: '/orders',
          label: 'Заказы',
          shortLabel: 'Заказы',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
        ),
      if (auth.has(Role.manager))
        const ShellDestination(
          path: '/manage',
          label: 'Рабочее место',
          shortLabel: 'Менеджер',
          icon: Icons.work_outline,
          selectedIcon: Icons.work,
        ),
      if (auth.can(Permission.manageUsers))
        const ShellDestination(
          path: '/admin/users',
          label: 'Пользователи и роли',
          shortLabel: 'Люди',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
        ),
      if (auth.can(Permission.viewStatistics))
        const ShellDestination(
          path: '/admin/stats',
          label: 'Статистика',
          shortLabel: 'Статистика',
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights,
        ),
    ];
  }

  int _selectedIndex(List<ShellDestination> destinations, String path) {
    if (path == '/') return 0;
    if (path.startsWith('/products')) {
      return destinations.indexWhere((d) => d.path == '/products');
    }
    if (path.startsWith('/admin/users')) {
      return destinations.indexWhere((d) => d.path == '/admin/users');
    }
    if (path.startsWith('/admin/stats')) {
      return destinations.indexWhere((d) => d.path == '/admin/stats');
    }
    if (path.startsWith('/profile')) {
      return destinations.indexWhere((d) => d.path == '/profile');
    }
    if (path.startsWith('/my-orders')) {
      return destinations.indexWhere((d) => d.path == '/my-orders');
    }
    if (path.startsWith('/orders')) {
      return destinations.indexWhere((d) => d.path == '/orders');
    }
    for (final prefix in [
      '/manage',
      '/categories',
      '/manufacturers',
      '/materials',
      '/customers'
    ]) {
      if (path.startsWith(prefix)) {
        return destinations.indexWhere((d) => d.path == '/manage');
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final destinations = _destinations(auth);
    final path = GoRouterState.of(context).uri.path;
    final index = _selectedIndex(destinations, path);

    void go(int value) {
      if (value < 0 || value >= destinations.length) return;
      final target = destinations[value].path;
      if (target != path) context.go(target);
    }

    final appBar = AppBar(
      title: Text(title, overflow: TextOverflow.ellipsis),
      leading: leading,
      actions: actions,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= _railBreakpoint) {
          final extended = width >= _extendedBreakpoint;
          return Scaffold(
            appBar: appBar,
            floatingActionButton: floatingActionButton,
            body: Row(
              children: [
                NavigationRail(
                  extended: extended,
                  minWidth: extended ? null : 96,
                  selectedIndex: index,
                  onDestinationSelected: go,
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(
                          extended ? destination.label : destination.shortLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: appBar,
          floatingActionButton: floatingActionButton,
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: go,
            destinations: [
              for (final destination in destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.shortLabel,
                ),
            ],
          ),
        );
      },
    );
  }
}
