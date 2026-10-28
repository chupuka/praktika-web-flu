import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../repositories/repositories.dart';
import 'load_status.dart';

class ProductListNotifier extends ChangeNotifier {
  final ProductRepository _repository;

  ProductListNotifier(this._repository);

  ProductQuery _query = const ProductQuery();
  PageResult<Product> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  Timer? _searchTimer;
  CancelToken? _cancelToken;
  int _generation = 0;
  Timer? _watchdog;
  bool _stale = false;

  ProductQuery get query => _query;
  PageResult<Product> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    final generation = ++_generation;
    _cancelToken?.cancel('superseded');
    final token = CancelToken();
    _cancelToken = token;
    _status = LoadStatus.loading;
    _error = null;
    _watchdog?.cancel();
    final watchdog = Timer(const Duration(seconds: 30), () {
      if (generation != _generation || _status != LoadStatus.loading) return;
      _status = LoadStatus.error;
      _error = 'Сервер не ответил вовремя. Нажмите «Повторить»';
      notifyListeners();
    });
    _watchdog = watchdog;
    notifyListeners();
    try {
      final result = await _repository.find(_query, cancelToken: token);
      if (generation != _generation) return;
      _result = result;
      _status = LoadStatus.success;
    } on ApiCancelled catch (_) {
      if (generation != _generation) return;
      _status = LoadStatus.error;
      _error = 'Запрос отменён. Нажмите «Повторить»';
    } catch (e) {
      if (generation != _generation) return;
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    } finally {
      watchdog.cancel();
    }
    notifyListeners();
  }

  Future<void> applyQuery(ProductQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  Future<void> refresh() async {
    await load();
  }

  void invalidate() {
    _stale = true;
  }

  Future<void> applyQueryIfChanged(ProductQuery next) async {
    if (next == _query && _status != LoadStatus.idle && !_stale) return;
    _stale = false;
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
    _watchdog?.cancel();
    _cancelToken?.cancel('disposed');
    super.dispose();
  }
}
