import 'package:calc_web/logic/calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculate', () {
    test('сложение', () {
      final r = calculate('2', '+', '3');
      expect(r, isA<CalcSuccess>());
      expect((r as CalcSuccess).value, 5.0);
    });

    test('вычитание', () {
      final r = calculate('10', '-', '4.5');
      expect((r as CalcSuccess).value, closeTo(5.5, 1e-9));
    });

    test('умножение', () {
      final r = calculate('3', '*', '7');
      expect((r as CalcSuccess).value, 21.0);
    });

    test('деление', () {
      final r = calculate('7', '/', '2');
      expect((r as CalcSuccess).value, 3.5);
    });

    test('деление на ноль — ошибка', () {
      final r = calculate('5', '/', '0');
      expect(r, isA<CalcFailure>());
      expect((r as CalcFailure).message, contains('ноль'));
    });

    test('нечисловой ввод — ошибка', () {
      final r = calculate('abc', '+', '2');
      expect(r, isA<CalcFailure>());
    });

    test('неизвестная операция — ошибка', () {
      final r = calculate('2', '%', '3');
      expect(r, isA<CalcFailure>());
    });

    test('отсутствие параметра — ошибка', () {
      final r = calculate(null, '+', '3');
      expect(r, isA<CalcFailure>());
    });
  });

  group('formatNumber', () {
    test('убирает артефакт 3.3333333333333335', () {
      expect(formatNumber(10 / 3), '3.333333');
    });

    test('целое без хвоста', () {
      expect(formatNumber(5.0), '5');
    });
  });
}
