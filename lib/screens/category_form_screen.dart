import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../repositories/repositories.dart';
import '../validation/validators.dart';
import '../widgets/entity_form.dart';
import 'entity_form_screen.dart';

class CategoryFormScreen extends EntityFormScreen<Category> {
  const CategoryFormScreen({super.key, super.id});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState
    extends EntityFormScreenState<Category, CategoryFormScreen> {
  @override
  String get entityTitle => 'категория';

  @override
  String get returnLocation => '/categories';

  @override
  Future<void> loadData() async {
    controllerFor('name');
    controllerFor('description');
  }

  @override
  Future<Category?> fetchEntity(int id) async {
    final repo = context.read<CategoryRepository>();
    final category = await repo.findById(id);
    if (category == null) return null;
    await loadData();
    return category;
  }

  @override
  void fillFrom(Category entity) {
    controllerFor('name', entity.name);
    controllerFor('description', entity.description);
  }

  @override
  List<FieldSpec> buildFields() {
    return [
      FieldSpec(
        key: 'name',
        label: 'Название',
        maxLength: 60,
        validate: (v) => Validators.minLength(v, 'название', 3),
      ),
      FieldSpec(
        key: 'description',
        label: 'Описание',
        required: false,
        maxLength: 200,
        validate: (v) => Validators.maxLength(v, 'описание', 200),
      ),
    ];
  }

  @override
  Future<bool> saveEntity() async {
    final repo = context.read<CategoryRepository>();
    final name = controllers['name']!.text.trim();

    final category = Category(
      id: widget.id ?? 0,
      name: name,
      description: controllers['description']!.text.trim(),
    );

    if (widget.isEditing) {
      await repo.update(category);
    } else {
      await repo.create(category);
    }
    return true;
  }
}
