import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../repositories/repositories.dart';
import '../state/auth_notifier.dart';
import '../widgets/state_views.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<Customer?> _future;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthNotifier>();
    final customerId = auth.user?.customerId;
    _future = customerId == null
        ? Future.value(null)
        : context.read<CustomerRepository>().findById(customerId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя карточка'),
        leading: IconButton(
          tooltip: 'На главную',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: FutureBuilder<Customer?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: 'Не удалось загрузить профиль: ${snapshot.error}',
              onRetry: () => context.go('/profile'),
            );
          }
          final customer = snapshot.data;
          if (customer == null) {
            return const EmptyView(
              text: 'К учётной записи не привязана карточка покупателя.',
            );
          }
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.fullName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(auth.user?.email ?? customer.email),
                        const Divider(height: 32),
                        _Row(label: 'Телефон', value: customer.phone),
                        _Row(label: 'Адрес', value: customer.address),
                        _Row(
                          label: 'Логин',
                          value: auth.user?.username ?? '—',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Бонусная карта',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (customer.card == null)
                          const Text('Карта не выпущена')
                        else ...[
                          _Row(
                            label: 'Номер',
                            value: customer.card!.number,
                          ),
                          _Row(
                            label: 'Уровень',
                            value: customer.card!.tier,
                          ),
                          _Row(
                            label: 'Баллы',
                            value: '${customer.card!.points}',
                          ),
                          _Row(
                            label: 'Выдана',
                            value: customer.card!.issuedAt,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          'Этот экран доступен только роли «Покупатель». '
                          'Менеджер и администратор увидят отказ.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}
