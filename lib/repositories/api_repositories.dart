import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/category.dart';
import '../models/category_query.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import '../models/material.dart';
import '../models/material_query.dart';
import '../models/order.dart';
import '../models/order_query.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../models/review.dart';
import '../models/stats.dart';
import 'repositories.dart';

const _countHeader = {'Prefer': 'count=exact'};
const _representation = {'Prefer': 'return=representation'};

({List<dynamic> rows, int total}) _readPage(
  Response<dynamic> response, {
  required int page,
  required int size,
}) {
  final rows = (response.data as List?) ?? const [];
  final range = response.headers.value('content-range') ?? '';
  final total = int.tryParse(range.split('/').last) ?? rows.length;
  return (rows: rows, total: total);
}

Map<String, dynamic> _filters(Map<String, String?> entries) {
  final result = <String, dynamic>{};
  for (final entry in entries.entries) {
    if (entry.value != null && entry.value!.isNotEmpty) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}

String? _searchOr(String value, List<String> fields) {
  final term = value.trim().replaceAll(',', ' ').replaceAll('(', ' ');
  if (term.isEmpty) return null;
  return '(${fields.map((f) => '$f.ilike.*$term*').join(',')})';
}

String _order(String field, bool ascending) {
  final column = switch (field) {
    'fullName' => 'full_name',
    'contactEmail' => 'contact_email',
    'createdAt' => 'created_at',
    _ => field,
  };
  return '$column.${ascending ? 'asc' : 'desc'}';
}

String? _deletedFilter(bool includeDeleted) =>
    includeDeleted ? null : 'is.null';

Map<String, dynamic> _productJson(Map<String, dynamic> row) {
  final materials = (row['product_materials'] as List?) ?? const [];
  return {
    'id': row['id'],
    'name': row['name'],
    'sku': row['sku'],
    'description': row['description'],
    'style': row['style'],
    'price': row['price'],
    'stock': row['stock'],
    'width': row['width'],
    'depth': row['depth'],
    'height': row['height'],
    'weight': row['weight'],
    'color': row['color'],
    'categoryId': row['category_id'],
    'manufacturerId': row['manufacturer_id'],
    'materialIds': [
      for (final link in materials)
        if (link is Map && link['material_id'] != null)
          (link['material_id'] as num).toInt(),
    ],
    'deletedAt': row['deleted_at'],
  };
}

Map<String, dynamic> _categoryJson(Map<String, dynamic> row) => {
      'id': row['id'],
      'name': row['name'],
      'description': row['description'],
      'deletedAt': row['deleted_at'],
    };

Map<String, dynamic> _manufacturerJson(Map<String, dynamic> row) => {
      'id': row['id'],
      'name': row['name'],
      'country': row['country'],
      'contactEmail': row['contact_email'],
      'deletedAt': row['deleted_at'],
    };

Map<String, dynamic> _materialJson(Map<String, dynamic> row) => {
      'id': row['id'],
      'name': row['name'],
      'description': row['description'],
      'deletedAt': row['deleted_at'],
    };

Map<String, dynamic> _customerJson(Map<String, dynamic> row) {
  final rawCards = row['loyalty_cards'];
  final card = rawCards is List
      ? (rawCards.isEmpty ? null : rawCards.first as Map)
      : rawCards as Map?;
  return {
    'id': row['id'],
    'fullName': row['full_name'],
    'email': row['email'],
    'phone': row['phone'],
    'address': row['address'],
    'card': card == null
        ? null
        : {
            'number': card['number'],
            'issuedAt': card['issued_at'],
            'tier': card['tier'],
            'points': card['points'],
          },
    'deletedAt': row['deleted_at'],
  };
}

Future<List<dynamic>> _insert(
  ApiClient client,
  String table,
  List<Map<String, dynamic>> rows, {
  bool representation = true,
}) async {
  if (rows.isEmpty) return const [];
  final response = await client.postRaw<dynamic>(
    table,
    data: rows,
    headers: representation ? _representation : null,
  );
  return (response.data as List?) ?? const [];
}

Future<int> _deleteWhere(
  ApiClient client,
  String table,
  Map<String, dynamic> query,
) async {
  final response =
      await client.deleteRaw<dynamic>(table, queryParameters: query);
  return (response.data as List?)?.length ?? 0;
}

Future<int> _patchWhere(
  ApiClient client,
  String table,
  Map<String, dynamic> body,
  Map<String, dynamic> query,
) async {
  final response = await client.patchRaw<dynamic>(
    table,
    data: body,
    queryParameters: query,
    headers: _representation,
  );
  return (response.data as List?)?.length ?? 0;
}

class ApiProductRepository implements ProductRepository {
  final ApiClient _client;

  ApiProductRepository(this._client);

  @override
  Future<PageResult<Product>> find(
    ProductQuery query, {
    CancelToken? cancelToken,
  }) async {
    final response = await _client.getRaw<dynamic>(
      'products',
      queryParameters: {
        'select': '*,product_materials(material_id)',
        'order': _order(query.sortField, query.sortAscending),
        'limit': '${query.size}',
        'offset': '${(query.page - 1) * query.size}',
        ..._filters({
          'deleted_at': _deletedFilter(query.includeDeleted),
          'category_id':
              query.categoryId == null ? null : 'eq.${query.categoryId}',
          'manufacturer_id': query.manufacturerId == null
              ? null
              : 'eq.${query.manufacturerId}',
          'style': query.style,
          'stock': query.inStockOnly ? 'gt.0' : null,
          if (query.priceFrom != null && query.priceTo == null)
            'price': 'gte.${query.priceFrom}',
          if (query.priceFrom == null && query.priceTo != null)
            'price': 'lte.${query.priceTo}',
          if (query.priceFrom != null && query.priceTo != null)
            'and': '(price.gte.${query.priceFrom},price.lte.${query.priceTo})',
        }),
        if (_searchOr(query.search, ['name', 'sku', 'description', 'color'])
            case final or?)
          'or': or,
      },
      headers: _countHeader,
      cancelToken: cancelToken,
    );
    final page = _readPage(response, page: query.page, size: query.size);
    return PageResult(
      items: [
        for (final row in page.rows)
          Product.fromJson(_productJson(Map<String, dynamic>.from(row as Map))),
      ],
      page: query.page,
      size: query.size,
      total: page.total,
    );
  }

  @override
  Future<Product?> findById(int id) async {
    final response = await _client.getRaw<dynamic>(
      'products',
      queryParameters: {
        'select': '*,product_materials(material_id)',
        'id': 'eq.$id',
        'limit': '1',
      },
    );
    final rows = (response.data as List?) ?? const [];
    if (rows.isEmpty) return null;
    return Product.fromJson(
      _productJson(Map<String, dynamic>.from(rows.first as Map)),
    );
  }

  @override
  Future<int> create(Product product) async {
    final rows = await _insert(_client, 'products', [_productBody(product)]);
    final id = ((rows.first as Map)['id'] as num).toInt();
    await _writeMaterials(id, product.materialIds);
    return id;
  }

  @override
  Future<void> update(Product product) async {
    await _patchWhere(
      _client,
      'products',
      _productBody(product),
      {'id': 'eq.${product.id}'},
    );
    await _deleteWhere(_client, 'product_materials', {
      'product_id': 'eq.${product.id}',
    });
    await _writeMaterials(product.id, product.materialIds);
  }

  Future<void> _writeMaterials(int productId, List<int> ids) async {
    if (ids.isEmpty) return;
    await _client.postRaw<dynamic>(
      'product_materials',
      data: [
        for (final id in ids) {'product_id': productId, 'material_id': id},
      ],
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await _patchWhere(
      _client,
      'products',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'eq.$id'},
    );
  }

  @override
  Future<void> hardDelete(int id) async {
    await _deleteWhere(_client, 'products', {'id': 'eq.$id'});
  }

  @override
  Future<void> restore(int id) async {
    await _patchWhere(
        _client, 'products', {'deleted_at': null}, {'id': 'eq.$id'});
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return 0;
    return _patchWhere(
      _client,
      'products',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'in.(${ids.join(',')})'},
    );
  }

  Map<String, dynamic> _productBody(Product p) => {
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
        'category_id': p.categoryId,
        'manufacturer_id': p.manufacturerId,
      };
}

class ApiCategoryRepository implements CategoryRepository {
  final ApiClient _client;

  ApiCategoryRepository(this._client);

  @override
  Future<PageResult<Category>> find(
    CategoryQuery query, {
    CancelToken? cancelToken,
  }) async {
    final response = await _client.getRaw<dynamic>(
      'categories',
      queryParameters: {
        'select': '*',
        'order': _order(query.sortField, query.sortAscending),
        'limit': '${query.size}',
        'offset': '${(query.page - 1) * query.size}',
        ..._filters({'deleted_at': _deletedFilter(query.includeDeleted)}),
        if (_searchOr(query.search, ['name', 'description']) case final or?)
          'or': or,
      },
      headers: _countHeader,
      cancelToken: cancelToken,
    );
    final page = _readPage(response, page: query.page, size: query.size);
    return PageResult(
      items: [
        for (final row in page.rows)
          Category.fromJson(
              _categoryJson(Map<String, dynamic>.from(row as Map))),
      ],
      page: query.page,
      size: query.size,
      total: page.total,
    );
  }

  @override
  Future<Category?> findById(int id) async {
    final response = await _client.getRaw<dynamic>(
      'categories',
      queryParameters: {'select': '*', 'id': 'eq.$id', 'limit': '1'},
    );
    final rows = (response.data as List?) ?? const [];
    if (rows.isEmpty) return null;
    return Category.fromJson(
      _categoryJson(Map<String, dynamic>.from(rows.first as Map)),
    );
  }

  @override
  Future<int> create(Category category) async {
    final rows = await _insert(_client, 'categories', [
      {'name': category.name, 'description': category.description},
    ]);
    return ((rows.first as Map)['id'] as num).toInt();
  }

  @override
  Future<void> update(Category category) async {
    await _patchWhere(
      _client,
      'categories',
      {'name': category.name, 'description': category.description},
      {'id': 'eq.${category.id}'},
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await _patchWhere(
      _client,
      'categories',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'eq.$id'},
    );
  }

  @override
  Future<void> hardDelete(int id) async {
    await _deleteWhere(_client, 'categories', {'id': 'eq.$id'});
  }

  @override
  Future<void> restore(int id) async {
    await _patchWhere(
        _client, 'categories', {'deleted_at': null}, {'id': 'eq.$id'});
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return 0;
    return _patchWhere(
      _client,
      'categories',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'in.(${ids.join(',')})'},
    );
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
    final response = await _client.getRaw<dynamic>(
      'manufacturers',
      queryParameters: {
        'select': '*',
        'order': _order(query.sortField, query.sortAscending),
        'limit': '${query.size}',
        'offset': '${(query.page - 1) * query.size}',
        ..._filters({'deleted_at': _deletedFilter(query.includeDeleted)}),
        if (_searchOr(query.search, ['name', 'country']) case final or?)
          'or': or,
      },
      headers: _countHeader,
      cancelToken: cancelToken,
    );
    final page = _readPage(response, page: query.page, size: query.size);
    return PageResult(
      items: [
        for (final row in page.rows)
          Manufacturer.fromJson(
            _manufacturerJson(Map<String, dynamic>.from(row as Map)),
          ),
      ],
      page: query.page,
      size: query.size,
      total: page.total,
    );
  }

  @override
  Future<Manufacturer?> findById(int id) async {
    final response = await _client.getRaw<dynamic>(
      'manufacturers',
      queryParameters: {'select': '*', 'id': 'eq.$id', 'limit': '1'},
    );
    final rows = (response.data as List?) ?? const [];
    if (rows.isEmpty) return null;
    return Manufacturer.fromJson(
      _manufacturerJson(Map<String, dynamic>.from(rows.first as Map)),
    );
  }

  @override
  Future<int> create(Manufacturer manufacturer) async {
    final rows = await _insert(_client, 'manufacturers', [
      {
        'name': manufacturer.name,
        'country': manufacturer.country,
        'contact_email': manufacturer.contactEmail,
      },
    ]);
    return ((rows.first as Map)['id'] as num).toInt();
  }

  @override
  Future<void> update(Manufacturer manufacturer) async {
    await _patchWhere(
      _client,
      'manufacturers',
      {
        'name': manufacturer.name,
        'country': manufacturer.country,
        'contact_email': manufacturer.contactEmail,
      },
      {'id': 'eq.${manufacturer.id}'},
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await _patchWhere(
      _client,
      'manufacturers',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'eq.$id'},
    );
  }

  @override
  Future<void> hardDelete(int id) async {
    await _deleteWhere(_client, 'manufacturers', {'id': 'eq.$id'});
  }

  @override
  Future<void> restore(int id) async {
    await _patchWhere(
      _client,
      'manufacturers',
      {'deleted_at': null},
      {'id': 'eq.$id'},
    );
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return 0;
    return _patchWhere(
      _client,
      'manufacturers',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'in.(${ids.join(',')})'},
    );
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
    final response = await _client.getRaw<dynamic>(
      'materials',
      queryParameters: {
        'select': '*',
        'order': _order(query.sortField, query.sortAscending),
        'limit': '${query.size}',
        'offset': '${(query.page - 1) * query.size}',
        ..._filters({'deleted_at': _deletedFilter(query.includeDeleted)}),
        if (_searchOr(query.search, ['name', 'description']) case final or?)
          'or': or,
      },
      headers: _countHeader,
      cancelToken: cancelToken,
    );
    final page = _readPage(response, page: query.page, size: query.size);
    return PageResult(
      items: [
        for (final row in page.rows)
          FurnitureMaterial.fromJson(
            _materialJson(Map<String, dynamic>.from(row as Map)),
          ),
      ],
      page: query.page,
      size: query.size,
      total: page.total,
    );
  }

  @override
  Future<FurnitureMaterial?> findById(int id) async {
    final response = await _client.getRaw<dynamic>(
      'materials',
      queryParameters: {'select': '*', 'id': 'eq.$id', 'limit': '1'},
    );
    final rows = (response.data as List?) ?? const [];
    if (rows.isEmpty) return null;
    return FurnitureMaterial.fromJson(
      _materialJson(Map<String, dynamic>.from(rows.first as Map)),
    );
  }

  @override
  Future<int> create(FurnitureMaterial material) async {
    final rows = await _insert(_client, 'materials', [
      {'name': material.name, 'description': material.description},
    ]);
    return ((rows.first as Map)['id'] as num).toInt();
  }

  @override
  Future<void> update(FurnitureMaterial material) async {
    await _patchWhere(
      _client,
      'materials',
      {'name': material.name, 'description': material.description},
      {'id': 'eq.${material.id}'},
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await _patchWhere(
      _client,
      'materials',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'eq.$id'},
    );
  }

  @override
  Future<void> hardDelete(int id) async {
    await _deleteWhere(_client, 'materials', {'id': 'eq.$id'});
  }

  @override
  Future<void> restore(int id) async {
    await _patchWhere(
        _client, 'materials', {'deleted_at': null}, {'id': 'eq.$id'});
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return 0;
    return _patchWhere(
      _client,
      'materials',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'in.(${ids.join(',')})'},
    );
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
    final response = await _client.getRaw<dynamic>(
      'customers',
      queryParameters: {
        'select': '*,loyalty_cards(number,issued_at,tier,points)',
        'order': _order(query.sortField, query.sortAscending),
        'limit': '${query.size}',
        'offset': '${(query.page - 1) * query.size}',
        ..._filters({'deleted_at': _deletedFilter(query.includeDeleted)}),
        if (_searchOr(query.search, ['full_name', 'email', 'phone'])
            case final or?)
          'or': or,
      },
      headers: _countHeader,
      cancelToken: cancelToken,
    );
    final page = _readPage(response, page: query.page, size: query.size);
    return PageResult(
      items: [
        for (final row in page.rows)
          Customer.fromJson(
              _customerJson(Map<String, dynamic>.from(row as Map))),
      ],
      page: query.page,
      size: query.size,
      total: page.total,
    );
  }

  @override
  Future<Customer?> findById(int id) async {
    final response = await _client.getRaw<dynamic>(
      'customers',
      queryParameters: {
        'select': '*,loyalty_cards(number,issued_at,tier,points)',
        'id': 'eq.$id',
        'limit': '1',
      },
    );
    final rows = (response.data as List?) ?? const [];
    if (rows.isEmpty) return null;
    return Customer.fromJson(
      _customerJson(Map<String, dynamic>.from(rows.first as Map)),
    );
  }

  @override
  Future<int> create(Customer customer) async {
    final rows = await _insert(_client, 'customers', [_customerBody(customer)]);
    final id = ((rows.first as Map)['id'] as num).toInt();
    await _writeCard(id, customer.card);
    return id;
  }

  @override
  Future<void> update(Customer customer) async {
    await _patchWhere(
      _client,
      'customers',
      _customerBody(customer),
      {'id': 'eq.${customer.id}'},
    );
    await _deleteWhere(_client, 'loyalty_cards', {
      'customer_id': 'eq.${customer.id}',
    });
    await _writeCard(customer.id, customer.card);
  }

  Future<void> _writeCard(int customerId, CustomerCard? card) async {
    if (card == null) return;
    await _client.postRaw<dynamic>('loyalty_cards', data: [
      {
        'customer_id': customerId,
        'number': card.number,
        'issued_at': card.issuedAt,
        'tier': card.tier,
        'points': card.points,
      },
    ]);
  }

  @override
  Future<void> softDelete(int id) async {
    await _patchWhere(
      _client,
      'customers',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'eq.$id'},
    );
  }

  @override
  Future<void> hardDelete(int id) async {
    await _deleteWhere(_client, 'customers', {'id': 'eq.$id'});
  }

  @override
  Future<void> restore(int id) async {
    await _patchWhere(
        _client, 'customers', {'deleted_at': null}, {'id': 'eq.$id'});
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return 0;
    return _patchWhere(
      _client,
      'customers',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'in.(${ids.join(',')})'},
    );
  }

  Map<String, dynamic> _customerBody(Customer c) => {
        'full_name': c.fullName,
        'email': c.email,
        'phone': c.phone,
        'address': c.address,
      };
}

class ApiOrderRepository implements OrderRepository {
  final ApiClient _client;

  ApiOrderRepository(this._client);

  Map<String, dynamic> _itemJson(Map<String, dynamic> row) => {
        'id': row['id'],
        'orderId': row['order_id'],
        'productId': row['product_id'],
        'productName': row['product_name'],
        'quantity': row['quantity'],
        'price': row['price'],
      };

  Map<String, dynamic> _orderJson(Map<String, dynamic> row) => {
        'id': row['id'],
        'customerId': row['customer_id'],
        'customerName': row['customer_name'],
        'status': row['status'],
        'deliveryMethod': row['delivery_method'],
        'subtotal': row['subtotal'],
        'discountPercent': row['discount_percent'],
        'deliveryCost': row['delivery_cost'],
        'totalPrice': row['total_price'],
        'comment': row['comment'],
        'createdAt': row['created_at'],
        'deletedAt': row['deleted_at'],
        'items': [
          for (final item in (row['order_items'] as List?) ?? const [])
            _itemJson(Map<String, dynamic>.from(item as Map)),
        ],
      };

  @override
  Future<PageResult<Order>> find(
    OrderQuery query, {
    CancelToken? cancelToken,
  }) async {
    final response = await _client.getRaw<dynamic>(
      'orders',
      queryParameters: {
        'select': '*,order_items(*)',
        'order': _order(query.sortField, query.sortAscending),
        'limit': '${query.size}',
        'offset': '${(query.page - 1) * query.size}',
        ..._filters({
          'deleted_at': _deletedFilter(query.includeDeleted),
          'status': query.status == null ? null : 'eq.${query.status!.apiName}',
        }),
        if (_searchOr(query.search, ['customer_name', 'comment'])
            case final or?)
          'or': or,
      },
      headers: _countHeader,
      cancelToken: cancelToken,
    );
    final page = _readPage(response, page: query.page, size: query.size);
    return PageResult(
      items: [
        for (final row in page.rows)
          Order.fromJson(_orderJson(Map<String, dynamic>.from(row as Map))),
      ],
      page: query.page,
      size: query.size,
      total: page.total,
    );
  }

  @override
  Future<Order?> findById(int id) async {
    final response = await _client.getRaw<dynamic>(
      'orders',
      queryParameters: {
        'select': '*,order_items(*)',
        'id': 'eq.$id',
        'limit': '1',
      },
    );
    final rows = (response.data as List?) ?? const [];
    if (rows.isEmpty) return null;
    return Order.fromJson(
      _orderJson(Map<String, dynamic>.from(rows.first as Map)),
    );
  }

  @override
  Future<int> create(Order order, List<OrderItem> items) async {
    final rows = await _insert(_client, 'orders', [
      {
        'customer_id': order.customerId,
        'customer_name': order.customerName,
        'status': order.status.apiName,
        'delivery_method': order.deliveryMethod.apiName,
        'comment': order.comment,
      },
    ]);
    final id = ((rows.first as Map)['id'] as num).toInt();
    if (items.isNotEmpty) {
      await _client.postRaw<dynamic>('order_items', data: [
        for (final item in items)
          {
            'order_id': id,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'price': item.price,
          },
      ]);
    }
    return id;
  }

  @override
  Future<void> updateStatus(int id, OrderStatus status) async {
    await _patchWhere(
      _client,
      'orders',
      {'status': status.apiName},
      {'id': 'eq.$id'},
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await _patchWhere(
      _client,
      'orders',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'eq.$id'},
    );
  }

  @override
  Future<void> hardDelete(int id) async {
    await _deleteWhere(_client, 'orders', {'id': 'eq.$id'});
  }

  @override
  Future<void> restore(int id) async {
    await _patchWhere(
        _client, 'orders', {'deleted_at': null}, {'id': 'eq.$id'});
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return 0;
    return _patchWhere(
      _client,
      'orders',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'in.(${ids.join(',')})'},
    );
  }
}

class ApiReviewRepository implements ReviewRepository {
  final ApiClient _client;

  ApiReviewRepository(this._client);

  Map<String, dynamic> _json(Map<String, dynamic> row) => {
        'id': row['id'],
        'productId': row['product_id'],
        'customerId': row['customer_id'],
        'customerName': row['customer_name'],
        'rating': row['rating'],
        'text': row['text'],
        'createdAt': row['created_at'],
        'deletedAt': row['deleted_at'],
      };

  @override
  Future<List<Review>> findByProduct(int productId) async {
    final response = await _client.getRaw<dynamic>(
      'reviews',
      queryParameters: {
        'select': '*',
        'product_id': 'eq.$productId',
        'deleted_at': 'is.null',
        'order': 'created_at.desc',
      },
    );
    final rows = (response.data as List?) ?? const [];
    return [
      for (final row in rows)
        Review.fromJson(_json(Map<String, dynamic>.from(row as Map))),
    ];
  }

  @override
  Future<void> create(Review review) async {
    await _client.postRaw<dynamic>('reviews', data: [
      {
        'product_id': review.productId,
        'customer_id': review.customerId,
        'customer_name': review.customerName,
        'rating': review.rating,
        'text': review.text,
      },
    ]);
  }

  @override
  Future<void> softDelete(int id) async {
    await _patchWhere(
      _client,
      'reviews',
      {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      {'id': 'eq.$id'},
    );
  }

  @override
  Future<void> hardDelete(int id) async {
    await _deleteWhere(_client, 'reviews', {'id': 'eq.$id'});
  }

  @override
  Future<void> restore(int id) async {
    await _patchWhere(
        _client, 'reviews', {'deleted_at': null}, {'id': 'eq.$id'});
  }
}

class ApiStatsRepository implements StatsRepository {
  final ApiClient _client;

  ApiStatsRepository(this._client);

  @override
  Future<ShopStats> shop() async {
    final response = await _client.getRaw<dynamic>(
      'v_shop_stats',
      queryParameters: const {'select': '*'},
    );
    final rows = (response.data as List?) ?? const [];
    if (rows.isEmpty) return const ShopStats();
    return ShopStats.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  @override
  Future<List<CategoryStat>> categories() async {
    final response = await _client.getRaw<dynamic>(
      'v_category_stats',
      queryParameters: const {'select': '*'},
    );
    final rows = (response.data as List?) ?? const [];
    return [
      for (final row in rows)
        CategoryStat.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
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
    return [
      for (final c in _categoryRows)
        if (!c.isDeleted) c
    ];
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
    return [
      for (final m in _manufacturerRows)
        if (!m.isDeleted) m
    ];
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
    return [
      for (final m in _materialRows)
        if (!m.isDeleted) m
    ];
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
