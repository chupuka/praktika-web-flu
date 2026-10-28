import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_shell.dart';

class ManagerHomeScreen extends StatelessWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppShell(
      title: 'Рабочее место менеджера',
      actions: [
        if (MediaQuery.sizeOf(context).width >= 700)
          FilledButton.icon(
            onPressed: () => context.go('/products/new'),
            icon: const Icon(Icons.add),
            label: const Text('Добавить товар'),
          )
        else
          IconButton(
            tooltip: 'Добавить товар',
            onPressed: () => context.go('/products/new'),
            icon: const Icon(Icons.add),
          ),
        const SizedBox(width: 12),
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
                  'Управление каталогом',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Менеджер ведёт товары и справочники, оформляет и закрывает '
                  'выдачи, работает с покупателями. Окончательное удаление и '
                  'восстановление записей доступны только администратору.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _Tile(
                      icon: Icons.chair_outlined,
                      title: 'Товары',
                      subtitle: 'Список, фильтры, создание и правка',
                      onTap: () => context.go('/products'),
                    ),
                    _Tile(
                      icon: Icons.category_outlined,
                      title: 'Категории',
                      subtitle: 'Справочник категорий мебели',
                      onTap: () => context.go('/categories'),
                    ),
                    _Tile(
                      icon: Icons.factory_outlined,
                      title: 'Производители',
                      subtitle: 'Фабрики и контактные данные',
                      onTap: () => context.go('/manufacturers'),
                    ),
                    _Tile(
                      icon: Icons.layers_outlined,
                      title: 'Материалы',
                      subtitle: 'Обивка, дерево, металл, стекло',
                      onTap: () => context.go('/materials'),
                    ),
                    _Tile(
                      icon: Icons.people_outline,
                      title: 'Покупатели',
                      subtitle: 'Карточки и бонусные карты',
                      onTap: () => context.go('/customers'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 30),
                const SizedBox(height: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
