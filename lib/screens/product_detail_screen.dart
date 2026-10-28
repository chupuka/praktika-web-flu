import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../models/role.dart';
import '../repositories/repositories.dart';
import '../state/auth_notifier.dart';
import '../widgets/state_views.dart';

class ProductDetailScreen extends StatefulWidget {
  final int? id;
  const ProductDetailScreen({super.key, required this.id});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  List<Review> _reviews = const [];
  bool _loading = true;
  String? _error;
  int _rating = 5;
  final _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.id == null) {
      setState(() {
        _loading = false;
        _error = 'Товар не найден';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final productRepo = context.read<ProductRepository>();
      final reviewRepo = context.read<ReviewRepository>();
      final product = await productRepo.findById(widget.id!);
      final reviews = await reviewRepo.findByProduct(widget.id!);
      if (!mounted) return;
      setState(() {
        _product = product;
        _reviews = reviews;
        _loading = false;
        if (product == null) _error = 'Товар не найден';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить товар: $e';
        _loading = false;
      });
    }
  }

  Future<void> _addReview(AuthNotifier auth) async {
    final product = _product;
    final customerId = auth.user?.customerId;
    if (product == null || customerId == null) return;
    final text = _reviewController.text.trim();
    if (text.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Напишите текст отзыва')),
      );
      return;
    }
    final ok = await runApiAction(
      context,
      () => context.read<ReviewRepository>().create(
            Review(
              productId: product.id,
              customerId: customerId,
              customerName: auth.user?.fullName ?? '',
              rating: _rating,
              text: text,
            ),
          ),
    );
    if (ok) {
      _reviewController.clear();
      await _load();
    }
  }

  Future<void> _placeOrder(AuthNotifier auth) async {
    final product = _product;
    final customerId = auth.user?.customerId;
    if (product == null || customerId == null) return;
    try {
      final id = await context.read<OrderRepository>().create(
        Order(
          customerId: customerId,
          customerName: auth.user?.fullName ?? '',
          deliveryMethod: DeliveryMethod.delivery,
        ),
        [
          OrderItem(
            productId: product.id,
            productName: product.name,
            quantity: 1,
            price: product.price,
          ),
        ],
      );
      if (!mounted) return;
      context.go('/my-orders/$id');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось оформить заказ: $e')),
      );
    }
  }

  Future<void> _deleteReview(Review review) async {
    final ok = await runApiAction(
      context,
      () => context.read<ReviewRepository>().softDelete(review.id),
    );
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final refs = context.read<ReferenceRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка товара'),
        leading: IconButton(
          tooltip: 'К списку',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _product == null
              ? ErrorView(
                  message: _error ?? 'Товар не найден',
                  onRetry: _load,
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          _product!.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_product!.price.toStringAsFixed(0)} ₽ • '
                          'Остаток: ${_product!.stock}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Категория: ${refs.categoryName(_product!.categoryId)} • '
                          'Производитель: ${refs.manufacturerName(_product!.manufacturerId)}',
                        ),
                        if (_product!.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(_product!.description),
                        ],
                        if (refs
                            .materialNames(_product!.materialIds)
                            .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Материалы: ${refs.materialNames(_product!.materialIds).join(', ')}',
                          ),
                        ],
                        if (_product!.color.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Цвет: ${_product!.color}'),
                        ],
                        if (auth.user?.role == Role.customer) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _product!.stock > 0
                                ? () => _placeOrder(auth)
                                : null,
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Оформить заказ'),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _reviewsSection(auth),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _reviewsSection(AuthNotifier auth) {
    final average = _reviews.isEmpty
        ? 0.0
        : _reviews.fold<int>(0, (sum, r) => sum + r.rating) / _reviews.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Отзывы', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 12),
            if (_reviews.isNotEmpty)
              Chip(
                avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                label: Text(
                  '${average.toStringAsFixed(1)} • ${_reviews.length}',
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_reviews.isEmpty)
          const Text('Отзывов пока нет.')
        else
          for (final review in _reviews)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${review.rating}'),
                ),
                title: Text(review.customerName),
                subtitle: Text(review.text),
                trailing: auth.user?.role == Role.manager ||
                        auth.user?.role == Role.admin
                    ? IconButton(
                        tooltip: 'Удалить отзыв',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteReview(review),
                      )
                    : null,
              ),
            ),
        if (auth.user?.role == Role.customer) ...[
          const SizedBox(height: 12),
          Text('Оставить отзыв',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Оценка:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _rating,
                items: [
                  for (var i = 1; i <= 5; i++)
                    DropdownMenuItem(value: i, child: Text('$i')),
                ],
                onChanged: (value) => setState(() => _rating = value ?? 5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Текст отзыва',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _addReview(auth),
            child: const Text('Отправить отзыв'),
          ),
        ],
      ],
    );
  }
}
