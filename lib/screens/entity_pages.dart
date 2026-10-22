import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/category_query.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import '../models/material.dart';
import '../models/material_query.dart';
import '../repositories/repositories.dart';
import 'entity_list_screen.dart';

class CategoryListPage extends StatelessWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CategoryRepository>();
    final refs = context.watch<ReferenceRepository>();
    return EntityListScreen<Category>(
      title: 'Категории',
      basePath: '/categories',
      createLabel: 'Добавить',
      searchHint: 'Название категории',
      columns: [
        ColumnSpec<Category>(
          label: 'Название',
          sortField: 'name',
          build: (item, context) => Text(
            item.name + (item.isDeleted ? ' (удалена)' : ''),
          ),
        ),
        ColumnSpec<Category>(
          label: 'Описание',
          build: (item, context) => Text(
            item.description.isEmpty ? '—' : item.description,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ColumnSpec<Category>(
          label: 'Товаров',
          numeric: true,
          build: (item, context) =>
              Text('${refs.countProductsByCategory(item.id)}'),
        ),
      ],
      load: (search, sortField, ascending, page, size, includeDeleted) {
        return repo.find(CategoryQuery(
          search: search,
          sortField: sortField,
          sortAscending: ascending,
          page: page,
          size: size,
          includeDeleted: includeDeleted,
        ));
      },
      delete: (id, hard) async {
        if (hard) {
          await repo.hardDelete(id);
        } else {
          await repo.softDelete(id);
        }
      },
      restore: repo.restore,
      deleteMany: repo.deleteMany,
      countReferences: (item) async => refs.countProductsByCategory(item.id),
      idOf: (item) => item.id,
      isDeleted: (item) => item.isDeleted,
    );
  }
}

class ManufacturerListPage extends StatelessWidget {
  const ManufacturerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ManufacturerRepository>();
    final refs = context.watch<ReferenceRepository>();
    return EntityListScreen<Manufacturer>(
      title: 'Производители',
      basePath: '/manufacturers',
      createLabel: 'Добавить',
      searchHint: 'Название или страна',
      columns: [
        ColumnSpec<Manufacturer>(
          label: 'Название',
          sortField: 'name',
          build: (item, context) => Text(
            item.name + (item.isDeleted ? ' (удалён)' : ''),
          ),
        ),
        ColumnSpec<Manufacturer>(
          label: 'Страна',
          sortField: 'country',
          build: (item, context) => Text(item.country),
        ),
        ColumnSpec<Manufacturer>(
          label: 'Почта',
          build: (item, context) => Text(
            item.contactEmail.isEmpty ? '—' : item.contactEmail,
          ),
        ),
        ColumnSpec<Manufacturer>(
          label: 'Товаров',
          numeric: true,
          build: (item, context) =>
              Text('${refs.countProductsByManufacturer(item.id)}'),
        ),
      ],
      load: (search, sortField, ascending, page, size, includeDeleted) {
        return repo.find(ManufacturerQuery(
          search: search,
          sortField: sortField,
          sortAscending: ascending,
          page: page,
          size: size,
          includeDeleted: includeDeleted,
        ));
      },
      delete: (id, hard) async {
        if (hard) {
          await repo.hardDelete(id);
        } else {
          await repo.softDelete(id);
        }
      },
      restore: repo.restore,
      deleteMany: repo.deleteMany,
      countReferences: (item) async =>
          refs.countProductsByManufacturer(item.id),
      idOf: (item) => item.id,
      isDeleted: (item) => item.isDeleted,
    );
  }
}

class MaterialListPage extends StatelessWidget {
  const MaterialListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MaterialRepository>();
    final refs = context.watch<ReferenceRepository>();
    return EntityListScreen<FurnitureMaterial>(
      title: 'Материалы',
      basePath: '/materials',
      createLabel: 'Добавить',
      searchHint: 'Название материала',
      columns: [
        ColumnSpec<FurnitureMaterial>(
          label: 'Название',
          sortField: 'name',
          build: (item, context) => Text(
            item.name + (item.isDeleted ? ' (удалён)' : ''),
          ),
        ),
        ColumnSpec<FurnitureMaterial>(
          label: 'Описание',
          build: (item, context) => Text(
            item.description.isEmpty ? '—' : item.description,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ColumnSpec<FurnitureMaterial>(
          label: 'Товаров',
          numeric: true,
          build: (item, context) =>
              Text('${refs.countProductsByMaterial(item.id)}'),
        ),
      ],
      load: (search, sortField, ascending, page, size, includeDeleted) {
        return repo.find(MaterialQuery(
          search: search,
          sortField: sortField,
          sortAscending: ascending,
          page: page,
          size: size,
          includeDeleted: includeDeleted,
        ));
      },
      delete: (id, hard) async {
        if (hard) {
          await repo.hardDelete(id);
        } else {
          await repo.softDelete(id);
        }
      },
      restore: repo.restore,
      deleteMany: repo.deleteMany,
      countReferences: (item) async => refs.countProductsByMaterial(item.id),
      idOf: (item) => item.id,
      isDeleted: (item) => item.isDeleted,
    );
  }
}

class CustomerListPage extends StatelessWidget {
  const CustomerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CustomerRepository>();
    return EntityListScreen<Customer>(
      title: 'Покупатели',
      basePath: '/customers',
      createLabel: 'Добавить',
      searchHint: 'ФИО, почта или телефон',
      defaultSortField: 'fullName',
      columns: [
        ColumnSpec<Customer>(
          label: 'ФИО',
          sortField: 'fullName',
          build: (item, context) => Text(
            item.fullName + (item.isDeleted ? ' (удалён)' : ''),
          ),
        ),
        ColumnSpec<Customer>(
          label: 'Почта',
          sortField: 'email',
          build: (item, context) => Text(item.email),
        ),
        ColumnSpec<Customer>(
          label: 'Карта',
          build: (item, context) => Text(item.card?.number ?? '—'),
        ),
        ColumnSpec<Customer>(
          label: 'Баллы',
          sortField: 'points',
          numeric: true,
          build: (item, context) => Text('${item.card?.points ?? 0}'),
        ),
      ],
      load: (search, sortField, ascending, page, size, includeDeleted) {
        return repo.find(CustomerQuery(
          search: search,
          sortField: sortField,
          sortAscending: ascending,
          page: page,
          size: size,
          includeDeleted: includeDeleted,
        ));
      },
      delete: (id, hard) async {
        if (hard) {
          await repo.hardDelete(id);
        } else {
          await repo.softDelete(id);
        }
      },
      restore: repo.restore,
      deleteMany: repo.deleteMany,
      countReferences: (item) async => 0,
      idOf: (item) => item.id,
      isDeleted: (item) => item.isDeleted,
    );
  }
}
