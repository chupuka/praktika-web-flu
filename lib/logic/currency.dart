const Map<String, double> currencyRates = {
  'RUB': 1.0,
  'USD': 92.5,
  'EUR': 100.2,
  'CNY': 12.7,
  'KZT': 0.19,
};

const List<String> currencies = ['RUB', 'USD', 'EUR', 'CNY', 'KZT'];

sealed class ConvertResult {
  const ConvertResult();
}

class ConvertSuccess extends ConvertResult {
  final double value;
  const ConvertSuccess(this.value);
}

class ConvertFailure extends ConvertResult {
  final String message;
  const ConvertFailure(this.message);
}

ConvertResult convert(String? rawAmount, String? from, String? to) {
  final amount = double.tryParse((rawAmount ?? '').replaceAll(',', '.'));
  if (amount == null) {
    return const ConvertFailure('В адресе передана не сумма');
  }
  final fromRate = from == null ? null : currencyRates[from];
  final toRate = to == null ? null : currencyRates[to];
  if (fromRate == null || toRate == null) {
    return const ConvertFailure('Неизвестная валюта');
  }
  if (amount < 0) {
    return const ConvertFailure('Сумма не может быть отрицательной');
  }
  final inRub = amount * fromRate;
  final value = (inRub / toRate * 100).round() / 100;
  return ConvertSuccess(value);
}
