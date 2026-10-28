import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../state/category_list_notifier.dart';
import '../state/product_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/state_views.dart';

abstract class EntityFormScreen<T> extends StatefulWidget {
  final int? id;
  const EntityFormScreen({super.key, this.id});

  bool get isEditing => id != null;
}

abstract class EntityFormScreenState<T, W extends EntityFormScreen<T>>
    extends State<W> {
  final formKey = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final dropdownValues = <String, int?>{};
  final multiValues = <String, List<int>>{};
  final groupControllers = <String, Map<String, TextEditingController>>{};
  final fieldErrors = <String, String>{};

  bool _dirty = false;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  String get entityTitle;
  List<FieldSpec> buildFields();
  Future<void> loadData();
  Future<bool> saveEntity();
  Future<T?> fetchEntity(int id);
  void fillFrom(T entity);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (widget.isEditing) {
        final entity = await fetchEntity(widget.id!);
        if (entity == null) {
          setState(() {
            _error = 'Запись не найдена';
            _loading = false;
          });
          return;
        }
        fillFrom(entity);
      } else {
        await loadData();
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить данные: $e';
        _loading = false;
      });
    }
  }

  TextEditingController controllerFor(String key, [String text = '']) {
    return controllers.putIfAbsent(
        key, () => TextEditingController(text: text));
  }

  Map<String, TextEditingController> groupFor(
    String groupKey,
    Map<String, String> values,
  ) {
    return groupControllers.putIfAbsent(
      groupKey,
      () => {
        for (final entry in values.entries)
          entry.key: TextEditingController(text: entry.value),
      },
    );
  }

  void markDirty() {
    if (!_dirty) _dirty = true;
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    for (final group in groupControllers.values) {
      for (final c in group.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Есть несохранённые изменения'),
        content: const Text(
          'Если выйти сейчас, введённые данные будут потеряны.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submit() async {
    fieldErrors.clear();
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final applied = await saveEntity();
      if (!applied) {
        if (!mounted) return;
        setState(() {
          _saving = false;
        });
        formKey.currentState?.validate();
        return;
      }
      _dirty = false;
      if (!mounted) return;
      await _refreshList();
      if (!mounted) return;
      context.go(returnLocation);
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        fieldErrors.addAll(e.fieldErrors);
      });
      formKey.currentState?.validate();
    } on ConflictException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить: $e')),
      );
    }
  }

  String get returnLocation;

  Future<void> _refreshList() async {
    final target = returnLocation;
    try {
      if (target.startsWith('/categories')) {
        await context.read<CategoryListNotifier>().refresh();
      } else if (target.startsWith('/products')) {
        await context.read<ProductListNotifier>().refresh();
      }
    } catch (_) {
      // Список перечитается при следующем открытии.
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmLeave();
        if (leave && context.mounted) {
          context.go(returnLocation);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing
              ? 'Изменение: $entityTitle'
              : 'Новая запись: $entityTitle'),
          leading: IconButton(
            tooltip: 'Назад',
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final leave = await _confirmLeave();
              if (leave && context.mounted) {
                context.go(returnLocation);
              }
            },
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: () => context.go(returnLocation),
      );
    }
    return Column(
      children: [
        Expanded(
          child: EntityForm(
            formKey: formKey,
            fields: buildFields(),
            controllers: controllers,
            dropdownValues: dropdownValues,
            multiValues: multiValues,
            groupControllers: groupControllers,
            onDropdownChanged: (key, value) {
              setState(() => dropdownValues[key] = value);
            },
            onMultiChanged: (key, value) {
              setState(() => multiValues[key] = value);
            },
            fieldErrors: fieldErrors,
            onDirty: markDirty,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          final leave = await _confirmLeave();
                          if (leave && mounted) {
                            context.go(returnLocation);
                          }
                        },
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isEditing ? 'Сохранить' : 'Создать'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
