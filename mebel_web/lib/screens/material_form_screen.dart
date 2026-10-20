import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/material.dart';
import '../repositories/repositories.dart';
import '../validation/validators.dart';
import '../widgets/entity_form.dart';
import 'entity_form_screen.dart';

class MaterialFormScreen extends EntityFormScreen<FurnitureMaterial> {
  const MaterialFormScreen({super.key, super.id});

  @override
  State<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState
    extends EntityFormScreenState<FurnitureMaterial, MaterialFormScreen> {
  @override
  String get entityTitle => 'материал';

  @override
  String get returnLocation => '/materials';

  @override
  Future<void> loadData() async {
    controllerFor('name');
    controllerFor('description');
  }

  @override
  Future<FurnitureMaterial?> fetchEntity(int id) async {
    final repo = context.read<MaterialRepository>();
    final item = await repo.findById(id);
    if (item == null) return null;
    await loadData();
    return item;
  }

  @override
  void fillFrom(FurnitureMaterial entity) {
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
        validate: (v) => Validators.minLength(v, 'название', 2),
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
    final repo = context.read<MaterialRepository>();
    final name = controllers['name']!.text.trim();

    final duplicate = await repo.findByName(name, exceptId: widget.id);
    if (duplicate != null) {
      setState(() {
        fieldErrors['name'] = 'Материал «$name» уже существует';
      });
      return false;
    }

    final item = FurnitureMaterial(
      id: widget.id ?? 0,
      name: name,
      description: controllers['description']!.text.trim(),
    );

    if (widget.isEditing) {
      await repo.update(item);
    } else {
      await repo.create(item);
    }
    return true;
  }
}
