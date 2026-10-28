import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/permissions.dart';
import '../../models/order.dart';
import '../../models/order_query.dart';
import '../../repositories/repositories.dart';
import '../../state/auth_notifier.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/state_views.dart';

class OrderListScreen extends StatefulWidget {
  final OrderQuery initialQuery;

  const OrderListScreen({super.key, required this.initialQuery});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late OrderQuery _query;
  late final TextEditingController _searchController;
  List<Order> _orders = const [];
  int _total = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchController = TextEditingController(text: _query.search);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant OrderListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      final next = widget.initialQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _query = next);
        _searchController.text = next.search;
        _load();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<OrderRepository>().find(_query);
      if (!mounted) return;
      setState(() {
        _orders = page.items;
        _total = page.total;
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

  void _go(OrderQuery query) {
    context.go(
      Uri(path: '/orders', queryParameters: query.toParameters()).toString(),
    );
  }

  Future<void> _changeStatus(Order order, OrderStatus status) async {
    final ok = await runApiAction(
      context,
      () => context.read<OrderRepository>().updateStatus(order.id, status),
    );
    if (ok) await _load();
  }

  Future<void> _delete(Order order, {bool hard = false}) async {
    final ok = await runApiAction(
      context,
      () => hard
          ? context.read<OrderRepository>().hardDelete(order.id)
          : context.read<OrderRepository>().softDelete(order.id),
    );
    if (ok) await _load();
  }

  Future<void> _restore(Order order) async {
    final ok = await runApiAction(
      context,
      () => context.read<OrderRepository>().restore(order.id),
    );
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return AppShell(
      title: 'Заказы',
      floatingActionButton: auth.can(Permission.viewOrders)
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/orders/new'),
              icon: const Icon(Icons.add),
              label: const Text('Новый заказ'),
            )
          : null,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _toolbar(auth),
                const SizedBox(height: 12),
                Expanded(child: _body(auth)),
                if (_total > _query.size)
                  PaginationBar(
                    page: _query.page,
                    totalPages: (_total / _query.size).ceil().clamp(1, 9999),
                    total: _total,
                    size: _query.size,
                    onPage: (page) => _go(_query.copyWith(page: page)),
                    onSize: (size) => _go(_query.copyWith(size: size, page: 1)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbar(AuthNotifier auth) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Поиск по покупателю или комментарию',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) => _go(_query.copyWith(search: value)),
          ),
        ),
        DropdownButton<OrderStatus?>(
          value: _query.status,
          hint: const Text('Все статусы'),
          items: [
            const DropdownMenuItem<OrderStatus?>(
              value: null,
              child: Text('Все статусы'),
            ),
            for (final status in OrderStatus.values)
              DropdownMenuItem<OrderStatus?>(
                value: status,
                child: Text(status.label),
              ),
          ],
          onChanged: (value) => _go(_query.copyWith(status: value)),
        ),
        if (auth.can(Permission.restoreRecords))
          FilterChip(
            label: const Text('Показать удалённые'),
            selected: _query.includeDeleted,
            onSelected: (value) => _go(_query.copyWith(includeDeleted: value)),
          ),
        Text('Найдено: $_total'),
      ],
    );
  }

  Widget _body(AuthNotifier auth) {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_orders.isEmpty) {
      return EmptyView(
        text: 'Заказов нет',
        onReset: _query.status == null && _query.search.isEmpty
            ? null
            : () => _go(const OrderQuery()),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return ListView.separated(
            itemCount: _orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _card(_orders[index], auth),
          );
        }
        return SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('№')),
                DataColumn(label: Text('Покупатель')),
                DataColumn(label: Text('Дата')),
                DataColumn(label: Text('Статус')),
                DataColumn(label: Text('Сумма'), numeric: true),
                DataColumn(label: Text('')),
              ],
              rows: [
                for (final order in _orders)
                  DataRow(cells: [
                    DataCell(Text('${order.id}')),
                    DataCell(Text(
                      order.customerName.isEmpty ? '—' : order.customerName,
                    )),
                    DataCell(Text(_date(order.createdAt))),
                    DataCell(_statusChip(order.status)),
                    DataCell(Text('${order.totalPrice.toStringAsFixed(0)} ₽')),
                    DataCell(_actions(order, auth)),
                  ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _card(Order order, AuthNotifier auth) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Заказ №${order.id} • ${order.customerName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _statusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('${_date(order.createdAt)} • ${order.itemsCount} поз.'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.totalPrice.toStringAsFixed(0)} ₽',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _actions(order, auth),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(Order order, AuthNotifier auth) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'open') {
          context.go('/orders/${order.id}');
        } else if (value == 'delete') {
          _delete(order);
        } else if (value == 'hard') {
          _delete(order, hard: true);
        } else if (value == 'restore') {
          _restore(order);
        } else if (value.startsWith('status:')) {
          _changeStatus(
            order,
            OrderStatus.fromApi(value.substring(7)),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'open', child: Text('Открыть')),
        for (final status in OrderStatus.values)
          PopupMenuItem(
            value: 'status:${status.apiName}',
            child: Text('Статус: ${status.label}'),
          ),
        const PopupMenuDivider(),
        if (!order.isDeleted)
          const PopupMenuItem(value: 'delete', child: Text('Удалить')),
        if (order.isDeleted && auth.can(Permission.restoreRecords))
          const PopupMenuItem(value: 'restore', child: Text('Восстановить')),
        if (auth.can(Permission.hardDelete))
          const PopupMenuItem(
            value: 'hard',
            child: Text('Удалить окончательно'),
          ),
      ],
    );
  }

  Widget _statusChip(OrderStatus status) {
    final color = switch (status) {
      OrderStatus.newOrder => Colors.blue,
      OrderStatus.processing => Colors.orange,
      OrderStatus.shipped => Colors.purple,
      OrderStatus.delivered => Colors.green,
      OrderStatus.cancelled => Colors.red,
    };
    return Chip(
      label: Text(status.label),
      labelStyle: TextStyle(color: color.shade800, fontSize: 12),
      backgroundColor: color.shade50,
      side: BorderSide(color: color.shade200),
      visualDensity: VisualDensity.compact,
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year}';
  }
}
