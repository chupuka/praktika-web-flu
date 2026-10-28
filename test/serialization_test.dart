import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/models/category.dart';
import 'package:mebel_web/models/customer.dart';
import 'package:mebel_web/models/manufacturer.dart';
import 'package:mebel_web/models/material.dart';
import 'package:mebel_web/models/product.dart';

void main() {
  test('товар переживает путь в JSON и обратно', () {
    final product = Product(
      id: 5,
      name: 'Стул',
      sku: 'MB-005',
      description: 'Описание',
      style: 'modern',
      price: 8490.5,
      stock: 12,
      width: 50,
      depth: 55,
      height: 85,
      weight: 6,
      color: 'Белый',
      categoryId: 2,
      manufacturerId: 3,
      materialIds: const [5, 4],
      deletedAt: DateTime.parse('2026-01-15T10:00:00.000'),
    );
    final restored = Product.fromJson(product.toJson());
    expect(restored.id, product.id);
    expect(restored.name, product.name);
    expect(restored.sku, product.sku);
    expect(restored.price, product.price);
    expect(restored.stock, product.stock);
    expect(restored.width, product.width);
    expect(restored.materialIds, product.materialIds);
    expect(restored.deletedAt, product.deletedAt);
  });

  test('fromJson устойчив к отсутствующим и null-полям', () {
    final restored = Product.fromJson(const {});
    expect(restored.id, 0);
    expect(restored.name, '');
    expect(restored.price, 0);
    expect(restored.stock, 0);
    expect(restored.width, isNull);
    expect(restored.materialIds, isEmpty);
    expect(restored.deletedAt, isNull);

    final withNulls = Product.fromJson(const {
      'id': null,
      'name': null,
      'price': null,
      'materialIds': null,
      'deletedAt': null,
    });
    expect(withNulls.id, 0);
    expect(withNulls.name, '');
    expect(withNulls.materialIds, isEmpty);
  });

  test('fromJson переживает числа, пришедшие строками разного вида', () {
    final restored = Product.fromJson(const {
      'id': 7,
      'name': 'Стол',
      'price': 12000,
      'stock': 3,
      'width': 120,
      'categoryId': 2,
      'manufacturerId': 1,
      'materialIds': [1, 2, 3],
    });
    expect(restored.id, 7);
    expect(restored.price, 12000.0);
    expect(restored.width, 120.0);
    expect(restored.materialIds, [1, 2, 3]);
  });

  test('категория, производитель и материал переживают сериализацию', () {
    const category = Category(id: 3, name: 'Кровати', description: 'Спальня');
    final restoredCategory = Category.fromJson(category.toJson());
    expect(restoredCategory.name, 'Кровати');
    expect(restoredCategory.description, 'Спальня');

    const manufacturer = Manufacturer(
      id: 2,
      name: 'Hoff',
      country: 'Россия',
      contactEmail: 'shop@hoff.ru',
    );
    final restoredManufacturer = Manufacturer.fromJson(manufacturer.toJson());
    expect(restoredManufacturer.country, 'Россия');
    expect(restoredManufacturer.contactEmail, 'shop@hoff.ru');

    const material = FurnitureMaterial(id: 4, name: 'Металл');
    final restoredMaterial = FurnitureMaterial.fromJson(material.toJson());
    expect(restoredMaterial.name, 'Металл');
  });

  test('покупатель с картой и без карты', () {
    const withCard = Customer(
      id: 1,
      fullName: 'Иванова Мария',
      email: 'm@example.com',
      card: CustomerCard(
        number: 'CL-1001',
        issuedAt: '2024-03-15',
        tier: 'gold',
        points: 1240,
      ),
    );
    final restored = Customer.fromJson(withCard.toJson());
    expect(restored.card?.number, 'CL-1001');
    expect(restored.card?.tier, 'gold');
    expect(restored.card?.points, 1240);

    const withoutCard = Customer(
      id: 2,
      fullName: 'Петров Алексей',
      email: 'p@example.com',
    );
    final restoredWithout = Customer.fromJson(withoutCard.toJson());
    expect(restoredWithout.card, isNull);
  });

  test('битая карта не роняет разбор покупателя', () {
    final restored = Customer.fromJson(const {
      'id': 3,
      'fullName': 'Соколова Ольга',
      'email': 's@example.com',
      'card': null,
    });
    expect(restored.card, isNull);
    expect(restored.fullName, 'Соколова Ольга');
  });
}
