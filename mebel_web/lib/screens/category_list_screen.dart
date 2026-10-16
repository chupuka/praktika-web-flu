import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/category_query.dart';
import '../state/category_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entity_table.dart';
import '../widgets/labeled_field.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/state_views.dart';

class CategoryListScreen extends StatefulWidget {
  final CategoryQuery initialQuery;
  const CategoryListScreen({super.key, required this.initialQuery});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.initialQuery.search);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<CategoryListNotifier>()
          .applyQueryIfChanged(widget.initialQuery);
    });
  }

  @override
  void didUpdateWidget(CategoryListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      if (_searchController.text != widget.initialQuery.search) {
        _searchController.text = widget.initialQuery.search;
      }
      context
          .read<CategoryListNotifier>()
          .applyQueryIfChanged(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _go(CategoryQuery query) {
    context.go(
      Uri(path: '/categories', queryParameters: query.toParameters())
          .toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CategoryListNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
        leading: IconButton(
          tooltip: 'На главную',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: 'Поиск',
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Название категории',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: notifier.searchSoon,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: const Text('Показать удалённые'),
                      selected: notifier.query.includeDeleted,
                      onSelected: (v) => _go(
                        notifier.query.copyWith(includeDeleted: v),
                      ),
                    ),
                  ],
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
                            'Удалить выбранные категории?',
                            'Записи попадут в удалённые, их можно восстановить.',
                          );
                          if (ok) notifier.deleteSelected();
                        },
                        child: const Text('Удалить выбранные'),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Expanded(child: _buildBody(notifier)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(CategoryListNotifier notifier) {
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
            onReset: () => _go(const CategoryQuery()),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: result.items.length,
                      itemBuilder: (context, i) {
                        final c = result.items[i];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: notifier.selected.contains(c.id),
                              onChanged: (_) =>
                                  notifier.toggleSelection(c.id),
                            ),
                            title: Text(
                              c.name + (c.isDeleted ? ' (удалена)' : ''),
                            ),
                            subtitle: Text(
                              'Товаров: ${notifier.counts[c.id] ?? 0}',
                            ),
                            trailing: c.isDeleted
                                ? IconButton(
                                    tooltip: 'Восстановить',
                                    icon: const Icon(Icons.restore),
                                    onPressed: () =>
                                        notifier.restore(c.id),
                                  )
                                : IconButton(
                                    tooltip: 'Удалить',
                                    icon:
                                        const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        notifier.softDelete(c.id),
                                  ),
                            onTap: () => context.go('/categories/${c.id}'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _pagination(notifier),
                ],
              );
            }
            return Column(
              children: [
                Expanded(
                  child: EntityTable<Category>(
                    items: result.items,
                    idOf: (c) => c.id,
                    selected: notifier.selected,
                    onToggleSelect: notifier.toggleSelection,
                    onSelectAll: (v) {
                      if (v ?? false) {
                        notifier.selectAll(result.items.map((c) => c.id));
                      } else {
                        notifier.clearSelection();
                      }
                    },
                    sortField: notifier.query.sortField,
                    sortAscending: notifier.query.sortAscending,
                    onSort: (f) {
                      final same =
                          notifier.query.sortField == f;
                      _go(notifier.query.copyWith(
                        sortField: f,
                        sortAscending:
                            same ? !notifier.query.sortAscending : true,
                      ));
                    },
                    actions: (c) => _rowActions(c, notifier),
                    columns: [
                      TableColumnSpec(
                        label: 'Название',
                        sortField: 'name',
                        build: (c) => InkWell(
                          onTap: () => context.go('/categories/${c.id}'),
                          child: Text(
                            c.name + (c.isDeleted ? ' (удалена)' : ''),
                          ),
                        ),
                      ),
                      TableColumnSpec(
                        label: 'Товаров',
                        numeric: true,
                        build: (c) =>
                            Text('${notifier.counts[c.id] ?? 0}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _pagination(notifier),
              ],
            );
          },
        );
    }
  }

  PaginationBar _pagination(CategoryListNotifier notifier) {
    final result = notifier.result;
    return PaginationBar(
      page: result.page,
      totalPages: result.totalPages,
      total: result.total,
      size: result.size,
      onPage: (p) => _go(notifier.query.copyWith(page: p)),
      onSize: (s) => _go(notifier.query.copyWith(size: s)),
    );
  }

  List<Widget> _rowActions(Category c, CategoryListNotifier notifier) {
    if (c.isDeleted) {
      return [
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore),
          onPressed: () => notifier.restore(c.id),
        ),
        IconButton(
          tooltip: 'Удалить насовсем',
          icon: const Icon(Icons.delete_forever),
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              'Удалить «${c.name}» насовсем?',
            );
            if (ok) notifier.hardDelete(c.id);
          },
        ),
      ];
    }
    return [
      IconButton(
        tooltip: 'Открыть',
        icon: const Icon(Icons.open_in_new),
        onPressed: () => context.go('/categories/${c.id}'),
      ),
      IconButton(
        tooltip: 'Удалить',
        icon: const Icon(Icons.delete_outline),
        onPressed: () => notifier.softDelete(c.id),
      ),
    ];
  }
}
