import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/validation/validators.dart';

void main() {
  test('обязательность заполнения', () {
    expect(Validators.required('', 'название'), isNotNull);
    expect(Validators.required('   ', 'название'), isNotNull);
    expect(Validators.required(null, 'название'), isNotNull);
    expect(Validators.required('Диван', 'название'), isNull);
  });

  test('ограничение длины строки', () {
    expect(Validators.minLength('ab', 'название', 3), contains('минимум 3'));
    expect(Validators.minLength('abc', 'название', 3), isNull);
    expect(
        Validators.maxLength('abcdef', 'описание', 3), contains('не больше'));
    expect(Validators.maxLength('abc', 'описание', 3), isNull);
  });

  test('формат почты', () {
    expect(Validators.email('client@example.com'), isNull);
    expect(Validators.email('client@example'), contains('Некорректный'));
    expect(Validators.email('client.example.com'), contains('Некорректный'));
    expect(Validators.email(''), contains('Укажите почту'));
  });

  test('телефон проверяется по числу цифр', () {
    expect(Validators.phone('+7 900 111-22-33'), isNull);
    expect(Validators.phone('123'), contains('минимум 10'));
    expect(Validators.phone(''), isNull);
  });

  test('диапазон и положительность чисел', () {
    expect(Validators.positiveNumber('100', 'Цена'), isNull);
    expect(Validators.positiveNumber('0', 'Цена'), contains('больше нуля'));
    expect(Validators.positiveNumber('-5', 'Цена'), contains('больше нуля'));
    expect(
        Validators.positiveNumber('abc', 'Цена'), contains('ожидается число'));
    expect(
        Validators.inRange('500', 'Цена', min: 1, max: 100), contains('от 1'));
    expect(Validators.inRange('50', 'Цена', min: 1, max: 100), isNull);
  });

  test('целые неотрицательные значения', () {
    expect(Validators.nonNegativeInt('0', 'Остаток'), isNull);
    expect(Validators.nonNegativeInt('5', 'Остаток'), isNull);
    expect(
        Validators.nonNegativeInt('-1', 'Остаток'), contains('отрицательным'));
    expect(Validators.positiveInt('0', 'Количество'), contains('больше нуля'));
  });

  test('дата в формате ISO', () {
    expect(Validators.isoDate('2026-01-15', 'Дата'), isNull);
    expect(Validators.isoDate('15.01.2026', 'Дата'), contains('формате'));
    expect(Validators.isoDate('', 'Дата'), contains('Укажите'));
  });

  test('выбор из списка и множественный выбор', () {
    expect(Validators.notEmptyList([], 'материалы'), isNotNull);
    expect(Validators.notEmptyList([1], 'материалы'), isNull);
    expect(Validators.notEmptyOption(null, 'категорию'), isNotNull);
    expect(Validators.notEmptyOption(2, 'категорию'), isNull);
  });
}
