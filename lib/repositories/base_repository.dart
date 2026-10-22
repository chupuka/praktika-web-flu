import '../data/json_store.dart';
import '../models/page_result.dart';

typedef RowMapper<T> = Map<String, dynamic> Function(T item);
typedef RowParser<T> = T Function(Map<String, dynamic> json);
typedef RowFilter<T> = bool Function(T item);
typedef RowComparator<T> = int Function(T a, T b);
typedef IdOf<T> = int Function(T item);
typedef DeletedSetter<T> = T Function(T item, DateTime? deletedAt);

class BaseRepository<T> {
  final JsonStore _store;
  final String _key;
  final List<T> _seed;
  final RowMapper<T> _toJson;
  final RowParser<T> _fromJson;
  final IdOf<T> _idOf;
  final DeletedSetter<T> _withDeletedAt;

  List<T> _rows = [];

  BaseRepository({
    required JsonStore store,
    required String key,
    required List<T> seed,
    required RowMapper<T> toJson,
    required RowParser<T> fromJson,
    required IdOf<T> idOf,
    required DeletedSetter<T> withDeletedAt,
  })  : _store = store,
        _key = key,
        _seed = seed,
        _toJson = toJson,
        _fromJson = fromJson,
        _idOf = idOf,
        _withDeletedAt = withDeletedAt {
    _restore();
  }

  List<T> get rows => List.unmodifiable(_rows);

  void _restore() {
    if (!_store.has(_key)) {
      _rows = List.of(_seed);
      _persist();
      return;
    }
    final decoded = _store.read(_key);
    if (decoded.isEmpty && _seed.isNotEmpty) {
      _rows = List.of(_seed);
      _persist();
      return;
    }
    _rows = [for (final json in decoded) _fromJson(json)];
  }

  Future<void> _persist() {
    return _store.write(_key, [for (final row in _rows) _toJson(row)]);
  }

  T? findByIdSync(int id) {
    for (final row in _rows) {
      if (_idOf(row) == id) return row;
    }
    return null;
  }

  Future<PageResult<T>> find({
    required RowFilter<T> filter,
    required RowComparator<T> comparator,
    required int page,
    required int size,
    bool includeDeleted = false,
    RowFilter<T>? isDeleted,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final deleted = isDeleted ?? _neverDeleted<T>;

    var result = _rows.where((row) {
      if (!includeDeleted && deleted(row)) return false;
      return filter(row);
    }).toList();

    result.sort(comparator);

    final total = result.length;
    final from = (page - 1) * size;
    final to = (from + size) > total ? total : (from + size);
    final items = from >= total ? <T>[] : result.sublist(from, to);
    return PageResult(items: items, page: page, size: size, total: total);
  }

  Future<void> add(T item) async {
    _rows.add(item);
    await _persist();
  }

  Future<void> update(T item) async {
    final index = _rows.indexWhere((row) => _idOf(row) == _idOf(item));
    if (index == -1) throw StateError('Запись ${_idOf(item)} не найдена');
    _rows[index] = item;
    await _persist();
  }

  Future<void> softDelete(int id, DateTime when) async {
    final index = _rows.indexWhere((row) => _idOf(row) == id);
    if (index == -1) throw StateError('Запись $id не найдена');
    _rows[index] = _withDeletedAt(_rows[index], when);
    await _persist();
  }

  Future<void> hardDelete(int id) async {
    _rows.removeWhere((row) => _idOf(row) == id);
    await _persist();
  }

  Future<void> restore(int id) async {
    final index = _rows.indexWhere((row) => _idOf(row) == id);
    if (index == -1) throw StateError('Запись $id не найдена');
    _rows[index] = _withDeletedAt(_rows[index], null);
    await _persist();
  }

  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final index = _rows.indexWhere((row) => _idOf(row) == id);
      if (index == -1) continue;
      if (_rows[index] == null) continue;
      _rows[index] = _withDeletedAt(_rows[index], DateTime.now());
      count++;
    }
    await _persist();
    return count;
  }

  int nextId() {
    var max = 0;
    for (final row in _rows) {
      final id = _idOf(row);
      if (id > max) max = id;
    }
    return max + 1;
  }

  int countLive(RowFilter<T> predicate) {
    var count = 0;
    for (final row in _rows) {
      if (predicate(row)) count++;
    }
    return count;
  }
}

bool _neverDeleted<T>(T item) => false;
