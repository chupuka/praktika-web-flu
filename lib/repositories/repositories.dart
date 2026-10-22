import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show Listenable;

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

abstract interface class ProductRepository {
  Future<PageResult<Product>> find(
    ProductQuery query, {
    CancelToken? cancelToken,
  });
  Future<Product?> findById(int id);
  Future<int> create(Product product);
  Future<void> update(Product product);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

abstract interface class CategoryRepository {
  Future<PageResult<Category>> find(
    CategoryQuery query, {
    CancelToken? cancelToken,
  });
  Future<Category?> findById(int id);
  Future<int> create(Category category);
  Future<void> update(Category category);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

abstract interface class ManufacturerRepository {
  Future<PageResult<Manufacturer>> find(
    ManufacturerQuery query, {
    CancelToken? cancelToken,
  });
  Future<Manufacturer?> findById(int id);
  Future<int> create(Manufacturer manufacturer);
  Future<void> update(Manufacturer manufacturer);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

abstract interface class MaterialRepository {
  Future<PageResult<FurnitureMaterial>> find(
    MaterialQuery query, {
    CancelToken? cancelToken,
  });
  Future<FurnitureMaterial?> findById(int id);
  Future<int> create(FurnitureMaterial material);
  Future<void> update(FurnitureMaterial material);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

abstract interface class CustomerRepository {
  Future<PageResult<Customer>> find(
    CustomerQuery query, {
    CancelToken? cancelToken,
  });
  Future<Customer?> findById(int id);
  Future<int> create(Customer customer);
  Future<void> update(Customer customer);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

abstract interface class ReferenceRepository implements Listenable {
  List<Category> categories();
  String categoryName(int id);
  List<Manufacturer> manufacturers();
  String manufacturerName(int id);
  List<FurnitureMaterial> materials();
  List<String> materialNames(List<int> ids);
  int countProductsByCategory(int categoryId);
  int countProductsByManufacturer(int manufacturerId);
  int countProductsByMaterial(int materialId);
  Future<void> refresh();
  Future<void> ensureLoaded();
}
