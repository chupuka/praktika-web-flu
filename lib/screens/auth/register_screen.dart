import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/password_policy.dart';
import '../../core/api_exceptions.dart';
import '../../state/auth_notifier.dart';
import '../../validation/validators.dart';

class RegisterScreen extends StatefulWidget {
  final String? from;

  const RegisterScreen({super.key, this.from});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _serverErrors = <String, String>{};
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _clearServerError(String field) {
    if (_serverErrors.remove(field) != null) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
      _serverErrors.clear();
    });
    try {
      await context.read<AuthNotifier>().register(
            username: _username.text.trim(),
            password: _password.text,
            fullName: _fullName.text.trim(),
            email: _email.text.trim(),
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
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverErrors.addAll(e.fieldErrors);
        _error = e.fieldErrors.isEmpty ? e.message : null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Не удалось зарегистрироваться: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final password = _password.text;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
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
                      Text(
                        'Регистрация',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Новый пользователь получает роль «Покупатель».',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _fullName,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Имя и фамилия',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: const OutlineInputBorder(),
                          errorText: _serverErrors['fullName'],
                        ),
                        onChanged: (_) => _clearServerError('fullName'),
                        validator: (value) =>
                            Validators.minLength(value, 'Имя и фамилию', 3),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Почта',
                          prefixIcon: const Icon(Icons.mail_outline),
                          border: const OutlineInputBorder(),
                          errorText: _serverErrors['email'],
                        ),
                        onChanged: (_) => _clearServerError('email'),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _username,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Логин',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: const OutlineInputBorder(),
                          errorText: _serverErrors['username'],
                        ),
                        onChanged: (_) => _clearServerError('username'),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Укажите логин';
                          if (!RegExp(r'^[a-zA-Z0-9._-]{3,32}$').hasMatch(text)) {
                            return 'Логин: 3–32 символа, латиница, цифры, . _ -';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          errorText: _serverErrors['password'],
                        ),
                        onChanged: (_) {
                          _clearServerError('password');
                          setState(() {});
                        },
                        validator: PasswordPolicy.validate,
                      ),
                      const SizedBox(height: 8),
                      for (final rule in PasswordRule.values)
                        _RuleRow(rule: rule, passed: rule.check(password)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirm,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Пароль ещё раз',
                          prefixIcon: Icon(Icons.lock_reset),
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Повторите пароль';
                          }
                          if (value != _password.text) return 'Пароли не совпадают';
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
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
                              : const Text('Зарегистрироваться'),
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
                                      ? '/login'
                                      : '/login?from=${Uri.encodeComponent(from)}',
                                );
                              },
                        child: const Text('Уже есть аккаунт? Войти'),
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

class _RuleRow extends StatelessWidget {
  final PasswordRule rule;
  final bool passed;

  const _RuleRow({required this.rule, required this.passed});

  @override
  Widget build(BuildContext context) {
    final color = passed
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 2),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            rule.label,
            style: TextStyle(color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
