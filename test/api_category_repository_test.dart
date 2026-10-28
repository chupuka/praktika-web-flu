import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/core/api_client.dart';
import 'package:mebel_web/core/api_exceptions.dart';
import 'package:mebel_web/models/category.dart';
import 'package:mebel_web/models/category_query.dart';
import 'package:mebel_web/models/page_result.dart';
import 'package:mebel_web/models/product_query.dart';
import 'package:mebel_web/repositories/api_repositories.dart';

import 'support/mock_adapter.dart';

void main() {
  late MockAdapter adapter;
  late ApiClient client;
  late ApiCategoryRepository categories;

  Map<String, dynamic> categoryJson({
    int id = 1,
    String name = 'Диваны и кресла',
  }) {
    return {
      'id': id,
      'name': name,
      'description': 'Мягкая мебель',
      'deletedAt': null,
    };
  }

  Map<String, dynamic> page(List<Map<String, dynamic>> items, int total) {
    return {
      'items': items,
      'page': 1,
      'size': 10,
      'total': total,
      'totalPages': 1,
    };
  }

  setUp(() {
    adapter = MockAdapter();
    client = ApiClient();
    client.dio.httpClientAdapter = adapter;
    categories = ApiCategoryRepository(client);
  });

  test('список категорий приходит с сервера', () async {
    adapter.enqueueJson(
      200,
      page([categoryJson(), categoryJson(id: 2, name: 'Столы и стулья')], 8),
    );

    final result = await categories.find(const CategoryQuery());

    expect(result.total, 8);
    expect(result.items.length, 2);
    expect(result.items.first.name, 'Диваны и кресла');
  });

  test('поиск уходит на сервер параметром search', () async {
    adapter.enqueueJson(200, page([categoryJson(id: 4)], 1));

    await categories.find(const CategoryQuery(search: 'шкаф'));

    expect(adapter.requests.single.query['search'], 'шкаф');
  });

  test('создание категории возвращает идентификатор', () async {
    adapter.enqueueJson(201, categoryJson(id: 9, name: 'Свободная'));

    final id = await categories.create(
      const Category(id: 0, name: 'Свободная'),
    );

    expect(id, 9);
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, '/categories');
  });

  test('дубликат имени даёт 422 с полем name', () async {
    adapter.enqueueJson(422, {
      'message': 'Ошибка валидации',
      'errors': {'name': 'Такая категория уже существует'},
    });

    await expectLater(
      categories.create(const Category(id: 0, name: 'Диваны и кресла')),
      throwsA(
        isA<ValidationException>().having(
            (e) => e.errorFor('name'), 'name', contains('уже существует')),
      ),
    );
  });

  test('сервер недоступен приводит к NetworkException', () async {
    adapter.enqueueError(
      DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
        error: 'Сервер не отвечает',
      ),
    );

    await expectLater(
      categories.find(const CategoryQuery()),
      throwsA(isA<NetworkException>()),
    );
  });

  test('смена фильтра возвращает на первую страницу', () {
    const q = ProductQuery(page: 7);
    final next = q.copyWith(search: 'диван');
    expect(next.page, 1);
    expect(next.search, 'диван');
  });

  test('сброс фильтра через null', () {
    const q = ProductQuery(categoryId: 2, page: 3);
    final next = q.copyWith(categoryId: null);
    expect(next.categoryId, isNull);
    expect(next.page, 1);
  });

  test('параметры адреса переживают путь туда и обратно', () {
    const q = ProductQuery(
      search: 'стол',
      categoryId: 2,
      priceFrom: 10000,
      priceTo: 40000,
      inStockOnly: true,
      sortField: 'price',
      sortAscending: false,
      page: 2,
      size: 25,
    );
    final restored = ProductQuery.fromParameters(q.toParameters());
    expect(restored, q);
  });

  test('число страниц считается вверх', () {
    const full = PageResult<int>(
      items: [1, 2],
      page: 1,
      size: 10,
      total: 22,
    );
    expect(full.totalPages, 3);
    expect(full.hasNext, isTrue);
    expect(full.hasPrevious, isFalse);
    expect(PageResult<int>.empty().totalPages, 1);
  });
}
