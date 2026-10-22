import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../models/category.dart';
import '../models/category_query.dart';
import '../models/page_result.dart';
import '../repositories/repositories.dart';
import 'load_status.dart';

class CategoryListNotifier extends ChangeNotifier {
  final CategoryRepository _repository;

  CategoryListNotifier(this._repository);

  CategoryQuery _query = const CategoryQuery();
  PageResult<Category> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  Timer? _searchTimer;
  CancelToken? _cancelToken;

  CategoryQuery get query => _query;
  PageResult<Category> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _cancelToken?.cancel('superseded');
    final token = CancelToken();
    _cancelToken = token;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query, cancelToken: token);
      _status = LoadStatus.success;
    } on ApiCancelled catch (_) {
      return;
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
    _cancelToken?.cancel('disposed');
    super.dispose();
  }
}
