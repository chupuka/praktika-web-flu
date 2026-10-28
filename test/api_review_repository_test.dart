import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/core/api_client.dart';
import 'package:mebel_web/models/review.dart';
import 'package:mebel_web/repositories/api_repositories.dart';

import 'support/mock_adapter.dart';

void main() {
  late MockAdapter adapter;
  late ApiClient client;
  late ApiReviewRepository repo;

  setUp(() {
    adapter = MockAdapter();
    client = ApiClient();
    client.dio.httpClientAdapter = adapter;
    repo = ApiReviewRepository(client);
  });

  test('отзывы товара приходят с сервера по убыванию даты', () async {
    adapter.enqueueJson(200, [
      {
        'id': 2,
        'product_id': 5,
        'customer_id': 1,
        'customer_name': 'Мария',
        'rating': 5,
        'text': 'Отличный диван',
        'created_at': '2026-10-28T13:49:36.711Z',
        'deleted_at': null,
      },
    ]);

    final reviews = await repo.findByProduct(5);

    expect(reviews.single.rating, 5);
    expect(adapter.requests.single.query['product_id'], 'eq.5');
    expect(adapter.requests.single.query['order'], 'created_at.desc');
    expect(adapter.requests.single.query['deleted_at'], 'is.null');
  });

  test('новый отзыв отправляется одной строкой', () async {
    adapter.enqueueJson(201, []);

    await repo.create(
      const Review(
        productId: 5,
        customerId: 1,
        customerName: 'Мария',
        rating: 4,
        text: 'Хорошая мебель',
      ),
    );

    final data = (adapter.requests.single.data as List).single as Map;
    expect(data['product_id'], 5);
    expect(data['rating'], 4);
  });

  test('удаление отзыва мягкое', () async {
    adapter.enqueueJson(200, []);

    await repo.softDelete(9);

    expect((adapter.requests.single.data as Map)['deleted_at'], isNotNull);
    expect(adapter.requests.single.query['id'], 'eq.9');
  });
}
