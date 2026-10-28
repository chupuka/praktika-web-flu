import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/stats.dart';
import '../../repositories/repositories.dart';
import '../../state/load_status.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/state_views.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  ShopStats _stats = const ShopStats();
  List<CategoryStat> _categories = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final repo = context.read<StatsRepository>();
      final results = await Future.wait<Object>([
        repo.shop(),
        repo.categories(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as ShopStats;
        _categories = results[1] as List<CategoryStat>;
        _status = LoadStatus.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить статистику: $e';
        _status = LoadStatus.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Статистика',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: _error ?? 'Ошибка загрузки',
          onRetry: _load,
        );
      case LoadStatus.success:
        return ListView(
          children: [
            Text(
              'Сводка по магазину',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Показатели считаются на сервере по таблицам базы данных.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _cards(),
            const SizedBox(height: 28),
            Text(
              'Распределение товаров по категориям',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _chart(),
          ],
        );
    }
  }

  Widget _cards() {
    final items = <({String label, String value, IconData icon})>[
      (
        label: 'Выручка',
        value: '${_stats.revenue.toStringAsFixed(0)} ₽',
        icon: Icons.payments_outlined
      ),
      (
        label: 'Заказы',
        value: '${_stats.orders}',
        icon: Icons.receipt_long_outlined
      ),
      (
        label: 'Стоимость склада',
        value: '${_stats.stockValue.toStringAsFixed(0)} ₽',
        icon: Icons.warehouse_outlined
      ),
      (
        label: 'Товары',
        value: '${_stats.products}',
        icon: Icons.chair_outlined
      ),
      (
        label: 'Средняя цена',
        value: '${_stats.avgPrice.toStringAsFixed(0)} ₽',
        icon: Icons.sell_outlined
      ),
      (
        label: 'Средний рейтинг',
        value: _stats.avgRating.toStringAsFixed(1),
        icon: Icons.star_outline
      ),
      (
        label: 'Нет в наличии',
        value: '${_stats.outOfStock}',
        icon: Icons.remove_shopping_cart_outlined
      ),
      (
        label: 'Мало на складе',
        value: '${_stats.lowStock}',
        icon: Icons.inventory_2_outlined
      ),
      (
        label: 'Покупатели',
        value: '${_stats.customers}',
        icon: Icons.people_outline
      ),
      (
        label: 'Пользователи',
        value: '${_stats.users}',
        icon: Icons.person_outline
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.value,
                                style: Theme.of(context).textTheme.titleLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _chart() {
    if (_categories.isEmpty) {
      return const Text('Нет данных по категориям');
    }
    final maxCount =
        _categories.map((c) => c.productCount).reduce((a, b) => a > b ? a : b);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final category in _categories)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 190,
                      child: Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final ratio = maxCount == 0
                              ? 0.0
                              : category.productCount / maxCount;
                          return Stack(
                            children: [
                              Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              Container(
                                height: 20,
                                width: constraints.maxWidth * ratio,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${category.productCount}',
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
