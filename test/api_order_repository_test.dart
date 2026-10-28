import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/core/api_client.dart';
import 'package:mebel_web/models/order.dart';
import 'package:mebel_web/models/order_query.dart';
import 'package:mebel_web/repositories/api_repositories.dart';

import 'support/mock_adapter.dart';

void main() {
  late MockAdapter adapter;
  late ApiClient client;
  late ApiOrderRepository repo;

  Map<String, dynamic> orderRow({
    int id = 1,
    String status = 'new',
    String customer = 'Иванова Мария Петровна',
    double total = 0,
  }) {
    return {
      'id': id,
      'customer_id': 1,
      'customer_name': customer,
      'status': status,
      'delivery_method': 'pickup',
      'subtotal': 10000,
      'discount_percent': 10,
      'delivery_cost': 0,
      'total_price': total == 0 ? 9000 : total,
      'comment': '',
      'created_at': '2026-10-28T13:49:36.711Z',
      'deleted_at': null,
      'order_items': [
        {
          'id': 1,
          'order_id': id,
          'product_id': 1,
          'product_name': 'Диван',
          'quantity': 2,
          'price': 5000,
        },
      ],
    };
  }

  setUp(() {
    adapter = MockAdapter();
    client = ApiClient();
    client.dio.httpClientAdapter = adapter;
    repo = ApiOrderRepository(client);
  });

  test('список заказов разбирается вместе с позициями', () async {
    adapter.enqueue(MockResponse(
      200,
      body: [orderRow()],
      headers: {
        'content-range': ['0-0/1'],
      },
    ));

    final result = await repo.find(const OrderQuery());

    expect(result.total, 1);
    expect(result.items.single.customerName, 'Иванова Мария Петровна');
    expect(result.items.single.items.single.total, 10000);
    expect(result.items.single.discountPercent, 10);
  });

  test('фильтр по статусу уходит на сервер', () async {
    adapter.enqueueJson(200, []);

    await repo.find(const OrderQuery(status: OrderStatus.processing));

    expect(adapter.requests.single.query['status'], 'eq.processing');
  });

  test('создание заказа отправляет шапку и позиции', () async {
    adapter.enqueueJson(201, [orderRow(id: 7)]);
    adapter.enqueueJson(201, []);

    final id = await repo.create(
      const Order(customerId: 1, customerName: 'Мария'),
      const [
        OrderItem(productId: 3, productName: 'Стол', quantity: 2, price: 4000),
      ],
    );

    expect(id, 7);
    expect(adapter.requests.length, 2);
    expect(adapter.requests[0].path, 'orders');
    expect(adapter.requests[1].path, 'order_items');
    expect((adapter.requests[1].data as List).single['quantity'], 2);
  });

  test('смена статуса обновляет строку заказа', () async {
    adapter.enqueueJson(200, [orderRow(status: 'delivered')]);

    await repo.updateStatus(7, OrderStatus.delivered);

    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.query['id'], 'eq.7');
    expect((request.data as Map)['status'], 'delivered');
  });

  test('мягкое удаление ставит дату, восстановление очищает', () async {
    adapter.enqueueJson(200, [orderRow()]);
    adapter.enqueueJson(200, [orderRow()]);

    await repo.softDelete(3);
    await repo.restore(3);

    expect((adapter.requests[0].data as Map)['deleted_at'], isNotNull);
    expect((adapter.requests[1].data as Map)['deleted_at'], isNull);
  });

  test('идентификатор заказа переживает адрес', () {
    const query = OrderQuery(
      search: 'мария',
      status: OrderStatus.shipped,
      page: 2,
      size: 25,
    );
    final restored = OrderQuery.fromParameters(query.toParameters());
    expect(restored, query);
  });
}
