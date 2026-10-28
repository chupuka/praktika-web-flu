import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/order_query.dart';
import '../../repositories/repositories.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/state_views.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Order> _orders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context
          .read<OrderRepository>()
          .find(const OrderQuery(size: 50, sortField: 'createdAt'));
      if (!mounted) return;
      setState(() {
        _orders = page.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить заказы: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Мои заказы',
      child: RefreshIndicator(
        onRefresh: _load,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_orders.isEmpty) {
      return const EmptyView(
        text: 'У вас ещё нет заказов.\nОткройте каталог и оформите заказ.',
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final order = _orders[index];
            return Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                onTap: () => context.go('/my-orders/${order.id}'),
                title: Text('Заказ №${order.id} • ${order.status.label}'),
                subtitle: Text(
                  '${_date(order.createdAt)} • '
                  '${order.deliveryMethod.label} • ${order.itemsCount} поз.',
                ),
                trailing: Text(
                  '${order.totalPrice.toStringAsFixed(0)} ₽',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.${local.year}';
  }
}
