import '../data/json_store.dart';
import '../data/seed.dart';
import '../data/storage_keys.dart';
import '../models/category.dart';
import '../models/category_query.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import '../models/material.dart';
import '../models/material_query.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import 'base_repository.dart';

class DeleteBlocked implements Exception {
  final String message;
  final int references;

  const DeleteBlocked(this.message, this.references);

  @override
  String toString() => message;
}

abstract interface class ProductRepository {
  Future<PageResult<Product>> find(ProductQuery query);
  Future<Product?> findById(int id);
  Future<Product?> findBySku(String sku, {int? exceptId});
  Future<int> create(Product product);
  Future<void> update(Product product);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  List<Product> all();
}

abstract interface class CategoryRepository {
  Future<PageResult<Category>> find(CategoryQuery query);
  Future<Category?> findById(int id);
  Future<Category?> findByName(String name, {int? exceptId});
  Future<int> create(Category category);
  Future<void> update(Category category);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  int countProducts(int categoryId);
  List<Category> all();
}

abstract interface class ManufacturerRepository {
  Future<PageResult<Manufacturer>> find(ManufacturerQuery query);
  Future<Manufacturer?> findById(int id);
  Future<Manufacturer?> findByName(String name, {int? exceptId});
  Future<int> create(Manufacturer manufacturer);
  Future<void> update(Manufacturer manufacturer);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  int countProducts(int manufacturerId);
  List<Manufacturer> all();
}

abstract interface class MaterialRepository {
  Future<PageResult<FurnitureMaterial>> find(MaterialQuery query);
  Future<FurnitureMaterial?> findById(int id);
  Future<FurnitureMaterial?> findByName(String name, {int? exceptId});
  Future<int> create(FurnitureMaterial material);
  Future<void> update(FurnitureMaterial material);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  int countProducts(int materialId);
  List<FurnitureMaterial> all();
}

abstract interface class CustomerRepository {
  Future<PageResult<Customer>> find(CustomerQuery query);
  Future<Customer?> findById(int id);
  Future<Customer?> findByEmail(String email, {int? exceptId});
  Future<int> create(Customer customer);
  Future<void> update(Customer customer);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  List<Customer> all();
}

class PersistentProductRepository implements ProductRepository {
  final BaseRepository<Product> _base;

  PersistentProductRepository(JsonStore store)
      : _base = BaseRepository<Product>(
          store: store,
          key: StorageKeys.products,
          seed: seedProducts,
          toJson: (p) => p.toJson(),
          fromJson: Product.fromJson,
          idOf: (p) => p.id,
          withDeletedAt: (p, when) => when == null
              ? p.copyWith(clearDeletedAt: true)
              : p.copyWith(deletedAt: when),
        );

  @override
  List<Product> all() => _base.rows;

  @override
  Future<PageResult<Product>> find(ProductQuery q) {
    final needle = q.search.trim().toLowerCase();
    return _base.find(
      isDeleted: (p) => p.isDeleted,
      page: q.page,
      size: q.size,
      includeDeleted: q.includeDeleted,
      filter: (p) {
        if (needle.isNotEmpty) {
          final hit = p.name.toLowerCase().contains(needle) ||
              p.description.toLowerCase().contains(needle) ||
              p.sku.toLowerCase().contains(needle);
          if (!hit) return false;
        }
        if (q.categoryId != null && p.categoryId != q.categoryId) {
          return false;
        }
        if (q.manufacturerId != null &&
            p.manufacturerId != q.manufacturerId) {
          return false;
        }
        if (q.priceFrom != null && p.price < q.priceFrom!) return false;
        if (q.priceTo != null && p.price > q.priceTo!) return false;
        if (q.style != null && q.style!.isNotEmpty && p.style != q.style) {
          return false;
        }
        if (q.inStockOnly && !p.inStock) return false;
        return true;
      },
      comparator: (a, b) {
        final result = switch (q.sortField) {
          'price' => a.price.compareTo(b.price),
          'stock' => a.stock.compareTo(b.stock),
          'name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          _ => throw ArgumentError(
              'Неизвестное поле сортировки: ${q.sortField}',
            ),
        };
        return q.sortAscending ? result : -result;
      },
    );
  }

  @override
  Future<Product?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _base.findByIdSync(id);
  }

  @override
  Future<Product?> findBySku(String sku, {int? exceptId}) async {
    final needle = sku.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final p in _base.rows) {
      if (p.isDeleted) continue;
      if (p.id == exceptId) continue;
      if (p.sku.trim().toLowerCase() == needle) return p;
    }
    return null;
  }

  @override
  Future<int> create(Product product) async {
    final id = _base.nextId();
    await _base.add(
      Product(
        id: id,
        name: product.name,
        sku: product.sku,
        description: product.description,
        style: product.style,
        price: product.price,
        stock: product.stock,
        width: product.width,
        depth: product.depth,
        height: product.height,
        weight: product.weight,
        color: product.color,
        categoryId: product.categoryId,
        manufacturerId: product.manufacturerId,
        materialIds: product.materialIds,
      ),
    );
    return id;
  }

  @override
  Future<void> update(Product product) => _base.update(product);

  @override
  Future<void> softDelete(int id) =>
      _base.softDelete(id, DateTime.now());

  @override
  Future<void> hardDelete(int id) => _base.hardDelete(id);

  @override
  Future<void> restore(int id) => _base.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final item = _base.findByIdSync(id);
      if (item == null || item.isDeleted) continue;
      await _base.softDelete(id, DateTime.now());
      count++;
    }
    return count;
  }
}

class PersistentCategoryRepository implements CategoryRepository {
  final BaseRepository<Category> _base;
  final ProductRepository _products;

  PersistentCategoryRepository(JsonStore store, this._products)
      : _base = BaseRepository<Category>(
          store: store,
          key: StorageKeys.categories,
          seed: seedCategories,
          toJson: (c) => c.toJson(),
          fromJson: Category.fromJson,
          idOf: (c) => c.id,
          withDeletedAt: (c, when) => when == null
              ? c.copyWith(clearDeletedAt: true)
              : c.copyWith(deletedAt: when),
        );

  @override
  List<Category> all() => _base.rows;

  @override
  Future<PageResult<Category>> find(CategoryQuery q) {
    final needle = q.search.trim().toLowerCase();
    return _base.find(
      isDeleted: (c) => c.isDeleted,
      page: q.page,
      size: q.size,
      includeDeleted: q.includeDeleted,
      filter: (c) => needle.isEmpty || c.name.toLowerCase().contains(needle),
      comparator: (a, b) {
        final result = switch (q.sortField) {
          'name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          _ => throw ArgumentError(
              'Неизвестное поле сортировки: ${q.sortField}',
            ),
        };
        return q.sortAscending ? result : -result;
      },
    );
  }

  @override
  Future<Category?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _base.findByIdSync(id);
  }

  @override
  Future<Category?> findByName(String name, {int? exceptId}) async {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final c in _base.rows) {
      if (c.isDeleted) continue;
      if (c.id == exceptId) continue;
      if (c.name.trim().toLowerCase() == needle) return c;
    }
    return null;
  }

  @override
  Future<int> create(Category category) async {
    final id = _base.nextId();
    await _base.add(Category(
      id: id,
      name: category.name,
      description: category.description,
    ));
    return id;
  }

  @override
  Future<void> update(Category category) => _base.update(category);

  @override
  Future<void> softDelete(int id) async {
    final references = countProducts(id);
    if (references > 0) {
      throw DeleteBlocked(
        'Нельзя удалить категорию: к ней привязано товаров — $references',
        references,
      );
    }
    await _base.softDelete(id, DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    final references = countProducts(id);
    if (references > 0) {
      throw DeleteBlocked(
        'Нельзя удалить категорию: к ней привязано товаров — $references',
        references,
      );
    }
    await _base.hardDelete(id);
  }

  @override
  Future<void> restore(int id) => _base.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final item = _base.findByIdSync(id);
      if (item == null || item.isDeleted) continue;
      if (countProducts(id) > 0) continue;
      await _base.softDelete(id, DateTime.now());
      count++;
    }
    return count;
  }

  @override
  int countProducts(int categoryId) => _products
      .all()
      .where((p) => !p.isDeleted && p.categoryId == categoryId)
      .length;
}

class PersistentManufacturerRepository implements ManufacturerRepository {
  final BaseRepository<Manufacturer> _base;
  final ProductRepository _products;

  PersistentManufacturerRepository(JsonStore store, this._products)
      : _base = BaseRepository<Manufacturer>(
          store: store,
          key: StorageKeys.manufacturers,
          seed: seedManufacturers,
          toJson: (m) => m.toJson(),
          fromJson: Manufacturer.fromJson,
          idOf: (m) => m.id,
          withDeletedAt: (m, when) => when == null
              ? m.copyWith(clearDeletedAt: true)
              : m.copyWith(deletedAt: when),
        );

  @override
  List<Manufacturer> all() => _base.rows;

  @override
  Future<PageResult<Manufacturer>> find(ManufacturerQuery q) {
    final needle = q.search.trim().toLowerCase();
    return _base.find(
      isDeleted: (m) => m.isDeleted,
      page: q.page,
      size: q.size,
      includeDeleted: q.includeDeleted,
      filter: (m) =>
          needle.isEmpty ||
          m.name.toLowerCase().contains(needle) ||
          m.country.toLowerCase().contains(needle),
      comparator: (a, b) {
        final result = switch (q.sortField) {
          'name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          'country' =>
            a.country.toLowerCase().compareTo(b.country.toLowerCase()),
          _ => throw ArgumentError(
              'Неизвестное поле сортировки: ${q.sortField}',
            ),
        };
        return q.sortAscending ? result : -result;
      },
    );
  }

  @override
  Future<Manufacturer?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _base.findByIdSync(id);
  }

  @override
  Future<Manufacturer?> findByName(String name, {int? exceptId}) async {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final m in _base.rows) {
      if (m.isDeleted) continue;
      if (m.id == exceptId) continue;
      if (m.name.trim().toLowerCase() == needle) return m;
    }
    return null;
  }

  @override
  Future<int> create(Manufacturer manufacturer) async {
    final id = _base.nextId();
    await _base.add(Manufacturer(
      id: id,
      name: manufacturer.name,
      country: manufacturer.country,
      contactEmail: manufacturer.contactEmail,
    ));
    return id;
  }

  @override
  Future<void> update(Manufacturer manufacturer) => _base.update(manufacturer);

  @override
  Future<void> softDelete(int id) async {
    final references = countProducts(id);
    if (references > 0) {
      throw DeleteBlocked(
        'Нельзя удалить производителя: к нему привязано товаров — $references',
        references,
      );
    }
    await _base.softDelete(id, DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    final references = countProducts(id);
    if (references > 0) {
      throw DeleteBlocked(
        'Нельзя удалить производителя: к нему привязано товаров — $references',
        references,
      );
    }
    await _base.hardDelete(id);
  }

  @override
  Future<void> restore(int id) => _base.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final item = _base.findByIdSync(id);
      if (item == null || item.isDeleted) continue;
      if (countProducts(id) > 0) continue;
      await _base.softDelete(id, DateTime.now());
      count++;
    }
    return count;
  }

  @override
  int countProducts(int manufacturerId) => _products
      .all()
      .where((p) => !p.isDeleted && p.manufacturerId == manufacturerId)
      .length;
}

class PersistentMaterialRepository implements MaterialRepository {
  final BaseRepository<FurnitureMaterial> _base;
  final ProductRepository _products;

  PersistentMaterialRepository(JsonStore store, this._products)
      : _base = BaseRepository<FurnitureMaterial>(
          store: store,
          key: StorageKeys.materials,
          seed: seedMaterials,
          toJson: (m) => m.toJson(),
          fromJson: FurnitureMaterial.fromJson,
          idOf: (m) => m.id,
          withDeletedAt: (m, when) => when == null
              ? m.copyWith(clearDeletedAt: true)
              : m.copyWith(deletedAt: when),
        );

  @override
  List<FurnitureMaterial> all() => _base.rows;

  @override
  Future<PageResult<FurnitureMaterial>> find(MaterialQuery q) {
    final needle = q.search.trim().toLowerCase();
    return _base.find(
      isDeleted: (m) => m.isDeleted,
      page: q.page,
      size: q.size,
      includeDeleted: q.includeDeleted,
      filter: (m) => needle.isEmpty || m.name.toLowerCase().contains(needle),
      comparator: (a, b) {
        final result = switch (q.sortField) {
          'name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          _ => throw ArgumentError(
              'Неизвестное поле сортировки: ${q.sortField}',
            ),
        };
        return q.sortAscending ? result : -result;
      },
    );
  }

  @override
  Future<FurnitureMaterial?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _base.findByIdSync(id);
  }

  @override
  Future<FurnitureMaterial?> findByName(String name, {int? exceptId}) async {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final m in _base.rows) {
      if (m.isDeleted) continue;
      if (m.id == exceptId) continue;
      if (m.name.trim().toLowerCase() == needle) return m;
    }
    return null;
  }

  @override
  Future<int> create(FurnitureMaterial material) async {
    final id = _base.nextId();
    await _base.add(FurnitureMaterial(
      id: id,
      name: material.name,
      description: material.description,
    ));
    return id;
  }

  @override
  Future<void> update(FurnitureMaterial material) => _base.update(material);

  @override
  Future<void> softDelete(int id) async {
    final references = countProducts(id);
    if (references > 0) {
      throw DeleteBlocked(
        'Нельзя удалить материал: он используется в товарах — $references',
        references,
      );
    }
    await _base.softDelete(id, DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    final references = countProducts(id);
    if (references > 0) {
      throw DeleteBlocked(
        'Нельзя удалить материал: он используется в товарах — $references',
        references,
      );
    }
    await _base.hardDelete(id);
  }

  @override
  Future<void> restore(int id) => _base.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final item = _base.findByIdSync(id);
      if (item == null || item.isDeleted) continue;
      if (countProducts(id) > 0) continue;
      await _base.softDelete(id, DateTime.now());
      count++;
    }
    return count;
  }

  @override
  int countProducts(int materialId) => _products
      .all()
      .where((p) => !p.isDeleted && p.materialIds.contains(materialId))
      .length;
}

class PersistentCustomerRepository implements CustomerRepository {
  final BaseRepository<Customer> _base;

  PersistentCustomerRepository(JsonStore store)
      : _base = BaseRepository<Customer>(
          store: store,
          key: StorageKeys.customers,
          seed: seedCustomers,
          toJson: (c) => c.toJson(),
          fromJson: Customer.fromJson,
          idOf: (c) => c.id,
          withDeletedAt: (c, when) => when == null
              ? c.copyWith(clearDeletedAt: true)
              : c.copyWith(deletedAt: when),
        );

  @override
  List<Customer> all() => _base.rows;

  @override
  Future<PageResult<Customer>> find(CustomerQuery q) {
    final needle = q.search.trim().toLowerCase();
    return _base.find(
      isDeleted: (c) => c.isDeleted,
      page: q.page,
      size: q.size,
      includeDeleted: q.includeDeleted,
      filter: (c) =>
          needle.isEmpty ||
          c.fullName.toLowerCase().contains(needle) ||
          c.email.toLowerCase().contains(needle) ||
          c.phone.toLowerCase().contains(needle),
      comparator: (a, b) {
        final result = switch (q.sortField) {
          'fullName' =>
            a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
          'points' => (a.card?.points ?? 0).compareTo(b.card?.points ?? 0),
          _ => throw ArgumentError(
              'Неизвестное поле сортировки: ${q.sortField}',
            ),
        };
        return q.sortAscending ? result : -result;
      },
    );
  }

  @override
  Future<Customer?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _base.findByIdSync(id);
  }

  @override
  Future<Customer?> findByEmail(String email, {int? exceptId}) async {
    final needle = email.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final c in _base.rows) {
      if (c.isDeleted) continue;
      if (c.id == exceptId) continue;
      if (c.email.trim().toLowerCase() == needle) return c;
    }
    return null;
  }

  @override
  Future<int> create(Customer customer) async {
    final id = _base.nextId();
    await _base.add(Customer(
      id: id,
      fullName: customer.fullName,
      email: customer.email,
      phone: customer.phone,
      address: customer.address,
      card: customer.card,
    ));
    return id;
  }

  @override
  Future<void> update(Customer customer) => _base.update(customer);

  @override
  Future<void> softDelete(int id) => _base.softDelete(id, DateTime.now());

  @override
  Future<void> hardDelete(int id) => _base.hardDelete(id);

  @override
  Future<void> restore(int id) => _base.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final item = _base.findByIdSync(id);
      if (item == null || item.isDeleted) continue;
      await _base.softDelete(id, DateTime.now());
      count++;
    }
    return count;
  }
}

class InMemoryReferenceRepository implements ReferenceRepository {
  final CategoryRepository _categories;
  final ManufacturerRepository _manufacturers;
  final MaterialRepository _materials;

  InMemoryReferenceRepository(
    this._categories,
    this._manufacturers,
    this._materials,
  );

  @override
  List<Category> categories() => [
        for (final c in _categories.all())
          if (!c.isDeleted) c,
      ];

  @override
  String categoryName(int id) {
    for (final c in _categories.all()) {
      if (c.id == id) return c.name;
    }
    return '—';
  }

  @override
  List<Manufacturer> manufacturers() => [
        for (final m in _manufacturers.all())
          if (!m.isDeleted) m,
      ];

  @override
  List<FurnitureMaterial> materials() => [
        for (final m in _materials.all())
          if (!m.isDeleted) m,
      ];

  @override
  String manufacturerName(int id) {
    for (final m in _manufacturers.all()) {
      if (m.id == id) return m.name;
    }
    return '—';
  }

  @override
  List<String> materialNames(List<int> ids) {
    return [
      for (final m in _materials.all())
        if (ids.contains(m.id)) m.name,
    ];
  }
}

abstract interface class ReferenceRepository {
  List<Category> categories();
  String categoryName(int id);
  List<Manufacturer> manufacturers();
  List<FurnitureMaterial> materials();
  String manufacturerName(int id);
  List<String> materialNames(List<int> ids);
}
