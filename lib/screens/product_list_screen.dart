import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/permissions.dart';
import '../data/seed.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../repositories/repositories.dart';
import '../state/auth_notifier.dart';
import '../state/load_status.dart';
import '../state/product_list_notifier.dart';
import '../widgets/app_shell.dart';
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
    _searchController = TextEditingController(text: widget.initialQuery.search);
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
      context.read<ReferenceRepository>().ensureLoaded();
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
    final refs = context.watch<ReferenceRepository>();
    final auth = context.watch<AuthNotifier>();
    final canManage = auth.can(Permission.manageProducts);
    final isAdmin = auth.can(Permission.hardDelete);
    return AppShell(
      title: 'Каталог товаров',
      actions: [
        if (canManage) ...[
          if (MediaQuery.sizeOf(context).width >= 600)
            FilledButton.icon(
              onPressed: () => context.go('/products/new'),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            )
          else
            IconButton(
              tooltip: 'Добавить товар',
              onPressed: () => context.go('/products/new'),
              icon: const Icon(Icons.add),
            ),
        ] else if (MediaQuery.sizeOf(context).width >= 600)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Chip(
              avatar: Icon(Icons.visibility_outlined, size: 16),
              label: Text('Только просмотр'),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.visibility_outlined),
          ),
      ],
      child: Center(
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
                  showDeleted: canManage,
                  onSearch: (v) => notifier.searchSoon(v),
                  onChanged: _go,
                ),
                const SizedBox(height: 8),
                if (canManage && notifier.hasSelection)
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
                          if (!ok) return;
                          if (!context.mounted) return;
                          await runApiAction(
                            context,
                            notifier.deleteSelected,
                          );
                        },
                        child: const Text('Удалить выбранные'),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildBody(notifier, refs, canManage, isAdmin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    ProductListNotifier notifier,
    ReferenceRepository refs,
    bool canManage,
    bool isAdmin,
  ) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: notifier.error ?? 'Ошибка загрузки',
          onRetry: () {
            context.read<ReferenceRepository>().refresh();
            notifier.load();
          },
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
                canManage: canManage,
                isAdmin: isAdmin,
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
                    onToggleSelect: canManage ? notifier.toggleSelection : null,
                    onSelectAll: !canManage
                        ? null
                        : (v) {
                            if (v ?? false) {
                              notifier.selectAll(result.items.map((p) => p.id));
                            } else {
                              notifier.clearSelection();
                            }
                          },
                    sortField: notifier.query.sortField,
                    sortAscending: notifier.query.sortAscending,
                    onSort: (f) => _onSort(f, notifier.query),
                    actions: (p) =>
                        _rowActions(p, notifier, canManage, isAdmin),
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

  List<Widget> _rowActions(
    Product p,
    ProductListNotifier notifier,
    bool canManage,
    bool isAdmin,
  ) {
    if (p.isDeleted) {
      if (!isAdmin) return const [];
      return [
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore),
          onPressed: () => runApiAction(
            context,
            () => notifier.restore(p.id),
          ),
        ),
        IconButton(
          tooltip: 'Удалить насовсем',
          icon: const Icon(Icons.delete_forever),
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              'Удалить «${p.name}» насовсем?',
            );
            if (!ok || !mounted) return;
            await runApiAction(
              context,
              () => notifier.hardDelete(p.id),
            );
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
      if (canManage) ...[
        IconButton(
          tooltip: 'Изменить',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('/products/${p.id}/edit'),
        ),
        IconButton(
          tooltip: 'Удалить',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => runApiAction(
            context,
            () => notifier.softDelete(p.id),
          ),
        ),
      ],
    ];
  }
}

class _Cards extends StatelessWidget {
  final List<Product> items;
  final ProductListNotifier notifier;
  final ReferenceRepository refs;
  final bool canManage;
  final bool isAdmin;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onSize;

  const _Cards({
    required this.items,
    required this.notifier,
    required this.refs,
    required this.canManage,
    required this.isAdmin,
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
                  leading: canManage
                      ? Checkbox(
                          value: selected,
                          onChanged: (_) => notifier.toggleSelection(p.id),
                        )
                      : null,
                  title: Text(p.name + (p.isDeleted ? ' (удалён)' : '')),
                  subtitle: Text(
                    '${refs.categoryName(p.categoryId)} • '
                    '${p.price.toStringAsFixed(0)} ₽ • Остаток: ${p.stock}',
                  ),
                  trailing: !canManage && !isAdmin
                      ? null
                      : p.isDeleted
                          ? (isAdmin
                              ? IconButton(
                                  tooltip: 'Восстановить',
                                  icon: const Icon(Icons.restore),
                                  onPressed: () => runApiAction(
                                    context,
                                    () => notifier.restore(p.id),
                                  ),
                                )
                              : null)
                          : (canManage
                              ? IconButton(
                                  tooltip: 'Удалить',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => runApiAction(
                                    context,
                                    () => notifier.softDelete(p.id),
                                  ),
                                )
                              : null),
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
  final bool showDeleted;
  final ValueChanged<String> onSearch;
  final ValueChanged<ProductQuery> onChanged;

  const _FilterPanel({
    required this.searchController,
    required this.priceFromController,
    required this.priceToController,
    required this.query,
    required this.showDeleted,
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
                    onChanged: (v) => onChanged(query.copyWith(categoryId: v)),
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
                onSelected: (v) => onChanged(query.copyWith(inStockOnly: v)),
              ),
              if (showDeleted)
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
