import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/page_result.dart';
import '../repositories/repositories.dart';
import '../state/load_status.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entity_table.dart';
import '../widgets/labeled_field.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/state_views.dart';

class ColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item, BuildContext context) build;

  const ColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityListScreen<T> extends StatefulWidget {
  final String title;
  final String basePath;
  final String createLabel;
  final List<ColumnSpec<T>> columns;
  final Future<PageResult<T>> Function(String search, String sortField,
      bool sortAscending, int page, int size, bool includeDeleted) load;
  final Future<void> Function(int id, bool hard) delete;
  final Future<void> Function(int id) restore;
  final Future<int> Function(List<int> ids) deleteMany;
  final Future<int?> Function(T item) countReferences;
  final int Function(T item) idOf;
  final bool Function(T item) isDeleted;
  final String searchHint;
  final List<String> sortFields;
  final String defaultSortField;

  const EntityListScreen({
    super.key,
    required this.title,
    required this.basePath,
    required this.createLabel,
    required this.columns,
    required this.load,
    required this.delete,
    required this.restore,
    required this.deleteMany,
    required this.countReferences,
    required this.idOf,
    required this.isDeleted,
    required this.searchHint,
    this.sortFields = const [],
    this.defaultSortField = 'name',
  });

  @override
  State<EntityListScreen<T>> createState() => _EntityListScreenState<T>();
}

class _EntityListScreenState<T> extends State<EntityListScreen<T>> {
  final _searchController = TextEditingController();
  final _selected = <int>{};

  PageResult<T>? _result;
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  String _search = '';
  String _sortField = 'name';
  bool _ascending = true;
  int _page = 1;
  int _size = 10;
  bool _includeDeleted = false;

  @override
  void initState() {
    super.initState();
    _sortField = widget.defaultSortField;
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReferenceRepository>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final result = await widget.load(
        _search,
        _sortField,
        _ascending,
        _page,
        _size,
        _includeDeleted,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _status = LoadStatus.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить список: $e';
        _status = LoadStatus.error;
      });
    }
  }

  void _setSort(String field) {
    setState(() {
      if (_sortField == field) {
        _ascending = !_ascending;
      } else {
        _sortField = field;
        _ascending = true;
      }
      _page = 1;
    });
    _reload();
  }

  Future<void> _tryDelete(T item) async {
    final references = await widget.countReferences(item) ?? 0;
    if (references > 0) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удаление невозможно'),
          content: Text(
            'К записи привязано связанных товаров: $references. '
            'Сначала измените или удалите их.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    final ok = await confirmDialog(
      context,
      'Удалить запись?',
      'Запись можно будет восстановить.',
    );
    if (!ok || !mounted) return;
    await runApiAction(context, () async {
      await widget.delete(widget.idOf(item), false);
      await _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          tooltip: 'На главную',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('${widget.basePath}/new'),
            icon: const Icon(Icons.add),
            label: Text(widget.createLabel),
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
                _buildFilterBar(),
                const SizedBox(height: 8),
                if (_selected.isNotEmpty) _buildSelectionBar(),
                const SizedBox(height: 8),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: 260,
          child: LabeledField(
            label: 'Поиск',
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                setState(() {
                  _search = value;
                  _page = 1;
                });
                _reload();
              },
            ),
          ),
        ),
        FilterChip(
          label: const Text('Показать удалённые'),
          selected: _includeDeleted,
          onSelected: (value) {
            setState(() {
              _includeDeleted = value;
              _page = 1;
            });
            _reload();
          },
        ),
        TextButton(
          onPressed: () {
            _searchController.clear();
            setState(() {
              _search = '';
              _page = 1;
              _sortField = widget.defaultSortField;
              _ascending = true;
            });
            _reload();
          },
          child: const Text('Сбросить'),
        ),
      ],
    );
  }

  Widget _buildSelectionBar() {
    return Row(
      children: [
        Text('Выбрано: ${_selected.length}'),
        const SizedBox(width: 12),
        FilledButton.tonal(
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              'Удалить выбранные записи?',
              'Записи можно будет восстановить.',
            );
            if (!ok || !mounted) return;
            final ids = _selected.toList();
            await runApiAction(context, () async {
              setState(() => _selected.clear());
              await widget.deleteMany(ids);
              await _reload();
            });
          },
          child: const Text('Удалить выбранные'),
        ),
      ],
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
          onRetry: _reload,
        );
      case LoadStatus.success:
        final result = _result;
        if (result == null || result.items.isEmpty) {
          return EmptyView(
            text: 'Записей нет. Измените условия поиска.',
            onReset: () {
              _searchController.clear();
              setState(() {
                _search = '';
                _page = 1;
              });
              _reload();
            },
          );
        }
        return Column(
          children: [
            Expanded(
              child: EntityTable<T>(
                items: result.items,
                idOf: widget.idOf,
                selected: _selected,
                onToggleSelect: (id) {
                  setState(() {
                    _selected.contains(id)
                        ? _selected.remove(id)
                        : _selected.add(id);
                  });
                },
                onSelectAll: (value) {
                  setState(() {
                    if (value ?? false) {
                      _selected.addAll(result.items.map(widget.idOf));
                    } else {
                      _selected.clear();
                    }
                  });
                },
                sortField: _sortField,
                sortAscending: _ascending,
                onSort: _setSort,
                actions: (item) => _rowActions(item),
                columns: [
                  for (final column in widget.columns)
                    TableColumnSpec<T>(
                      label: column.label,
                      sortField: column.sortField,
                      numeric: column.numeric,
                      build: (item) => column.build(item, context),
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
              onPage: (page) {
                setState(() => _page = page);
                _reload();
              },
              onSize: (size) {
                setState(() {
                  _size = size;
                  _page = 1;
                });
                _reload();
              },
            ),
          ],
        );
    }
  }

  List<Widget> _rowActions(T item) {
    final id = widget.idOf(item);
    if (widget.isDeleted(item)) {
      return [
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore),
          onPressed: () => runApiAction(context, () async {
            await widget.restore(id);
            await _reload();
          }),
        ),
        IconButton(
          tooltip: 'Удалить насовсем',
          icon: const Icon(Icons.delete_forever),
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              'Удалить запись насовсем?',
              'Восстановить её будет нельзя.',
            );
            if (!ok || !mounted) return;
            await runApiAction(context, () async {
              await widget.delete(id, true);
              await _reload();
            });
          },
        ),
      ];
    }
    return [
      IconButton(
        tooltip: 'Изменить',
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => context.go('${widget.basePath}/$id/edit'),
      ),
      IconButton(
        tooltip: 'Удалить',
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _tryDelete(item),
      ),
    ];
  }
}
