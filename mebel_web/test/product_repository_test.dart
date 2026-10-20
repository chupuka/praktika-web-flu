import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/data/json_store.dart';
import 'package:mebel_web/models/product.dart';
import 'package:mebel_web/models/product_query.dart';
import 'package:mebel_web/repositories/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProductRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = PersistentProductRepository(JsonStore(prefs));
  });

  test('без фильтров возвращает все 22 товара', () async {
    final result = await repo.find(const ProductQuery(size: 50));
    expect(result.total, 22);
    expect(result.items.length, 22);
  });

  test('поиск находит по названию и описанию', () async {
    final result = await repo.find(
      const ProductQuery(search: 'диван', size: 50),
    );
    expect(result.total, 2);
    final byDesc = await repo.find(
      const ProductQuery(search: 'пружинами', size: 50),
    );
    expect(byDesc.total, 1);
  });

  test('фильтры комбинируются: категория и диапазон цен', () async {
    final result = await repo.find(
      const ProductQuery(
        categoryId: 1,
        priceFrom: 10000,
        priceTo: 50000,
        size: 50,
      ),
    );
    expect(result.total, 2);
    expect(result.items.map((p) => p.name), contains('Диван-кровать «Уют»'));
  });

  test('фильтр производителя и стиля', () async {
    final result = await repo.find(
      const ProductQuery(manufacturerId: 1, style: 'scandi', size: 50),
    );
    expect(result.total, 5);
  });

  test('в наличии убирает товар с нулевым остатком', () async {
    final result = await repo.find(
      const ProductQuery(inStockOnly: true, size: 50),
    );
    expect(result.total, 21);
    expect(result.items.where((p) => p.stock == 0), isEmpty);
  });

  test('сортировка по цене по убыванию', () async {
    final result = await repo.find(
      const ProductQuery(sortField: 'price', sortAscending: false, size: 50),
    );
    expect(result.items.first.name, contains('Прованс'));
    for (var i = 1; i < result.items.length; i++) {
      expect(result.items[i - 1].price >= result.items[i].price, isTrue);
    }
  });

  test('пагинация режет на страницы', () async {
    final first = await repo.find(
      const ProductQuery(sortField: 'name', page: 1, size: 10),
    );
    final second = await repo.find(
      const ProductQuery(sortField: 'name', page: 2, size: 10),
    );
    expect(first.total, 22);
    expect(first.items.length, 10);
    expect(second.items.length, 10);
    expect(second.page, 2);
    expect(
      first.items
          .map((p) => p.id)
          .toSet()
          .intersection(second.items.map((p) => p.id).toSet()),
      isEmpty,
    );
  });

  test('неизвестное поле сортировки бросает ошибку', () async {
    expect(
      repo.find(const ProductQuery(sortField: 'bogus')),
      throwsArgumentError,
    );
  });

  test('мягкое удаление прячет, флаг показывает, восстановление возвращает',
      () async {
    await repo.softDelete(1);
    var hidden = await repo.find(const ProductQuery(search: 'Уют', size: 50));
    expect(hidden.total, 0);
    final shown = await repo.find(
      const ProductQuery(search: 'Уют', includeDeleted: true, size: 50),
    );
    expect(shown.total, 1);
    await repo.restore(1);
    hidden = await repo.find(const ProductQuery(search: 'Уют', size: 50));
    expect(hidden.total, 1);
  });

  test('жёсткое удаление стирает насовсем', () async {
    await repo.hardDelete(1);
    final shown = await repo.find(
      const ProductQuery(search: 'Уют', includeDeleted: true, size: 50),
    );
    expect(shown.total, 0);
  });

  test('множественное удаление считает только живые записи', () async {
    await repo.softDelete(1);
    final count = await repo.deleteMany([1, 2, 3]);
    expect(count, 2);
  });

  test('создание товара присваивает новый идентификатор', () async {
    final id = await repo.create(const Product(
      id: 0,
      name: 'Тестовый стул',
      sku: 'MB-999',
      price: 1000,
      categoryId: 2,
      manufacturerId: 1,
      materialIds: [4],
    ));
    expect(id, 23);
    final created = await repo.findById(id);
    expect(created?.name, 'Тестовый стул');
  });

  test('поиск дубликата артикула находит существующий товар', () async {
    final duplicate = await repo.findBySku('MB-001');
    expect(duplicate?.name, contains('Уют'));
    final own = await repo.findBySku('MB-001', exceptId: 1);
    expect(own, isNull);
  });

  test('данные переживают пересоздание репозитория', () async {
    await repo.create(const Product(
      id: 0,
      name: 'Стол сохраняемый',
      sku: 'MB-777',
      price: 5000,
      categoryId: 2,
      manufacturerId: 1,
    ));
    final prefs = await SharedPreferences.getInstance();
    final fresh = PersistentProductRepository(JsonStore(prefs));
    final found = await fresh.find(
      const ProductQuery(search: 'сохраняемый', size: 50),
    );
    expect(found.total, 1);
  });
}
