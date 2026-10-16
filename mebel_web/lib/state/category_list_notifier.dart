import 'dart:async';

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/category_query.dart';
import '../models/page_result.dart';
import '../models/product_query.dart';
import '../repositories/repositories.dart';
import 'load_status.dart';

class CategoryListNotifier extends ChangeNotifier {
  final CategoryRepository _repository;
  final ProductRepository _products;

  CategoryListNotifier(this._repository, this._products);

  CategoryQuery _query = const CategoryQuery();
  PageResult<Category> _result = PageResult.empty();
  Map<int, int> _counts = {};
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  Timer? _searchTimer;

  CategoryQuery get query => _query;
  PageResult<Category> get result => _result;
  Map<int, int> get counts => _counts;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      final all = await _products.find(const ProductQuery(size: 1000));
      final counts = <int, int>{};
      for (final p in all.items) {
        if (!p.isDeleted) counts[p.categoryId] = (counts[p.categoryId] ?? 0) + 1;
      }
      _counts = counts;
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(CategoryQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  Future<void> applyQueryIfChanged(CategoryQuery next) async {
    if (next == _query && _status != LoadStatus.idle) return;
    await applyQuery(next);
  }

  void searchSoon(String text) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      applyQuery(_query.copyWith(search: text));
    });
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void selectAll(Iterable<int> ids) {
    _selected.addAll(ids);
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
