import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/manufacturer.dart';
import '../repositories/repositories.dart';
import '../validation/validators.dart';
import '../widgets/entity_form.dart';
import 'entity_form_screen.dart';

class ManufacturerFormScreen extends EntityFormScreen<Manufacturer> {
  const ManufacturerFormScreen({super.key, super.id});

  @override
  State<ManufacturerFormScreen> createState() =>
      _ManufacturerFormScreenState();
}

class _ManufacturerFormScreenState
    extends EntityFormScreenState<Manufacturer, ManufacturerFormScreen> {
  @override
  String get entityTitle => 'производитель';

  @override
  String get returnLocation => '/manufacturers';

  @override
  Future<void> loadData() async {
    controllerFor('name');
    controllerFor('country');
    controllerFor('contactEmail');
  }

  @override
  Future<Manufacturer?> fetchEntity(int id) async {
    final repo = context.read<ManufacturerRepository>();
    final item = await repo.findById(id);
    if (item == null) return null;
    await loadData();
    return item;
  }

  @override
  void fillFrom(Manufacturer entity) {
    controllerFor('name', entity.name);
    controllerFor('country', entity.country);
    controllerFor('contactEmail', entity.contactEmail);
  }

  @override
  List<FieldSpec> buildFields() {
    return [
      FieldSpec(
        key: 'name',
        label: 'Название',
        maxLength: 80,
        validate: (v) => Validators.minLength(v, 'название', 2),
      ),
      FieldSpec(
        key: 'country',
        label: 'Страна',
        maxLength: 40,
        validate: (v) => Validators.minLength(v, 'страну', 2),
      ),
      FieldSpec(
        key: 'contactEmail',
        label: 'Почта для связи',
        required: false,
        maxLength: 60,
        validate: (v) =>
            (v == null || v.trim().isEmpty) ? null : Validators.email(v),
      ),
    ];
  }

  @override
  Future<bool> saveEntity() async {
    final repo = context.read<ManufacturerRepository>();
    final name = controllers['name']!.text.trim();

    final duplicate = await repo.findByName(name, exceptId: widget.id);
    if (duplicate != null) {
      setState(() {
        fieldErrors['name'] = 'Производитель «$name» уже добавлен';
      });
      return false;
    }

    final item = Manufacturer(
      id: widget.id ?? 0,
      name: name,
      country: controllers['country']!.text.trim(),
      contactEmail: controllers['contactEmail']!.text.trim(),
    );

    if (widget.isEditing) {
      await repo.update(item);
    } else {
      await repo.create(item);
    }
    return true;
  }
}
