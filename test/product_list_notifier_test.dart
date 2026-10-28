import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/core/api_exceptions.dart';
import 'package:mebel_web/models/page_result.dart';
import 'package:mebel_web/models/product.dart';
import 'package:mebel_web/models/product_query.dart';
import 'package:mebel_web/repositories/repositories.dart';
import 'package:mebel_web/state/load_status.dart';
import 'package:mebel_web/state/product_list_notifier.dart';

class _FakeProductRepository implements ProductRepository {
  int calls = 0;
  int active = 0;
  int maxActive = 0;
  bool failNext = false;
  Duration delay = const Duration(milliseconds: 20);

  @override
  Future<PageResult<Product>> find(
    ProductQuery query, {
    CancelToken? cancelToken,
  }) async {
    calls++;
    active++;
    if (active > maxActive) maxActive = active;
    try {
      await Future<void>.delayed(delay);
      if (cancelToken?.isCancelled ?? false) {
        throw const ApiCancelled();
      }
      if (failNext) {
        failNext = false;
        throw const NetworkException();
      }
      return PageResult<Product>(
        items: [
          Product(
            id: query.page,
            name: 'Товар ${query.page}',
            price: 100,
            categoryId: 1,
            manufacturerId: 1,
          ),
        ],
        page: query.page,
        size: query.size,
        total: 25,
      );
    } finally {
      active--;
    }
  }

  @override
  Future<int> create(Product product) async => 1;

  @override
  Future<int> deleteMany(List<int> ids) async => ids.length;

  @override
  Future<void> hardDelete(int id) async {}

  @override
  Future<void> restore(int id) async {}

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> update(Product product) async {}

  @override
  Future<Product?> findById(int id) async => null;
}

void main() {
  test('смена страницы загружает новую страницу и не залипает', () async {
    final repo = _FakeProductRepository();
    final notifier = ProductListNotifier(repo);

    await notifier.applyQueryIfChanged(const ProductQuery());
    expect(notifier.status, LoadStatus.success);
    expect(notifier.result.page, 1);

    await notifier.applyQueryIfChanged(const ProductQuery(page: 2));
    expect(notifier.status, LoadStatus.success);
    expect(notifier.result.page, 2);
    expect(repo.calls, 2);
  });

  test('отменённый запрос не оставляет состояние загрузки', () async {
    final repo = _FakeProductRepository();
    final notifier = ProductListNotifier(repo);

    final first = notifier.load();
    final second = notifier.load();
    await Future.wait([first, second]);

    expect(notifier.status, LoadStatus.success);
    expect(notifier.result.page, 1);
    expect(repo.maxActive, 2);
  });

  test('ошибка показывается, повтор загружает список', () async {
    final repo = _FakeProductRepository()..failNext = true;
    final notifier = ProductListNotifier(repo);

    await notifier.load();
    expect(notifier.status, LoadStatus.error);
    expect(notifier.error, contains('Не удалось загрузить'));

    await notifier.refresh();
    expect(notifier.status, LoadStatus.success);
  });

  test('после сохранения список перечитывается, хотя запрос тот же', () async {
    final repo = _FakeProductRepository();
    final notifier = ProductListNotifier(repo);

    await notifier.applyQueryIfChanged(const ProductQuery());
    expect(repo.calls, 1);

    await notifier.applyQueryIfChanged(const ProductQuery());
    expect(repo.calls, 1);

    notifier.invalidate();
    await notifier.applyQueryIfChanged(const ProductQuery());
    expect(repo.calls, 2);
    expect(notifier.status, LoadStatus.success);
  });

  test('новую страницу нельзя открыть дальше последней', () async {
    final repo = _FakeProductRepository();
    final notifier = ProductListNotifier(repo);

    await notifier.applyQueryIfChanged(const ProductQuery(page: 3));
    expect(notifier.result.hasNext, isFalse);
    expect(notifier.result.hasPrevious, isTrue);
  });
}
