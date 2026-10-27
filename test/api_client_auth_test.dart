import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/core/api_client.dart';
import 'package:mebel_web/core/api_exceptions.dart';

import 'support/mock_adapter.dart';

void main() {
  late MockAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = MockAdapter();
    client = ApiClient();
    client.dio.httpClientAdapter = adapter;
    client.setAccessToken('старый-токен');
  });

  test('401 обновляет токен и один раз повторяет запрос', () async {
    var refreshes = 0;
    client.onUnauthorized = () async {
      refreshes += 1;
      client.setAccessToken('новый-токен');
      return true;
    };
    adapter.enqueueJson(401, {'message': 'Истёк'});
    adapter.enqueueJson(200, {'ok': true});

    final data = await client.get<dynamic>('/products');

    expect(data, {'ok': true});
    expect(refreshes, 1);
    expect(adapter.requests.length, 2);
    expect(
      adapter.requests.last.headers['Authorization'],
      'Bearer новый-токен',
    );
  });

  test('повторный 401 не вызывает бесконечного обновления', () async {
    var refreshes = 0;
    client.onUnauthorized = () async {
      refreshes += 1;
      return true;
    };
    adapter.enqueueJson(401, {'message': 'Истёк'});
    adapter.enqueueJson(401, {'message': 'Всё ещё истёк'});

    await expectLater(
      client.get<dynamic>('/products'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(refreshes, 1);
    expect(adapter.requests.length, 2);
  });

  test('неудачное обновление не повторяет запрос', () async {
    var refreshes = 0;
    client.onUnauthorized = () async {
      refreshes += 1;
      return false;
    };
    adapter.enqueueJson(401, {'message': 'Истёк'});

    await expectLater(
      client.get<dynamic>('/products'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(refreshes, 1);
    expect(adapter.requests.length, 1);
  });

  test('401 на адресах /auth/ не запускает обновление', () async {
    var refreshes = 0;
    client.onUnauthorized = () async {
      refreshes += 1;
      return true;
    };
    adapter.enqueueJson(401, {'message': 'Неверный логин или пароль'});

    await expectLater(
      client.post<dynamic>('/auth/login', data: {}),
      throwsA(
        isA<UnauthorizedException>().having(
          (e) => e.message,
          'message',
          contains('Неверный логин'),
        ),
      ),
    );
    expect(refreshes, 0);
    expect(adapter.requests.length, 1);
  });

  test('403 превращается в ForbiddenException', () async {
    adapter.enqueueJson(403, {'message': 'Операция доступна только admin'});

    await expectLater(
      client.get<dynamic>('/users'),
      throwsA(
        isA<ForbiddenException>().having(
          (e) => e.message,
          'message',
          contains('admin'),
        ),
      ),
    );
  });

  test('тело повторного запроса не теряется', () async {
    client.onUnauthorized = () async {
      client.setAccessToken('новый');
      return true;
    };
    adapter.enqueueJson(401, {'message': 'Истёк'});
    adapter.enqueueJson(200, {'id': 5});

    await client.put<dynamic>('/products/5', data: {'name': 'Стол'});

    expect(adapter.requests.last.method, 'PUT');
    expect(adapter.requests.last.path, '/products/5');
    expect(adapter.requests.last.data, {'name': 'Стол'});
  });
}
