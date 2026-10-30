import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/core/api_client.dart';
import 'package:mebel_web/core/api_exceptions.dart';
import 'package:mebel_web/models/product.dart';
import 'package:mebel_web/models/product_query.dart';
import 'package:mebel_web/repositories/api_repositories.dart';

import 'support/mock_adapter.dart';

void main() {
  late MockAdapter adapter;
  late ApiClient client;
  late ApiProductRepository repo;

  Map<String, dynamic> productRow({
    int id = 1,
    String name = 'Диван-кровать «Уют»',
    String sku = 'MB-001',
    double price = 45990,
    int stock = 15,
    int categoryId = 1,
  }) {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'description': 'Описание',
      'style': 'modern',
      'price': price,
      'stock': stock,
      'width': 200,
      'depth': 90,
      'height': 85,
      'weight': 45,
      'color': 'Серый',
      'category_id': categoryId,
      'manufacturer_id': 2,
      'created_at': '2026-10-28T13:49:36.711Z',
      'deleted_at': null,
      'product_materials': [
        {'material_id': 6},
        {'material_id': 4},
      ],
    };
  }

  MockResponse listResponse(List<Map<String, dynamic>> rows, int total) {
    return MockResponse(
      200,
      body: rows,
      headers: {
        'content-range': ['0-${rows.length - 1}/$total'],
      },
    );
  }

  setUp(() {
    adapter = MockAdapter();
    client = ApiClient();
    client.dio.httpClientAdapter = adapter;
    repo = ApiProductRepository(client);
  });

  test('список товаров разбирается в PageResult', () async {
    adapter.enqueue(listResponse([productRow()], 1));

    final result = await repo.find(const ProductQuery());

    expect(result.total, 1);
    expect(result.items.single.name, 'Диван-кровать «Уют»');
    expect(result.items.single.materialIds, [6, 4]);
  });

  test('запрос уходит с параметрами фильтра и сортировки', () async {
    adapter.enqueue(listResponse([], 0));

    await repo.find(
      const ProductQuery(search: 'диван', categoryId: 1, size: 25),
    );

    final request = adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.path, 'products');
    expect(request.query['category_id'], 'eq.1');
    expect(request.query['limit'], '25');
    expect(request.query['or'], contains('name.ilike.*диван*'));
    expect(request.query['order'], 'name.asc');
    expect(request.headers['Prefer'], 'count=exact');
  });

  test('токен подставляется в заголовок авторизации', () async {
    client.setAccessToken('токен-123');
    adapter.enqueue(listResponse([], 0));

    await repo.find(const ProductQuery());

    expect(
        adapter.requests.single.headers['Authorization'], 'Bearer токен-123');
  });

  test('дубликат артикула превращается в ValidationException с полем',
      () async {
    adapter.enqueueJson(409, {
      'code': '23505',
      'message':
          'duplicate key value violates unique constraint "products_sku_key"',
      'details': 'Key (sku)=(MB-001) already exists.',
    });

    await expectLater(
      repo.create(
        const Product(
          id: 0,
          name: 'Стул',
          sku: 'MB-001',
          price: 1000,
          categoryId: 2,
          manufacturerId: 1,
        ),
      ),
      throwsA(
        isA<ValidationException>()
            .having((e) => e.errorFor('sku'), 'sku', contains('используется'))
            .having((e) => e.fieldErrors.length, 'fieldErrors', 1),
      ),
    );
  });

  test('нарушение внешнего ключа даёт ConflictException', () async {
    adapter.enqueueJson(409, {
      'code': '23503',
      'message':
          'update or delete on table "categories" violates foreign key constraint',
    });

    await expectLater(
      repo.softDelete(1),
      throwsA(isA<ConflictException>()),
    );
  });

  test('ошибка проверки поля даёт ValidationException', () async {
    adapter.enqueueJson(400, {
      'code': '23514',
      'message':
          'new row for relation "products" violates check constraint "products_price_check"',
    });

    await expectLater(
      repo.create(
        const Product(
          id: 0,
          name: 'Стул',
          sku: 'MB-002',
          price: 10,
          categoryId: 2,
          manufacturerId: 1,
        ),
      ),
      throwsA(
        isA<ValidationException>()
            .having((e) => e.errorFor('price'), 'price', isNotNull),
      ),
    );
  });

  test('ответ 401 превращается в UnauthorizedException', () async {
    adapter.enqueueJson(401, {'message': 'Требуется аутентификация'});

    await expectLater(
      repo.find(const ProductQuery()),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('недоступный сервер даёт NetworkException', () async {
    adapter.enqueueError(
      DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
        error: 'Сервер не отвечает',
      ),
    );

    await expectLater(
      repo.find(const ProductQuery()),
      throwsA(isA<NetworkException>()),
    );
  });

  test('повтор при недоступности сервера ограничен тремя попытками', () async {
    for (var i = 0; i < 3; i++) {
      adapter.enqueueError(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
          error: 'Сервер не отвечает',
        ),
      );
    }

    await expectLater(
      repo.find(const ProductQuery()),
      throwsA(isA<NetworkException>()),
    );
    expect(adapter.requests.length, 3);
  });

  test('создание товара возвращает идентификатор с сервера', () async {
    adapter.enqueueJson(201, [productRow(id: 23, name: 'Тестовый стул')]);

    final id = await repo.create(
      const Product(
        id: 0,
        name: 'Тестовый стул',
        sku: 'MB-999',
        price: 1000,
        categoryId: 2,
        manufacturerId: 1,
      ),
    );

    expect(id, 23);
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, 'products');
    expect((request.data as List).first['sku'], 'MB-999');
    expect((request.data as List).first['category_id'], 2);
  });

  test('материалы сохраняются отдельными строками связи', () async {
    adapter.enqueueJson(201, [productRow(id: 24)]);
    adapter.enqueueJson(201, const []);

    await repo.create(
      const Product(
        id: 0,
        name: 'Стол',
        sku: 'MB-500',
        price: 1000,
        categoryId: 1,
        manufacturerId: 1,
        materialIds: [1, 2],
      ),
    );

    expect(adapter.requests.length, 2);
    final linkRequest = adapter.requests[1];
    expect(linkRequest.path, 'product_materials');
    expect((linkRequest.data as List).length, 2);
  });

  test('жёсткое удаление удаляет строку по идентификатору', () async {
    adapter.enqueue(const MockResponse(204));

    await repo.hardDelete(5);

    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.path, 'products');
    expect(request.query['id'], 'eq.5');
  });

  test('жёсткое удаление не падает на пустом ответе сервера', () async {
    adapter.enqueueJson(204, '');

    await repo.hardDelete(6);

    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.query['id'], 'eq.6');
  });

  test('восстановление очищает дату удаления', () async {
    adapter.enqueueJson(200, [productRow()]);

    await repo.restore(5);

    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.path, 'products');
    expect(request.query['id'], 'eq.5');
    expect((request.data as Map)['deleted_at'], isNull);
  });

  test('множественное удаление возвращает число изменённых строк', () async {
    adapter.enqueueJson(200, [
      {'id': 1},
      {'id': 2},
    ]);

    final count = await repo.deleteMany([1, 2, 3]);

    expect(count, 2);
    expect(adapter.requests.single.query['id'], 'in.(1,2,3)');
  });

  test('несуществующий товар даёт null, а не исключение', () async {
    adapter.enqueue(listResponse([], 0));

    final found = await repo.findById(999);

    expect(found, isNull);
  });

  test('отменённый запрос не превращается в ошибку сети', () async {
    adapter.enqueueError(
      DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.cancel,
          error: 'отменён'),
    );

    await expectLater(
      repo.find(const ProductQuery()),
      throwsA(isA<ApiCancelled>()),
    );
  });
}
