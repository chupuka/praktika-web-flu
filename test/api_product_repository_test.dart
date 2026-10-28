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

  Map<String, dynamic> productJson({
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
      'categoryId': categoryId,
      'manufacturerId': 2,
      'materialIds': [6, 4],
      'category': {'id': categoryId, 'name': 'Диваны и кресла'},
      'manufacturer': {'id': 2, 'name': 'Hoff'},
      'materials': [
        {'id': 6, 'name': 'Микрофибра'},
        {'id': 4, 'name': 'Металл'},
      ],
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
    repo = ApiProductRepository(client);
  });

  test('список товаров разбирается в PageResult', () async {
    adapter.enqueueJson(200, page([productJson()], 1));

    final result = await repo.find(const ProductQuery());

    expect(result.total, 1);
    expect(result.items.single.name, 'Диван-кровать «Уют»');
    expect(result.items.single.materialIds, [6, 4]);
  });

  test('запрос уходит с параметрами фильтра', () async {
    adapter.enqueueJson(200, page([], 0));

    await repo.find(
      const ProductQuery(search: 'диван', categoryId: 1, size: 25),
    );

    final request = adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.path, '/products');
    expect(request.query['search'], 'диван');
    expect(request.query['categoryId'], '1');
    expect(request.query['size'], '25');
  });

  test('токен подставляется в заголовок авторизации', () async {
    client.setAccessToken('токен-123');
    adapter.enqueueJson(200, page([], 0));

    await repo.find(const ProductQuery());

    expect(
        adapter.requests.single.headers['Authorization'], 'Bearer токен-123');
  });

  test('ответ 422 превращается в ValidationException с полями', () async {
    adapter.enqueueJson(422, {
      'message': 'Ошибка валидации',
      'errors': {'sku': 'Товар с таким артикулом уже существует'},
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
            .having((e) => e.errorFor('sku'), 'sku', contains('уже существует'))
            .having((e) => e.fieldErrors.length, 'fieldErrors', 1),
      ),
    );
  });

  test('ответ 409 превращается в ConflictException', () async {
    adapter.enqueueJson(
        409, {'message': 'Нельзя удалить: к категории привязано товаров — 4'});

    await expectLater(
      repo.softDelete(1),
      throwsA(
        isA<ConflictException>().having(
          (e) => e.message,
          'message',
          contains('привязано товаров'),
        ),
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
    adapter.enqueueJson(201, productJson(id: 23, name: 'Тестовый стул'));

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
    expect(request.path, '/products');
    expect((request.data as Map)['sku'], 'MB-999');
  });

  test('жёсткое удаление запрашивает параметр hard', () async {
    adapter.enqueue(const MockResponse(204));

    await repo.hardDelete(5);

    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.path, '/products/5');
    expect(request.query['hard'], 'true');
  });

  test('восстановление идёт отдельным маршрутом', () async {
    adapter.enqueueJson(200, productJson());

    await repo.restore(5);

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/products/5/restore');
  });

  test('множественное удаление возвращает число удалённых', () async {
    adapter.enqueueJson(200, {'deleted': 2});

    final count = await repo.deleteMany([1, 2, 3]);

    expect(count, 2);
    expect(adapter.requests.single.path, '/products/bulk-delete');
  });

  test('несуществующий товар даёт null, а не исключение', () async {
    adapter.enqueueJson(404, {'message': 'Объект не найден'});

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
