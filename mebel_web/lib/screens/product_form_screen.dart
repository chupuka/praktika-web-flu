import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/seed.dart';
import '../models/category.dart';
import '../models/manufacturer.dart';
import '../models/material.dart';
import '../models/product.dart';
import '../repositories/repositories.dart';
import '../validation/validators.dart';
import '../widgets/entity_form.dart';
import 'entity_form_screen.dart';

class ProductFormScreen extends EntityFormScreen<Product> {
  const ProductFormScreen({super.key, super.id});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState
    extends EntityFormScreenState<Product, ProductFormScreen> {
  List<Category> _categories = const [];
  List<Manufacturer> _manufacturers = const [];
  List<FurnitureMaterial> _materials = const [];

  @override
  String get entityTitle => 'товар';

  @override
  String get returnLocation => '/products';

  @override
  Future<void> loadData() async {
    final refs = context.read<ReferenceRepository>();
    _categories = refs.categories();
    _manufacturers = refs.manufacturers();
    _materials = refs.materials();
    controllerFor('name');
    controllerFor('sku');
    controllerFor('description');
    controllerFor('price');
    controllerFor('stock');
    controllerFor('width');
    controllerFor('depth');
    controllerFor('height');
    controllerFor('weight');
    controllerFor('color');
  }

  @override
  Future<Product?> fetchEntity(int id) async {
    final repo = context.read<ProductRepository>();
    final product = await repo.findById(id);
    if (product == null) return null;
    await loadData();
    return product;
  }

  @override
  void fillFrom(Product entity) {
    controllerFor('name', entity.name);
    controllerFor('sku', entity.sku);
    controllerFor('description', entity.description);
    controllerFor('price', entity.price.toStringAsFixed(0));
    controllerFor('stock', entity.stock.toString());
    controllerFor('width', entity.width?.toStringAsFixed(0) ?? '');
    controllerFor('depth', entity.depth?.toStringAsFixed(0) ?? '');
    controllerFor('height', entity.height?.toStringAsFixed(0) ?? '');
    controllerFor('weight', entity.weight?.toStringAsFixed(0) ?? '');
    controllerFor('color', entity.color);
    dropdownValues['categoryId'] = entity.categoryId;
    dropdownValues['manufacturerId'] = entity.manufacturerId;
    dropdownValues['style'] = entity.style.isEmpty
        ? null
        : seedStyles.indexOf(entity.style) + 1;
    multiValues['materialIds'] = [...entity.materialIds];
  }

  @override
  List<FieldSpec> buildFields() {
    return [
      FieldSpec(
        key: 'name',
        label: 'Название',
        maxLength: 120,
        validate: (v) => Validators.minLength(v, 'название', 3),
      ),
      FieldSpec(
        key: 'sku',
        label: 'Артикул',
        hint: 'Например, MB-101',
        maxLength: 20,
        validate: (v) {
          final base = Validators.required(v, 'артикул');
          if (base != null) return base;
          final text = v!.trim();
          if (text.length < 4) return 'Артикул: минимум 4 символа';
          if (!RegExp(r'^[A-Za-zА-Яа-я0-9-]+$').hasMatch(text)) {
            return 'Артикул: только буквы, цифры и дефис';
          }
          return null;
        },
      ),
      FieldSpec(
        key: 'description',
        label: 'Описание',
        required: false,
        maxLength: 400,
        validate: (v) => Validators.maxLength(v, 'описание', 400),
      ),
      FieldSpec(
        key: 'categoryId',
        label: 'Категория',
        kind: FieldKind.dropdown,
        options: [
          for (final c in _categories)
            DropdownOption(value: c.id, label: c.name),
        ],
      ),
      FieldSpec(
        key: 'manufacturerId',
        label: 'Производитель',
        kind: FieldKind.dropdown,
        options: [
          for (final m in _manufacturers)
            DropdownOption(value: m.id, label: m.name),
        ],
      ),
      FieldSpec(
        key: 'materialIds',
        label: 'Материалы',
        kind: FieldKind.multiSelect,
        options: [
          for (final m in _materials)
            DropdownOption(value: m.id, label: m.name),
        ],
      ),
      FieldSpec(
        key: 'style',
        label: 'Стиль',
        kind: FieldKind.dropdown,
        required: false,
        options: [
          for (var i = 0; i < seedStyles.length; i++)
            DropdownOption(value: i + 1, label: seedStyles[i]),
        ],
      ),
      FieldSpec(
        key: 'price',
        label: 'Цена, ₽',
        kind: FieldKind.number,
        validate: (v) => Validators.inRange(
          v,
          'Цена',
          min: 1,
          max: 10000000,
        ),
      ),
      FieldSpec(
        key: 'stock',
        label: 'Остаток, шт',
        kind: FieldKind.integer,
        validate: (v) => Validators.nonNegativeInt(v, 'Остаток'),
      ),
      FieldSpec(
        key: 'width',
        label: 'Ширина, см',
        kind: FieldKind.number,
        required: false,
        validate: (v) =>
            (v == null || v.trim().isEmpty) ? null : Validators.positiveNumber(v, 'Ширина'),
      ),
      FieldSpec(
        key: 'depth',
        label: 'Глубина, см',
        kind: FieldKind.number,
        required: false,
        validate: (v) =>
            (v == null || v.trim().isEmpty) ? null : Validators.positiveNumber(v, 'Глубина'),
      ),
      FieldSpec(
        key: 'height',
        label: 'Высота, см',
        kind: FieldKind.number,
        required: false,
        validate: (v) =>
            (v == null || v.trim().isEmpty) ? null : Validators.positiveNumber(v, 'Высота'),
      ),
      FieldSpec(
        key: 'weight',
        label: 'Вес, кг',
        kind: FieldKind.number,
        required: false,
        validate: (v) =>
            (v == null || v.trim().isEmpty) ? null : Validators.positiveNumber(v, 'Вес'),
      ),
      FieldSpec(
        key: 'color',
        label: 'Цвет',
        required: false,
        maxLength: 40,
        validate: (v) => Validators.maxLength(v, 'цвет', 40),
      ),
    ];
  }

  @override
  Future<bool> saveEntity() async {
    final repo = context.read<ProductRepository>();
    final sku = controllers['sku']!.text.trim();

    final duplicate = await repo.findBySku(sku, exceptId: widget.id);
    if (duplicate != null) {
      setState(() {
        fieldErrors['sku'] = 'Артикул «$sku» уже используется';
      });
      return false;
    }

    final styleIndex = dropdownValues['style'];
    final product = Product(
      id: widget.id ?? 0,
      name: controllers['name']!.text.trim(),
      sku: sku,
      description: controllers['description']!.text.trim(),
      style: styleIndex == null ? '' : seedStyles[styleIndex - 1],
      price: _parseDouble(controllers['price']!.text),
      stock: int.tryParse(controllers['stock']!.text.trim()) ?? 0,
      width: _parseNullable(controllers['width']!.text),
      depth: _parseNullable(controllers['depth']!.text),
      height: _parseNullable(controllers['height']!.text),
      weight: _parseNullable(controllers['weight']!.text),
      color: controllers['color']!.text.trim(),
      categoryId: dropdownValues['categoryId'] ?? 0,
      manufacturerId: dropdownValues['manufacturerId'] ?? 0,
      materialIds: multiValues['materialIds'] ?? const [],
    );

    if (widget.isEditing) {
      await repo.update(product);
    } else {
      await repo.create(product);
    }
    return true;
  }

  double _parseDouble(String raw) {
    return double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;
  }

  double? _parseNullable(String raw) {
    final text = raw.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }
}
