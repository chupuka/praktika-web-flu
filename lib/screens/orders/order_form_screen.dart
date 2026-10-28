import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/customer_query.dart';
import '../../models/order.dart';
import '../../models/page_result.dart';
import '../../models/product.dart';
import '../../models/product_query.dart';
import '../../repositories/repositories.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/state_views.dart';

class _DraftItem {
  final Product product;
  int quantity;

  _DraftItem(this.product, this.quantity);

  double get total => product.price * quantity;
}

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _commentController = TextEditingController();
  final _items = <_DraftItem>[];
  List<Customer> _customers = const [];
  List<Product> _products = const [];
  Customer? _customer;
  DeliveryMethod _delivery = DeliveryMethod.pickup;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        context.read<CustomerRepository>().find(const CustomerQuery(size: 100)),
        context.read<ProductRepository>().find(const ProductQuery(size: 100)),
      ]);
      if (!mounted) return;
      setState(() {
        _customers = (results[0] as PageResult<Customer>).items;
        _products = (results[1] as PageResult<Product>).items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить данные: $e';
        _loading = false;
      });
    }
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);

  double get _discountPercent {
    final tier = _customer?.card?.tier;
    return switch (tier) {
      'gold' => 10,
      'silver' => 5,
      _ => 0,
    };
  }

  double get _deliveryCost {
    return switch (_delivery) {
      DeliveryMethod.pickup => 0,
      DeliveryMethod.mail => 490,
      DeliveryMethod.delivery => _subtotal >= 50000 ? 0 : 990,
    };
  }

  double get _total => _subtotal * (1 - _discountPercent / 100) + _deliveryCost;

  Future<void> _addItem() async {
    final available = _products
        .where((p) => !_items.any((item) => item.product.id == p.id))
        .toList();
    if (available.isEmpty) return;
    final product = await showDialog<Product>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите товар'),
        children: [
          for (final product in available)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, product),
              child: Text(
                '${product.name} • ${product.price.toStringAsFixed(0)} ₽',
              ),
            ),
        ],
      ),
    );
    if (product == null) return;
    setState(() => _items.add(_DraftItem(product, 1)));
  }

  Future<void> _save() async {
    if (_customer == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите покупателя и хотя бы один товар'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final order = Order(
        customerId: _customer!.id,
        customerName: _customer!.fullName,
        deliveryMethod: _delivery,
        comment: _commentController.text.trim(),
      );
      final items = [
        for (final item in _items)
          OrderItem(
            productId: item.product.id,
            productName: item.product.name,
            quantity: item.quantity,
            price: item.product.price,
          ),
      ];
      final id = await context.read<OrderRepository>().create(order, items);
      if (!mounted) return;
      context.go('/orders/$id');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось создать заказ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Новый заказ',
      leading: IconButton(
        tooltip: 'К списку',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/orders'),
      ),
      child: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _customerField(),
                          const SizedBox(height: 12),
                          _deliveryField(),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _commentController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Комментарий к заказу',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text(
                                'Позиции',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add),
                                label: const Text('Добавить товар'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_items.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child:
                                    Text('Пока не добавлено ни одного товара'),
                              ),
                            )
                          else
                            Card(
                              margin: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  for (final item in _items)
                                    ListTile(
                                      title: Text(item.product.name),
                                      subtitle: Text(
                                        '${item.product.price.toStringAsFixed(0)} ₽ × ${item.quantity}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: item.quantity > 1
                                                ? () => setState(
                                                      () => item.quantity--,
                                                    )
                                                : null,
                                          ),
                                          Text('${item.quantity}'),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () => setState(
                                              () => item.quantity++,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () => setState(
                                              () => _items.remove(item),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          _summary(),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: const Icon(Icons.check),
                            label: Text(
                              _saving ? 'Сохранение…' : 'Создать заказ',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _customerField() {
    return DropdownButtonFormField<Customer>(
      value: _customer,
      decoration: const InputDecoration(
        labelText: 'Покупатель',
      ),
      items: [
        for (final customer in _customers)
          DropdownMenuItem(
            value: customer,
            child: Text(
              customer.card == null
                  ? customer.fullName
                  : '${customer.fullName} • ${customer.card!.tier}',
            ),
          ),
      ],
      onChanged: (value) => setState(() => _customer = value),
    );
  }

  Widget _deliveryField() {
    return DropdownButtonFormField<DeliveryMethod>(
      value: _delivery,
      decoration: const InputDecoration(labelText: 'Способ получения'),
      items: [
        for (final method in DeliveryMethod.values)
          DropdownMenuItem(value: method, child: Text(method.label)),
      ],
      onChanged: (value) =>
          setState(() => _delivery = value ?? DeliveryMethod.pickup),
    );
  }

  Widget _summary() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Подытог', _subtotal),
            if (_discountPercent > 0)
              _row(
                'Скидка по карте (${_discountPercent.toStringAsFixed(0)}%)',
                -_subtotal * _discountPercent / 100,
              ),
            _row('Доставка', _deliveryCost),
            const Divider(),
            _row('Итого', _total, bold: true),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Итоговую сумму пересчитает сервер: скидка зависит от карты, '
                'доставка — от способа получения и суммы.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
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
}
