import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../repositories/repositories.dart';
import '../widgets/state_views.dart';

class ProductDetailScreen extends StatefulWidget {
  final int? id;
  const ProductDetailScreen({super.key, required this.id});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final Future<Product?> _future;

  @override
  void initState() {
    super.initState();
    final repo = context.read<ProductRepository>();
    _future =
        widget.id == null ? Future.value(null) : repo.findById(widget.id!);
  }

  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder<Product?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final product = snapshot.data;
          if (product == null) {
            return ErrorView(
              message: 'Товар не найден',
              onRetry: () => context.go('/products'),
            );
          }
          final materials = refs.materialNames(product.materialIds).join(', ');
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${product.price.toStringAsFixed(0)} ₽ • Остаток: ${product.stock}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Категория: ${refs.categoryName(product.categoryId)} • '
                      'Производитель: ${refs.manufacturerName(product.manufacturerId)}',
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(product.description),
                    ],
                    if (materials.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Материалы: $materials'),
                    ],
                    if (product.color.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Цвет: ${product.color}'),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
