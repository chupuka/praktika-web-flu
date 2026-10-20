import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/data/json_store.dart';
import 'package:mebel_web/models/category.dart';
import 'package:mebel_web/models/category_query.dart';
import 'package:mebel_web/models/page_result.dart';
import 'package:mebel_web/models/product_query.dart';
import 'package:mebel_web/repositories/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late CategoryRepository categories;
  late ProductRepository products;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = JsonStore(prefs);
    products = PersistentProductRepository(store);
    categories = PersistentCategoryRepository(store, products);
  });

  test('категорий 8, поиск по названию', () async {
    final all = await categories.find(const CategoryQuery(size: 50));
    expect(all.total, 8);
    final found = await categories.find(
      const CategoryQuery(search: 'шкаф', size: 50),
    );
    expect(found.total, 1);
  });

  test('удаление и восстановление свободной категории', () async {
    await categories.create(const Category(id: 0, name: 'Свободная'));
    final created = await categories.findByName('Свободная');
    await categories.softDelete(created!.id);
    var all = await categories.find(const CategoryQuery(size: 50));
    expect(all.total, 8);
    await categories.restore(created.id);
    all = await categories.find(const CategoryQuery(size: 50));
    expect(all.total, 9);
  });

  test('категорию со связанными товарами удалить нельзя', () async {
    expect(
      () => categories.softDelete(1),
      throwsA(isA<DeleteBlocked>()),
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
