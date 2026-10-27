import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/auth_notifier.dart';
import '../../widgets/role_badge.dart';

class ForbiddenScreen extends StatelessWidget {
  final String? path;

  const ForbiddenScreen({super.key, this.path});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступ запрещён'),
        leading: IconButton(
          tooltip: 'На главную',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block,
                  size: 72,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Недостаточно прав',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'У вашей роли нет доступа к этому разделу.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                if (path != null && path!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Запрошенный адрес: $path',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (user != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Текущая роль: ', style: theme.textTheme.bodyMedium),
                      RoleBadge(role: user.role),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Вернуться на главную'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
