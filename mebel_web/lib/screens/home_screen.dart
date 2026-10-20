import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мебельный магазин')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/products'),
                  icon: const Icon(Icons.chair),
                  label: const Text('Каталог товаров'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/categories'),
                  icon: const Icon(Icons.category),
                  label: const Text('Категории'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/manufacturers'),
                  icon: const Icon(Icons.factory),
                  label: const Text('Производители'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/materials'),
                  icon: const Icon(Icons.layers),
                  label: const Text('Материалы'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/customers'),
                  icon: const Icon(Icons.people),
                  label: const Text('Покупатели'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
