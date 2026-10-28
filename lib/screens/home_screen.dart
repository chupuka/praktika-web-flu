import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_config.dart';
import '../auth/permissions.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../widgets/app_shell.dart';
import '../widgets/role_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthNotifier>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final expiresAt = auth.sessionExpiresAt;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return AppShell(
      title: 'Мебельный магазин',
      actions: [
        RoleBadge(role: user.role),
        if (wide) ...[
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              user.fullName,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
        IconButton(
          tooltip: 'Выйти',
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
        ),
        const SizedBox(width: 8),
      ],
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Здравствуйте, ${user.fullName}',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Вы вошли как ${user.role.label.toLowerCase()} · ${user.email}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (expiresAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Сессия действует до '
                    '${_two(expiresAt.hour)}:${_two(expiresAt.minute)} '
                    '(лимит ${AuthConfig.sessionLimit.inMinutes} мин)',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Что доступно вашей роли',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final permission
                                in Permissions.forRole(user.role))
                              Chip(
                                avatar: const Icon(Icons.check, size: 16),
                                label: Text(permission.label),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 600
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _MenuTile(
                          width: width,
                          icon: Icons.chair_outlined,
                          title: 'Каталог товаров',
                          subtitle: 'Просмотр мебели, поиск и фильтры',
                          onTap: () => context.go('/products'),
                        ),
                        if (auth.can(Permission.viewOwnProfile))
                          _MenuTile(
                            width: width,
                            icon: Icons.card_membership,
                            title: 'Моя карточка',
                            subtitle: 'Профиль и бонусная карта покупателя',
                            onTap: () => context.go('/profile'),
                          ),
                        if (auth.has(Role.manager))
                          _MenuTile(
                            width: width,
                            icon: Icons.work_outline,
                            title: 'Рабочее место менеджера',
                            subtitle:
                                'Товары, справочники, покупатели и выдачи',
                            onTap: () => context.go('/manage'),
                          ),
                        if (auth.can(Permission.manageUsers))
                          _MenuTile(
                            width: width,
                            icon: Icons.admin_panel_settings_outlined,
                            title: 'Пользователи и роли',
                            subtitle: 'Только администратор',
                            onTap: () => context.go('/admin/users'),
                          ),
                        if (auth.can(Permission.viewStatistics))
                          _MenuTile(
                            width: width,
                            icon: Icons.insights_outlined,
                            title: 'Статистика',
                            subtitle: 'Сводка по каталогу и пользователям',
                            onTap: () => context.go('/admin/stats'),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _MenuTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
