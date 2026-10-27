import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../models/app_user.dart';
import '../../models/role.dart';
import '../../repositories/auth_repository.dart';
import '../../state/load_status.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/state_views.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  LoadStatus _status = LoadStatus.loading;
  List<AppUser> _users = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _withCode(ApiException error) {
    final code = switch (error) {
      ForbiddenException() => 403,
      UnauthorizedException() => 401,
      ConflictException() => 409,
      NotFoundException() => 404,
      _ => null,
    };
    return code == null
        ? error.message
        : 'Сервер отклонил запрос: ${error.message} (код $code)';
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final page = await context.read<UserRepository>().find(size: 50);
      if (!mounted) return;
      setState(() {
        _users = page.items;
        _status = LoadStatus.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _withCode(e);
        _status = LoadStatus.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить пользователей: $e';
        _status = LoadStatus.error;
      });
    }
  }

  Future<void> _changeRole(AppUser user, Role? role) async {
    if (role == null || role == user.role) return;
    try {
      await context.read<UserRepository>().changeRole(user.id, role);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_withCode(e))),
      );
    }
  }

  Future<void> _delete(AppUser user) async {
    final ok = await confirmDialog(
      context,
      'Удалить пользователя ${user.username}?',
      'Учётная запись будет помечена как удалённая.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<UserRepository>().delete(user.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_withCode(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи и роли'),
        leading: IconButton(
          tooltip: 'На главную',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Раздел доступен только администратору. Роль из '
                            'localStorage рисует интерфейс, но решение о доступе '
                            'принимает сервер по подписанному токену.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: _error ?? 'Ошибка загрузки',
          onRetry: _load,
        );
      case LoadStatus.success:
        if (_users.isEmpty) {
          return const EmptyView(text: 'Пользователей нет.');
        }
        return SingleChildScrollView(
          child: EntityTable<AppUser>(
            items: _users,
            idOf: (user) => user.id,
            columns: [
              TableColumnSpec(label: 'Логин', build: (u) => Text(u.username)),
              TableColumnSpec(label: 'Имя', build: (u) => Text(u.fullName)),
              TableColumnSpec(label: 'Почта', build: (u) => Text(u.email)),
              TableColumnSpec(
                label: 'Роль',
                build: (u) => DropdownButton<Role>(
                  value: u.role,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final role in Role.values)
                      DropdownMenuItem(
                        value: role,
                        child: Text(role.label),
                      ),
                  ],
                  onChanged: (role) => _changeRole(u, role),
                ),
              ),
            ],
            actions: (u) => [
              IconButton(
                tooltip: 'Удалить',
                icon: const Icon(Icons.person_remove_outlined),
                onPressed: () => _delete(u),
              ),
            ],
          ),
        );
    }
  }
}
