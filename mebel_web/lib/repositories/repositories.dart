import '../data/seed.dart';
import '../models/category.dart';
import '../models/category_query.dart';
import '../models/manufacturer.dart';
import '../models/material.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';

abstract interface class ProductRepository {
  Future<PageResult<Product>> find(ProductQuery query);
  Future<Product?> findById(int id);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

abstract interface class CategoryRepository {
  Future<PageResult<Category>> find(CategoryQuery query);
  Future<Category?> findById(int id);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

abstract interface class ReferenceRepository {
  List<Category> categories();
  String categoryName(int id);
  List<Manufacturer> manufacturers();
  List<Material> materials();
  String manufacturerName(int id);
  List<String> materialNames(List<int> ids);
}

class InMemoryProductRepository implements ProductRepository {
  final List<Product> _products = List.of(seedProducts);

  @override
  Future<PageResult<Product>> find(ProductQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _products
        .where((p) => q.includeDeleted || !p.isDeleted)
        .toList();

    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where((p) =>
              p.name.toLowerCase().contains(needle) ||
              p.description.toLowerCase().contains(needle))
          .toList();
    }
    if (q.categoryId != null) {
      rows = rows.where((p) => p.categoryId == q.categoryId).toList();
    }
    if (q.manufacturerId != null) {
      rows =
          rows.where((p) => p.manufacturerId == q.manufacturerId).toList();
    }
    if (q.priceFrom != null) {
      rows = rows.where((p) => p.price >= q.priceFrom!).toList();
    }
    if (q.priceTo != null) {
      rows = rows.where((p) => p.price <= q.priceTo!).toList();
    }
    if (q.style != null && q.style!.isNotEmpty) {
      rows = rows.where((p) => p.style == q.style).toList();
    }
    if (q.inStockOnly) {
      rows = rows.where((p) => p.inStock).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'price' => a.price.compareTo(b.price),
        'stock' => a.stock.compareTo(b.stock),
        'name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        _ => throw ArgumentError('Неизвестное поле сортировки: ${q.sortField}'),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Product>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Product?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _products.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Товар $id не найден');
    _products[i] = _products[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _products.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _products.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Товар $id не найден');
    _products[i] = _products[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _products.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _products[i] = _products[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}

class InMemoryCategoryRepository implements CategoryRepository {
  final List<Category> _categories = List.of(seedCategories);

  @override
  Future<PageResult<Category>> find(CategoryQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _categories
        .where((c) => q.includeDeleted || !c.isDeleted)
        .toList();

    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where((c) => c.name.toLowerCase().contains(needle))
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        _ => throw ArgumentError('Неизвестное поле сортировки: ${q.sortField}'),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Category>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Category?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _categories.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Категория $id не найдена');
    _categories[i] = _categories[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _categories.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _categories.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Категория $id не найдена');
    _categories[i] = _categories[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _categories.indexWhere((c) => c.id == id && !c.isDeleted);
      if (i != -1) {
        _categories[i] = _categories[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}

class InMemoryReferenceRepository implements ReferenceRepository {
  @override
  List<Category> categories() => seedCategories;

  @override
  String categoryName(int id) {
    for (final c in seedCategories) {
      if (c.id == id) return c.name;
    }
    return '—';
  }

  @override
  List<Manufacturer> manufacturers() => seedManufacturers;

  @override
  List<Material> materials() => seedMaterials;

  @override
  String manufacturerName(int id) {
    for (final m in seedManufacturers) {
      if (m.id == id) return m.name;
    }
    return '—';
  }

  @override
  List<String> materialNames(List<int> ids) {
    return [
      for (final m in seedMaterials)
        if (ids.contains(m.id)) m.name,
    ];
  }
}
