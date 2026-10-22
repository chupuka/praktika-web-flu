import '../models/category.dart';
import '../models/customer.dart';
import '../models/manufacturer.dart';
import '../models/material.dart';
import '../models/product.dart';

const seedCategories = [
  Category(id: 1, name: 'Диваны и кресла', description: 'Мягкая мебель для гостиной и отдыха'),
  Category(id: 2, name: 'Столы и стулья', description: 'Обеденные и письменные столы, стулья'),
  Category(id: 3, name: 'Кровати и матрасы', description: 'Спальная мебель и принадлежности'),
  Category(id: 4, name: 'Шкафы и стеллажи', description: 'Системы хранения для дома'),
  Category(id: 5, name: 'Кухонная мебель', description: 'Гарнитуры и модули для кухни'),
  Category(id: 6, name: 'Прихожие', description: 'Мебель для прихожей и коридора'),
  Category(id: 7, name: 'Детская мебель', description: 'Мебель для детской комнаты'),
  Category(id: 8, name: 'Офисная мебель', description: 'Мебель для кабинета и офиса'),
];

const seedManufacturers = [
  Manufacturer(id: 1, name: 'IKEA', country: 'Швеция', contactEmail: 'info@ikea.com'),
  Manufacturer(id: 2, name: 'Hoff', country: 'Россия', contactEmail: 'shop@hoff.ru'),
  Manufacturer(id: 3, name: 'Mr.Doors', country: 'Россия', contactEmail: 'info@mrdoors.ru'),
  Manufacturer(id: 4, name: 'Leroy Merlin', country: 'Франция', contactEmail: 'service@leroymerlin.ru'),
  Manufacturer(id: 5, name: 'Шатура', country: 'Россия', contactEmail: 'office@shatura.ru'),
];

const seedMaterials = <FurnitureMaterial>[
  FurnitureMaterial(id: 1, name: 'Массив дуба', description: 'Натуральная древесина твёрдых пород'),
  FurnitureMaterial(id: 2, name: 'МДФ', description: 'Древесноволокнистая плита'),
  FurnitureMaterial(id: 3, name: 'ЛДСП', description: 'Ламинированная стружечная плита'),
  FurnitureMaterial(id: 4, name: 'Металл', description: 'Сталь и порошковая окраска'),
  FurnitureMaterial(id: 5, name: 'Экокожа', description: 'Искусственная кожа'),
  FurnitureMaterial(id: 6, name: 'Микрофибра', description: 'Синтетическая ворсовая ткань'),
  FurnitureMaterial(id: 7, name: 'Велюр', description: 'Бархатистая обивочная ткань'),
  FurnitureMaterial(id: 8, name: 'Стекло', description: 'Закалённое стекло'),
];

const seedStyles = ['modern', 'classic', 'loft', 'scandi', 'provence'];

const seedCustomers = [
  Customer(
    id: 1,
    fullName: 'Иванова Мария Петровна',
    email: 'ivanova.maria@example.com',
    phone: '+7 900 111-22-33',
    address: 'Москва, ул. Тверская, д. 12, кв. 5',
    card: CustomerCard(number: 'CL-1001', issuedAt: '2024-03-15', tier: 'gold', points: 1240),
  ),
  Customer(
    id: 2,
    fullName: 'Петров Алексей Ильич',
    email: 'petrov.alexey@example.com',
    phone: '+7 901 222-33-44',
    address: 'Санкт-Петербург, Невский пр., д. 88',
    card: CustomerCard(number: 'CL-1002', issuedAt: '2024-07-02', tier: 'silver', points: 430),
  ),
  Customer(
    id: 3,
    fullName: 'Соколова Ольга Викторовна',
    email: 'sokolova.olga@example.com',
    phone: '+7 902 333-44-55',
    address: 'Казань, ул. Баумана, д. 40',
  ),
  Customer(
    id: 4,
    fullName: 'Кузнецов Дмитрий Сергеевич',
    email: 'kuznetsov.dmitry@example.com',
    phone: '+7 903 444-55-66',
    address: 'Новосибирск, ул. Ленина, д. 7',
    card: CustomerCard(number: 'CL-1003', issuedAt: '2025-01-20', tier: 'basic', points: 85),
  ),
  Customer(
    id: 5,
    fullName: 'Николаева Екатерина Андреевна',
    email: 'nikolaeva.ekaterina@example.com',
    phone: '+7 904 555-66-77',
    address: 'Екатеринбург, ул. Малышева, д. 101',
  ),
];

const seedProducts = [
  Product(id: 1, name: 'Диван-кровать «Уют»', sku: 'MB-001', description: 'Удобный диван-кровать с механизмом трансформации. Обивка — износостойкая микрофибра.', style: 'modern', price: 45990, stock: 15, width: 200, depth: 90, height: 85, weight: 45, color: 'Серый', categoryId: 1, manufacturerId: 2, materialIds: [6, 4]),
  Product(id: 2, name: 'Угловой диван «Лофт»', sku: 'MB-002', description: 'Стильный угловой диван с местом для хранения внутри.', style: 'loft', price: 78990, stock: 8, width: 260, depth: 160, height: 80, weight: 62, color: 'Чёрный', categoryId: 1, manufacturerId: 3, materialIds: [5, 4]),
  Product(id: 3, name: 'Кресло «Релакс»', sku: 'MB-003', description: 'Комфортное кресло с высокой спинкой. Механизм качания.', style: 'modern', price: 19990, stock: 25, width: 75, depth: 80, height: 110, weight: 18, color: 'Тёмно-синий', categoryId: 1, manufacturerId: 1, materialIds: [7, 4]),
  Product(id: 4, name: 'Стол обеденный «Классика»', sku: 'MB-004', description: 'Большой обеденный стол из массива дуба на 6 персон.', style: 'classic', price: 34990, stock: 10, width: 180, depth: 90, height: 75, weight: 35, color: 'Дуб', categoryId: 2, manufacturerId: 5, materialIds: [1, 4]),
  Product(id: 5, name: 'Стул «Барселона»', sku: 'MB-005', description: 'Элегантный стул с мягким сиденьем.', style: 'modern', price: 8490, stock: 40, width: 50, depth: 55, height: 85, weight: 6, color: 'Белый', categoryId: 2, manufacturerId: 3, materialIds: [5, 4]),
  Product(id: 6, name: 'Стол письменный «Офис»', sku: 'MB-006', description: 'Компактный письменный стол с выдвижными ящиками.', style: 'scandi', price: 15990, stock: 20, width: 120, depth: 60, height: 75, weight: 22, color: 'Белый', categoryId: 2, manufacturerId: 1, materialIds: [3, 4]),
  Product(id: 7, name: 'Кровать двуспальная «Престиж»', sku: 'MB-007', description: 'Двуспальная кровать с мягким изголовьем 160x200.', style: 'classic', price: 52990, stock: 5, width: 165, depth: 210, height: 90, weight: 55, color: 'Бежевый', categoryId: 3, manufacturerId: 3, materialIds: [5, 2]),
  Product(id: 8, name: 'Матрас ортопедический «Здоровье»', sku: 'MB-008', description: 'Ортопедический матрас с независимыми пружинами.', style: 'modern', price: 24990, stock: 12, width: 160, depth: 200, height: 22, weight: 25, color: 'Белый', categoryId: 3, manufacturerId: 2, materialIds: [6, 4]),
  Product(id: 9, name: 'Тумба прикроватная «Норд»', sku: 'MB-009', description: 'Компактная прикроватная тумба с ящиком.', style: 'scandi', price: 6990, stock: 30, width: 40, depth: 35, height: 55, weight: 8, color: 'Белый', categoryId: 3, manufacturerId: 1, materialIds: [2]),
  Product(id: 10, name: 'Шкаф-купе «Гранд»', sku: 'MB-010', description: 'Вместительный шкаф-купе: полки, штанги, ящики.', style: 'modern', price: 68990, stock: 7, width: 240, depth: 60, height: 240, weight: 90, color: 'Венге', categoryId: 4, manufacturerId: 5, materialIds: [3, 8]),
  Product(id: 11, name: 'Стеллаж «Открытый»', sku: 'MB-011', description: 'Стеллаж с открытыми полками. Регулируемые полки.', style: 'scandi', price: 12490, stock: 18, width: 80, depth: 35, height: 200, weight: 15, color: 'Дуб', categoryId: 4, manufacturerId: 1, materialIds: [3, 4]),
  Product(id: 12, name: 'Стенка гостиная «Модерн»', sku: 'MB-012', description: 'Модульная стенка: шкаф, витрина, тумба под ТВ.', style: 'modern', price: 84900, stock: 4, width: 300, depth: 50, height: 220, weight: 120, color: 'Орех', categoryId: 4, manufacturerId: 2, materialIds: [2, 8]),
  Product(id: 13, name: 'Кухонный гарнитур «Прованс»', sku: 'MB-013', description: 'Классический кухонный гарнитур, 6 модулей.', style: 'provence', price: 189990, stock: 3, width: 280, depth: 60, height: 210, weight: 150, color: 'Кремовый', categoryId: 5, manufacturerId: 3, materialIds: [2, 1]),
  Product(id: 14, name: 'Кухонный уголок «Завтрак»', sku: 'MB-014', description: 'Мягкий кухонный уголок с ящиком для хранения.', style: 'classic', price: 28990, stock: 14, width: 140, depth: 120, height: 85, weight: 35, color: 'Коричневый', categoryId: 5, manufacturerId: 5, materialIds: [5, 2]),
  Product(id: 15, name: 'Вешалка прихожая «Минимал»', sku: 'MB-015', description: 'Настенная вешалка с полкой и крючками.', style: 'scandi', price: 3990, stock: 50, width: 60, depth: 25, height: 40, weight: 4, color: 'Белый', categoryId: 6, manufacturerId: 1, materialIds: [4, 2]),
  Product(id: 16, name: 'Консоль прихожая «Элегант»', sku: 'MB-016', description: 'Узкая консоль с ящиками и зеркалом.', style: 'classic', price: 18990, stock: 10, width: 80, depth: 40, height: 90, weight: 18, color: 'Дуб', categoryId: 6, manufacturerId: 2, materialIds: [2, 8]),
  Product(id: 17, name: 'Кровать детская «Малыш»', sku: 'MB-017', description: 'Детская кровать с бортиками 90x180. Безопасные углы.', style: 'scandi', price: 18990, stock: 11, width: 95, depth: 185, height: 70, weight: 20, color: 'Белый', categoryId: 7, manufacturerId: 1, materialIds: [2, 4]),
  Product(id: 18, name: 'Стол детский «Школьник»', sku: 'MB-018', description: 'Растущий письменный стол с регулировкой высоты.', style: 'modern', price: 12990, stock: 16, width: 100, depth: 60, height: 75, weight: 16, color: 'Серый', categoryId: 7, manufacturerId: 2, materialIds: [3, 4]),
  Product(id: 19, name: 'Кресло офисное «Босс»', sku: 'MB-019', description: 'Эргономичное кресло с поддержкой поясницы.', style: 'modern', price: 24990, stock: 9, width: 65, depth: 65, height: 130, weight: 15, color: 'Чёрный', categoryId: 8, manufacturerId: 3, materialIds: [5, 4]),
  Product(id: 20, name: 'Стеллаж офисный «Архив»', sku: 'MB-020', description: 'Металлический стеллаж для документов.', style: 'loft', price: 21490, stock: 13, width: 100, depth: 40, height: 200, weight: 28, color: 'Серый', categoryId: 8, manufacturerId: 5, materialIds: [4, 3]),
  Product(id: 21, name: 'Комод «Классик»', sku: 'MB-021', description: 'Комод с пятью ящиками на направляющих.', style: 'classic', price: 27990, stock: 6, width: 120, depth: 45, height: 90, weight: 32, color: 'Орех', categoryId: 4, manufacturerId: 5, materialIds: [2, 1]),
  Product(id: 22, name: 'Пуф «Мягкий»', sku: 'MB-022', description: 'Круглый пуф с отделением для хранения.', style: 'modern', price: 5990, stock: 0, width: 45, depth: 45, height: 40, weight: 5, color: 'Горчичный', categoryId: 1, manufacturerId: 1, materialIds: [7]),
];
