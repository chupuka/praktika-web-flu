import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../core/api_exceptions.dart';
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
import 'repositories.dart';

Map<String, dynamic> _queryParams(Map<String, String> params) {
  final result = <String, dynamic>{};
  for (final entry in params.entries) {
    if (entry.value.isEmpty) continue;
    result[entry.key] = entry.value;
  }
  return result;
}

class _Page {
  final List<dynamic> items;
  final int page;
  final int size;
  final int total;

  const _Page(this.items, this.page, this.size, this.total);
}

_Page _parsePage(dynamic data) {
  final map = Map<String, dynamic>.from(data as Map);
  final raw = (map['items'] as List?) ?? const [];
  return _Page(
    raw,
    (map['page'] as num?)?.toInt() ?? 1,
    (map['size'] as num?)?.toInt() ?? 10,
    (map['total'] as num?)?.toInt() ?? raw.length,
  );
}

class ApiProductRepository implements ProductRepository {
  final ApiClient _client;

  ApiProductRepository(this._client);

  @override
  Future<PageResult<Product>> find(
    ProductQuery query, {
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<dynamic>(
      '/products',
      queryParameters: _queryParams(query.toParameters()),
      cancelToken: cancelToken,
    );
    final page = _parsePage(data);
    return PageResult(
      items: page.items
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      page: page.page,
      size: page.size,
      total: page.total,
    );
  }

  @override
  Future<Product?> findById(int id) async {
    try {
      final data = await _client.get<dynamic>('/products/$id');
      return Product.fromJson(Map<String, dynamic>.from(data as Map));
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<int> create(Product product) async {
    final data = await _client.post<dynamic>('/products', data: _toJson(product));
    return (Map<String, dynamic>.from(data as Map)['id'] as num?)?.toInt() ?? 0;
  }

  Future<List<Product>> findAll() async {
    final data = await _client.get<dynamic>(
      '/products',
      queryParameters: {'size': 100},
    );
    final page = _parsePage(data);
    return page.items
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> update(Product product) async {
    await _client.put<dynamic>(
      '/products/${product.id}',
      data: _toJson(product),
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await _client.delete('/products/$id');
  }

  @override
  Future<void> hardDelete(int id) async {
    await _client.delete('/products/$id', queryParameters: {'hard': 'true'});
  }

  @override
  Future<void> restore(int id) async {
    await _client.post<dynamic>('/products/$id/restore');
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final data = await _client.post<dynamic>(
      '/products/bulk-delete',
      data: {'ids': ids},
    );
    return (Map<String, dynamic>.from(data as Map)['deleted'] as num?)?.toInt() ??
        0;
  }

  Map<String, dynamic> _toJson(Product p) {
    return {
      'name': p.name,
      'sku': p.sku,
      'description': p.description,
      'style': p.style,
      'price': p.price,
      'stock': p.stock,
      'width': p.width,
      'depth': p.depth,
      'height': p.height,
      'weight': p.weight,
      'color': p.color,
      'categoryId': p.categoryId,
      'manufacturerId': p.manufacturerId,
      'materialIds': p.materialIds,
    };
  }
}

class ApiCategoryRepository implements CategoryRepository {
  final ApiClient _client;

  ApiCategoryRepository(this._client);

  @override
  Future<PageResult<Category>> find(
    CategoryQuery query, {
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<dynamic>(
      '/categories',
      queryParameters: _queryParams(query.toParameters()),
      cancelToken: cancelToken,
    );
    final page = _parsePage(data);
    return PageResult(
      items: page.items
          .map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      page: page.page,
      size: page.size,
      total: page.total,
    );
  }

  @override
  Future<Category?> findById(int id) async {
    try {
      final data = await _client.get<dynamic>('/categories/$id');
      return Category.fromJson(Map<String, dynamic>.from(data as Map));
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<int> create(Category category) async {
    final data = await _client.post<dynamic>(
      '/categories',
      data: {'name': category.name, 'description': category.description},
    );
    return (Map<String, dynamic>.from(data as Map)['id'] as num?)?.toInt() ?? 0;
  }

  Future<List<Category>> findAll() async {
    final data = await _client.get<dynamic>(
      '/categories',
      queryParameters: {'size': 100},
    );
    final page = _parsePage(data);
    return page.items
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> update(Category category) async {
    await _client.put<dynamic>(
      '/categories/${category.id}',
      data: {'name': category.name, 'description': category.description},
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await _client.delete('/categories/$id');
  }

  @override
  Future<void> hardDelete(int id) async {
    await _client.delete('/categories/$id', queryParameters: {'hard': 'true'});
  }

  @override
  Future<void> restore(int id) async {
    await _client.post<dynamic>('/categories/$id/restore');
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final data = await _client.post<dynamic>(
      '/categories/bulk-delete',
      data: {'ids': ids},
    );
    return (Map<String, dynamic>.from(data as Map)['deleted'] as num?)?.toInt() ??
        0;
  }
}

class ApiManufacturerRepository implements ManufacturerRepository {
  final ApiClient _client;

  ApiManufacturerRepository(this._client);

  @override
  Future<PageResult<Manufacturer>> find(
    ManufacturerQuery query, {
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<dynamic>(
      '/manufacturers',
      queryParameters: _queryParams(query.toParameters()),
      cancelToken: cancelToken,
    );
    final page = _parsePage(data);
    return PageResult(
      items: page.items
          .map((e) => Manufacturer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      page: page.page,
      size: page.size,
      total: page.total,
    );
  }

  @override
  Future<Manufacturer?> findById(int id) async {
    try {
      final data = await _client.get<dynamic>('/manufacturers/$id');
      return Manufacturer.fromJson(Map<String, dynamic>.from(data as Map));
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<int> create(Manufacturer manufacturer) async {
    final data = await _client.post<dynamic>(
      '/manufacturers',
      data: {
        'name': manufacturer.name,
        'country': manufacturer.country,
        'contactEmail': manufacturer.contactEmail,
      },
    );
    return (Map<String, dynamic>.from(data as Map)['id'] as num?)?.toInt() ?? 0;
  }

  Future<List<Manufacturer>> findAll() async {
    final data = await _client.get<dynamic>(
      '/manufacturers',
      queryParameters: {'size': 100},
    );
    final page = _parsePage(data);
    return page.items
        .map((e) => Manufacturer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> update(Manufacturer manufacturer) async {
    await _client.put<dynamic>(
      '/manufacturers/${manufacturer.id}',
      data: {
        'name': manufacturer.name,
        'country': manufacturer.country,
        'contactEmail': manufacturer.contactEmail,
      },
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await _client.delete('/manufacturers/$id');
  }

  @override
  Future<void> hardDelete(int id) async {
    await _client.delete(
      '/manufacturers/$id',
      queryParameters: {'hard': 'true'},
    );
  }

  @override
  Future<void> restore(int id) async {
    await _client.post<dynamic>('/manufacturers/$id/restore');
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final data = await _client.post<dynamic>(
      '/manufacturers/bulk-delete',
      data: {'ids': ids},
    );
    return (Map<String, dynamic>.from(data as Map)['deleted'] as num?)?.toInt() ??
        0;
  }
}

class ApiMaterialRepository implements MaterialRepository {
  final ApiClient _client;

  ApiMaterialRepository(this._client);

  @override
  Future<PageResult<FurnitureMaterial>> find(
    MaterialQuery query, {
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<dynamic>(
      '/materials',
      queryParameters: _queryParams(query.toParameters()),
      cancelToken: cancelToken,
    );
    final page = _parsePage(data);
    return PageResult(
      items: page.items
          .map(
            (e) => FurnitureMaterial.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      page: page.page,
      size: page.size,
      total: page.total,
    );
  }

  @override
  Future<FurnitureMaterial?> findById(int id) async {
    try {
      final data = await _client.get<dynamic>('/materials/$id');
      return FurnitureMaterial.fromJson(Map<String, dynamic>.from(data as Map));
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<int> create(FurnitureMaterial material) async {
    final data = await _client.post<dynamic>(
      '/materials',
      data: {'name': material.name, 'description': material.description},
    );
    return (Map<String, dynamic>.from(data as Map)['id'] as num?)?.toInt() ?? 0;
  }

  Future<List<FurnitureMaterial>> findAll() async {
    final data = await _client.get<dynamic>(
      '/materials',
      queryParameters: {'size': 100},
    );
    final page = _parsePage(data);
    return page.items
        .map(
          (e) => FurnitureMaterial.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> update(FurnitureMaterial material) async {
    await _client.put<dynamic>(
      '/materials/${material.id}',
      data: {'name': material.name, 'description': material.description},
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await _client.delete('/materials/$id');
  }

  @override
  Future<void> hardDelete(int id) async {
    await _client.delete('/materials/$id', queryParameters: {'hard': 'true'});
  }

  @override
  Future<void> restore(int id) async {
    await _client.post<dynamic>('/materials/$id/restore');
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final data = await _client.post<dynamic>(
      '/materials/bulk-delete',
      data: {'ids': ids},
    );
    return (Map<String, dynamic>.from(data as Map)['deleted'] as num?)?.toInt() ??
        0;
  }
}

class ApiCustomerRepository implements CustomerRepository {
  final ApiClient _client;

  ApiCustomerRepository(this._client);

  @override
  Future<PageResult<Customer>> find(
    CustomerQuery query, {
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<dynamic>(
      '/customers',
      queryParameters: _queryParams(query.toParameters()),
      cancelToken: cancelToken,
    );
    final page = _parsePage(data);
    return PageResult(
      items: page.items
          .map((e) => Customer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      page: page.page,
      size: page.size,
      total: page.total,
    );
  }

  @override
  Future<Customer?> findById(int id) async {
    try {
      final data = await _client.get<dynamic>('/customers/$id');
      return Customer.fromJson(Map<String, dynamic>.from(data as Map));
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<int> create(Customer customer) async {
    final data = await _client.post<dynamic>(
      '/customers',
      data: _toJson(customer),
    );
    return (Map<String, dynamic>.from(data as Map)['id'] as num?)?.toInt() ?? 0;
  }

  Future<List<Customer>> findAll() async {
    final data = await _client.get<dynamic>(
      '/customers',
      queryParameters: {'size': 100},
    );
    final page = _parsePage(data);
    return page.items
        .map((e) => Customer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> update(Customer customer) async {
    await _client.put<dynamic>(
      '/customers/${customer.id}',
      data: _toJson(customer),
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await _client.delete('/customers/$id');
  }

  @override
  Future<void> hardDelete(int id) async {
    await _client.delete('/customers/$id', queryParameters: {'hard': 'true'});
  }

  @override
  Future<void> restore(int id) async {
    await _client.post<dynamic>('/customers/$id/restore');
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final data = await _client.post<dynamic>(
      '/customers/bulk-delete',
      data: {'ids': ids},
    );
    return (Map<String, dynamic>.from(data as Map)['deleted'] as num?)?.toInt() ??
        0;
  }

  Map<String, dynamic> _toJson(Customer c) {
    return {
      'fullName': c.fullName,
      'email': c.email,
      'phone': c.phone,
      'address': c.address,
      'card': c.card == null
          ? null
          : {
              'number': c.card!.number,
              'issuedAt': c.card!.issuedAt,
              'tier': c.card!.tier,
              'points': c.card!.points,
            },
    };
  }
}

class ApiReferenceRepository extends ChangeNotifier
    implements ReferenceRepository {
  final ProductRepository _products;
  final CategoryRepository _categories;
  final ManufacturerRepository _manufacturers;
  final MaterialRepository _materials;

  List<Category> _categoryRows = const [];
  List<Manufacturer> _manufacturerRows = const [];
  List<FurnitureMaterial> _materialRows = const [];
  List<Product> _productRows = const [];
  DateTime _stamp = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void>? _pending;

  ApiReferenceRepository({
    required ProductRepository products,
    required CategoryRepository categories,
    required ManufacturerRepository manufacturers,
    required MaterialRepository materials,
  })  : _products = products,
        _categories = categories,
        _manufacturers = manufacturers,
        _materials = materials;

  bool get isFresh {
    return DateTime.now().difference(_stamp) < ApiConfig.referenceCacheTtl;
  }

  @override
  Future<void> refresh() async {
    if (_pending != null) return _pending!;
    final completer = Completer<void>();
    _pending = completer.future;
    try {
      final results = await Future.wait<Object>([
        _categories.find(const CategoryQuery(size: 100)),
        _manufacturers.find(const ManufacturerQuery(size: 100)),
        _materials.find(const MaterialQuery(size: 100)),
        _products.find(const ProductQuery(size: 100)),
      ]);
      _categoryRows = (results[0] as PageResult<Category>).items;
      _manufacturerRows = (results[1] as PageResult<Manufacturer>).items;
      _materialRows = (results[2] as PageResult<FurnitureMaterial>).items;
      _productRows = (results[3] as PageResult<Product>).items;
      _stamp = DateTime.now();
      notifyListeners();
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _pending = null;
    }
  }

  @override
  Future<void> ensureLoaded() async {
    if (isFresh) return;
    await refresh();
  }

  @override
  List<Category> categories() {
    return [for (final c in _categoryRows) if (!c.isDeleted) c];
  }

  @override
  String categoryName(int id) {
    for (final c in categories()) {
      if (c.id == id) return c.name;
    }
    return '—';
  }

  @override
  List<Manufacturer> manufacturers() {
    return [for (final m in _manufacturerRows) if (!m.isDeleted) m];
  }

  @override
  String manufacturerName(int id) {
    for (final m in manufacturers()) {
      if (m.id == id) return m.name;
    }
    return '—';
  }

  @override
  List<FurnitureMaterial> materials() {
    return [for (final m in _materialRows) if (!m.isDeleted) m];
  }

  @override
  List<String> materialNames(List<int> ids) {
    return [
      for (final m in materials())
        if (ids.contains(m.id)) m.name,
    ];
  }

  @override
  int countProductsByCategory(int categoryId) {
    return _productRows
        .where((p) => !p.isDeleted && p.categoryId == categoryId)
        .length;
  }

  @override
  int countProductsByManufacturer(int manufacturerId) {
    return _productRows
        .where((p) => !p.isDeleted && p.manufacturerId == manufacturerId)
        .length;
  }

  @override
  int countProductsByMaterial(int materialId) {
    return _productRows
        .where((p) => !p.isDeleted && p.materialIds.contains(materialId))
        .length;
  }
}
