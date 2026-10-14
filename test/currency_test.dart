import 'package:calc_web/logic/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('convert', () {
    test('доллары в рубли', () {
      final r = convert('100', 'USD', 'RUB');
      expect(r, isA<ConvertSuccess>());
      expect((r as ConvertSuccess).value, closeTo(9250.0, 1e-6));
    });

    test('рубли в доллары', () {
      final r = convert('9250', 'RUB', 'USD');
      expect((r as ConvertSuccess).value, closeTo(100.0, 1e-6));
    });

    test('нечисловая сумма — ошибка', () {
      expect(convert('abc', 'USD', 'RUB'), isA<ConvertFailure>());
    });

    test('неизвестная валюта — ошибка', () {
      expect(convert('10', 'XXX', 'RUB'), isA<ConvertFailure>());
    });

    test('отрицательная сумма — ошибка', () {
      expect(convert('-5', 'USD', 'RUB'), isA<ConvertFailure>());
    });

    test('пять валют заданы константами', () {
      expect(currencies.length, greaterThanOrEqualTo(5));
      for (final c in ['RUB', 'USD', 'EUR', 'CNY', 'KZT']) {
        expect(currencyRates.containsKey(c), isTrue);
      }
    });
  });
}
