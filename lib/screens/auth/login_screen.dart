import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_config.dart';
import '../../core/api_exceptions.dart';
import '../../state/auth_notifier.dart';

class LoginScreen extends StatefulWidget {
  final String? from;
  final String? reason;

  const LoginScreen({super.key, this.from, this.reason});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _idleText {
    final seconds = AuthConfig.idleTimeout.inSeconds;
    if (seconds >= 60 && seconds % 60 == 0) return '${seconds ~/ 60} мин';
    return '$seconds с';
  }

  String? get _reasonText {
    return switch (widget.reason) {
      'idle' => 'Сессия завершена: $_idleText без действий.',
      'absolute' => 'Сессия завершена: истёк максимальный срок работы.',
      'expired' => 'Сессия истекла. Войдите снова.',
      _ => null,
    };
  }

  void _fill(String username, String password) {
    setState(() {
      _username.text = username;
      _password.text = password;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthNotifier>().login(
            _username.text.trim(),
            _password.text,
          );
      if (!mounted) return;
      final from = widget.from;
      final target = from != null &&
              from.startsWith('/') &&
              !from.startsWith('/login') &&
              !from.startsWith('/register')
          ? from
          : '/';
      context.go(target);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Не удалось войти: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.chair_outlined,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Мебельный магазин',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Вход в систему',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (_reasonText != null) ...[
                        const SizedBox(height: 16),
                        _MessageBox(
                          text: _reasonText!,
                          icon: Icons.timer_off_outlined,
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _username,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Логин',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Укажите логин'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Укажите пароль'
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _MessageBox(text: _error!, icon: Icons.error_outline),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Войти'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () {
                                final from = widget.from;
                                context.go(
                                  from == null
                                      ? '/register'
                                      : '/register?from=${Uri.encodeComponent(from)}',
                                );
                              },
                        child: const Text('Нет аккаунта? Зарегистрироваться'),
                      ),
                      const Divider(height: 32),
                      Text(
                        'Учётные записи для проверки',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('Покупатель'),
                            onPressed: () =>
                                _fill('customer', 'customer123'),
                          ),
                          ActionChip(
                            label: const Text('Менеджер'),
                            onPressed: () => _fill('manager', 'manager123'),
                          ),
                          ActionChip(
                            label: const Text('Администратор'),
                            onPressed: () => _fill('admin', 'admin123'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String text;
  final IconData icon;

  const _MessageBox({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
