import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../repositories/repositories.dart';
import '../state/load_status.dart';
import '../state/product_list_notifier.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entity_table.dart';
import '../widgets/labeled_field.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/state_views.dart';

class ProductListScreen extends StatefulWidget {
  final ProductQuery initialQuery;
  const ProductListScreen({super.key, required this.initialQuery});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _priceFromController;
  late final TextEditingController _priceToController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.initialQuery.search);
    _priceFromController = TextEditingController(
      text: widget.initialQuery.priceFrom?.toInt().toString() ?? '',
    );
    _priceToController = TextEditingController(
      text: widget.initialQuery.priceTo?.toInt().toString() ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ProductListNotifier>()
          .applyQueryIfChanged(widget.initialQuery);
    });
  }

  @override
  void didUpdateWidget(ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      if (_searchController.text != widget.initialQuery.search) {
        _searchController.text = widget.initialQuery.search;
      }
      context
          .read<ProductListNotifier>()
          .applyQueryIfChanged(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _priceFromController.dispose();
    _priceToController.dispose();
    super.dispose();
  }

  void _go(ProductQuery query) {
    context.go(
      Uri(path: '/products', queryParameters: query.toParameters()).toString(),
    );
  }

  void _onSort(String field, ProductQuery query) {
    final same = query.sortField == field;
    _go(query.copyWith(
      sortField: field,
      sortAscending: same ? !query.sortAscending : true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProductListNotifier>();
    final query = notifier.query;
    final refs = context.read<ReferenceRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог товаров'),
        leading: IconButton(
          tooltip: 'На главную',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/products/new'),
            icon: const Icon(Icons.add),
            label: const Text('Добавить'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _FilterPanel(
                  searchController: _searchController,
                  priceFromController: _priceFromController,
                  priceToController: _priceToController,
                  query: query,
                  onSearch: (v) => notifier.searchSoon(v),
                  onChanged: _go,
                ),
                const SizedBox(height: 8),
                if (notifier.hasSelection)
                  Row(
                    children: [
                      Text('Выбрано: ${notifier.selected.length}'),
                      const SizedBox(width: 12),
                      FilledButton.tonal(
                        onPressed: () async {
                          final ok = await confirmDialog(
                            context,
                            'Удалить выбранные товары?',
                            'Записи попадут в удалённые, их можно восстановить.',
                          );
                          if (ok) notifier.deleteSelected();
                        },
                        child: const Text('Удалить выбранные'),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Expanded(child: _buildBody(notifier, refs)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ProductListNotifier notifier, ReferenceRepository refs) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: notifier.error ?? 'Ошибка загрузки',
          onRetry: () => notifier.load(),
        );
      case LoadStatus.success:
        final result = notifier.result;
        if (result.items.isEmpty) {
          return EmptyView(
            text: 'Ничего не найдено. Попробуйте смягчить условия.',
            onReset: () => _go(const ProductQuery()),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return _Cards(
                items: result.items,
                notifier: notifier,
                refs: refs,
                onPage: (p) => _go(notifier.query.copyWith(page: p)),
                onSize: (s) => _go(notifier.query.copyWith(size: s)),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: EntityTable<Product>(
                    items: result.items,
                    idOf: (p) => p.id,
                    selected: notifier.selected,
                    onToggleSelect: notifier.toggleSelection,
                    onSelectAll: (v) {
                      if (v ?? false) {
                        notifier.selectAll(result.items.map((p) => p.id));
                      } else {
                        notifier.clearSelection();
                      }
                    },
                    sortField: notifier.query.sortField,
                    sortAscending: notifier.query.sortAscending,
                    onSort: (f) => _onSort(f, notifier.query),
                    actions: (p) => _rowActions(p, notifier),
                    columns: [
                      TableColumnSpec(
                        label: 'Название',
                        sortField: 'name',
                        build: (p) => InkWell(
                          onTap: () => context.go('/products/${p.id}'),
                          child: Text(
                            p.name + (p.isDeleted ? ' (удалён)' : ''),
                          ),
                        ),
                      ),
                      TableColumnSpec(
                        label: 'Категория',
                        build: (p) => Text(refs.categoryName(p.categoryId)),
                      ),
                      TableColumnSpec(
                        label: 'Цена',
                        sortField: 'price',
                        numeric: true,
                        build: (p) => Text('${p.price.toStringAsFixed(0)} ₽'),
                      ),
                      TableColumnSpec(
                        label: 'Остаток',
                        sortField: 'stock',
                        numeric: true,
                        build: (p) => Text('${p.stock}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                PaginationBar(
                  page: result.page,
                  totalPages: result.totalPages,
                  total: result.total,
                  size: result.size,
                  onPage: (p) => _go(notifier.query.copyWith(page: p)),
                  onSize: (s) => _go(notifier.query.copyWith(size: s)),
                ),
              ],
            );
          },
        );
    }
  }

  List<Widget> _rowActions(Product p, ProductListNotifier notifier) {
    if (p.isDeleted) {
      return [
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore),
          onPressed: () => notifier.restore(p.id),
        ),
        IconButton(
          tooltip: 'Удалить насовсем',
          icon: const Icon(Icons.delete_forever),
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              'Удалить «${p.name}» насовсем?',
            );
            if (ok) notifier.hardDelete(p.id);
          },
        ),
      ];
    }
    return [
      IconButton(
        tooltip: 'Открыть',
        icon: const Icon(Icons.open_in_new),
        onPressed: () => context.go('/products/${p.id}'),
      ),
      IconButton(
        tooltip: 'Изменить',
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => context.go('/products/${p.id}/edit'),
      ),
      IconButton(
        tooltip: 'Удалить',
        icon: const Icon(Icons.delete_outline),
        onPressed: () => notifier.softDelete(p.id),
      ),
    ];
  }
}

class _Cards extends StatelessWidget {
  final List<Product> items;
  final ProductListNotifier notifier;
  final ReferenceRepository refs;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onSize;

  const _Cards({
    required this.items,
    required this.notifier,
    required this.refs,
    required this.onPage,
    required this.onSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final p = items[i];
              final selected = notifier.selected.contains(p.id);
              return Card(
                child: ListTile(
                  leading: Checkbox(
                    value: selected,
                    onChanged: (_) => notifier.toggleSelection(p.id),
                  ),
                  title: Text(p.name + (p.isDeleted ? ' (удалён)' : '')),
                  subtitle: Text(
                    '${refs.categoryName(p.categoryId)} • '
                    '${p.price.toStringAsFixed(0)} ₽ • Остаток: ${p.stock}',
                  ),
                  trailing: p.isDeleted
                      ? IconButton(
                          tooltip: 'Восстановить',
                          icon: const Icon(Icons.restore),
                          onPressed: () => notifier.restore(p.id),
                        )
                      : IconButton(
                          tooltip: 'Удалить',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => notifier.softDelete(p.id),
                        ),
                  onTap: () => context.go('/products/${p.id}'),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        PaginationBar(
          page: notifier.result.page,
          totalPages: notifier.result.totalPages,
          total: notifier.result.total,
          size: notifier.result.size,
          onPage: onPage,
          onSize: onSize,
        ),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final TextEditingController priceFromController;
  final TextEditingController priceToController;
  final ProductQuery query;
  final ValueChanged<String> onSearch;
  final ValueChanged<ProductQuery> onChanged;

  const _FilterPanel({
    required this.searchController,
    required this.priceFromController,
    required this.priceToController,
    required this.query,
    required this.onSearch,
    required this.onChanged,
  });

  double? _parsePrice(String text) {
    final t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  @override
  Widget build(BuildContext context) {
    final refs = context.read<ReferenceRepository>();
    return ExpansionTile(
      title: const Text('Поиск и фильтры'),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: LabeledField(
                  label: 'Поиск',
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Название или описание',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onSearch,
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: LabeledField(
                  label: 'Категория',
                  child: DropdownButtonFormField<int>(
                    value: query.categoryId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        child: Text('Все'),
                      ),
                      for (final c in refs.categories())
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) =>
                        onChanged(query.copyWith(categoryId: v)),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: LabeledField(
                  label: 'Производитель',
                  child: DropdownButtonFormField<int>(
                    value: query.manufacturerId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        child: Text('Все'),
                      ),
                      for (final m in refs.manufacturers())
                        DropdownMenuItem(value: m.id, child: Text(m.name)),
                    ],
                    onChanged: (v) =>
                        onChanged(query.copyWith(manufacturerId: v)),
                  ),
                ),
              ),
              SizedBox(
                width: 140,
                child: LabeledField(
                  label: 'Цена от',
                  child: TextField(
                    controller: priceFromController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (v) =>
                        onChanged(query.copyWith(priceFrom: _parsePrice(v))),
                  ),
                ),
              ),
              SizedBox(
                width: 140,
                child: LabeledField(
                  label: 'Цена до',
                  child: TextField(
                    controller: priceToController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (v) =>
                        onChanged(query.copyWith(priceTo: _parsePrice(v))),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: LabeledField(
                  label: 'Стиль',
                  child: DropdownButtonFormField<String>(
                    value: query.style,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        child: Text('Все'),
                      ),
                      for (final s in seedStyles)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) => onChanged(query.copyWith(style: v)),
                  ),
                ),
              ),
              FilterChip(
                label: const Text('В наличии'),
                selected: query.inStockOnly,
                onSelected: (v) =>
                    onChanged(query.copyWith(inStockOnly: v)),
              ),
              FilterChip(
                label: const Text('Показать удалённые'),
                selected: query.includeDeleted,
                onSelected: (v) =>
                    onChanged(query.copyWith(includeDeleted: v)),
              ),
              TextButton(
                onPressed: () => onChanged(const ProductQuery()),
                child: const Text('Сбросить всё'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
