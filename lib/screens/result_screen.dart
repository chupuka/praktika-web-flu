import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/calculator.dart';
import '../logic/currency.dart';

class CalcResultScreen extends StatelessWidget {
  final Map<String, String> query;
  const CalcResultScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final result = calculate(query['a'], query['op'], query['b']);
    final expression = '${query['a'] ?? '?'} ${query['op'] ?? '?'} '
        '${query['b'] ?? '?'}';

    return Scaffold(
      appBar: AppBar(title: const Text('Результат вычисления')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(expression, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                switch (result) {
                  CalcSuccess(value: final v) => Text(
                      '= ${formatNumber(v)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  CalcFailure(message: final m) => Text(
                      'Ошибка: $m',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                },
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => context.go('/calculator'),
                  child: const Text('Назад к форме'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ConverterResultScreen extends StatelessWidget {
  final Map<String, String> query;
  const ConverterResultScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final result = convert(query['amount'], query['from'], query['to']);
    final expression =
        '${query['amount'] ?? '?'} ${query['from'] ?? '?'} → ${query['to'] ?? '?'}';

    return Scaffold(
      appBar: AppBar(title: const Text('Результат конвертации')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(expression, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                switch (result) {
                  ConvertSuccess(value: final v) => Text(
                      '= ${formatNumber(v)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ConvertFailure(message: final m) => Text(
                      'Ошибка: $m',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                },
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => context.go('/converter'),
                  child: const Text('Назад к форме'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
