import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../repositories/repositories.dart';
import '../widgets/state_views.dart';

class CategoryDetailScreen extends StatefulWidget {
  final int? id;
  const CategoryDetailScreen({super.key, required this.id});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late final Future<Category?> _future;

  @override
  void initState() {
    super.initState();
    final repo = context.read<CategoryRepository>();
    _future =
        widget.id == null ? Future.value(null) : repo.findById(widget.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка категории'),
        leading: IconButton(
          tooltip: 'К списку',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/categories'),
        ),
      ),
      body: FutureBuilder<Category?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final category = snapshot.data;
          if (category == null) {
            return ErrorView(
              message: 'Категория не найдена',
              onRetry: () => context.go('/categories'),
            );
          }
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
                      category.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (category.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(category.description),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => context.go(
                        Uri(
                          path: '/products',
                          queryParameters: {'categoryId': '${category.id}'},
                        ).toString(),
                      ),
                      child: const Text('Показать товары'),
                    ),
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
