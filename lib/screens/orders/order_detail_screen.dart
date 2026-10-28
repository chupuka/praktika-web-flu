import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/permissions.dart';
import '../../models/order.dart';
import '../../repositories/repositories.dart';
import '../../state/auth_notifier.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/state_views.dart';

class OrderDetailScreen extends StatefulWidget {
  final int? id;
  final bool mine;

  const OrderDetailScreen({super.key, required this.id, this.mine = false});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.id == null) {
      setState(() {
        _loading = false;
        _error = 'Заказ не найден';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await context.read<OrderRepository>().findById(widget.id!);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
        if (order == null) _error = 'Заказ не найден';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить заказ: $e';
        _loading = false;
      });
    }
  }

  Future<void> _changeStatus(OrderStatus status) async {
    final order = _order;
    if (order == null) return;
    final ok = await runApiAction(
      context,
      () => context.read<OrderRepository>().updateStatus(order.id, status),
    );
    if (ok) await _load();
  }

  Future<void> _delete() async {
    final order = _order;
    if (order == null) return;
    final ok = await runApiAction(
      context,
      () => context.read<OrderRepository>().softDelete(order.id),
    );
    if (ok && mounted) {
      context.go(widget.mine ? '/my-orders' : '/orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return AppShell(
      title: _order == null ? 'Заказ' : 'Заказ №${_order!.id}',
      leading: IconButton(
        tooltip: 'Назад',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(widget.mine ? '/my-orders' : '/orders'),
      ),
      actions: [
        if (_order != null && auth.can(Permission.viewOrders))
          PopupMenuButton<OrderStatus>(
            tooltip: 'Изменить статус',
            icon: const Icon(Icons.published_with_changes),
            onSelected: _changeStatus,
            itemBuilder: (context) => [
              for (final status in OrderStatus.values)
                PopupMenuItem(value: status, child: Text(status.label)),
            ],
          ),
        if (_order != null && auth.can(Permission.viewOrders))
          IconButton(
            tooltip: 'Удалить заказ',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
      ],
      child: _buildBody(auth),
    );
  }

  Widget _buildBody(AuthNotifier auth) {
    if (_loading) return const LoadingView();
    if (_error != null || _order == null) {
      return ErrorView(message: _error ?? 'Заказ не найден', onRetry: _load);
    }
    final order = _order!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    order.customerName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Chip(label: Text(order.status.label)),
                  Chip(label: Text(order.deliveryMethod.label)),
                  if (order.isDeleted)
                    const Chip(
                      label: Text('Удалён'),
                      backgroundColor: Color(0xFFFFDAD6),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Оформлен: ${_dateTime(order.createdAt)}'),
              if (order.comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Комментарий: ${order.comment}'),
              ],
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (final item in order.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.productName} × ${item.quantity}',
                                ),
                              ),
                              Text('${item.total.toStringAsFixed(0)} ₽'),
                            ],
                          ),
                        ),
                      const Divider(),
                      _totalRow('Подытог', order.subtotal),
                      if (order.discountPercent > 0)
                        _totalRow(
                          'Скидка по карте (${order.discountPercent.toStringAsFixed(0)}%)',
                          -order.subtotal * order.discountPercent / 100,
                        ),
                      _totalRow('Доставка', order.deliveryCost),
                      const SizedBox(height: 6),
                      _totalRow('Итого', order.totalPrice, bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Скидка и доставка рассчитаны на сервере по правилам магазина.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    final style = bold
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('${value.toStringAsFixed(0)} ₽', style: style),
        ],
      ),
    );
  }

  String _dateTime(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year} ${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
