sealed class CalcResult {
  const CalcResult();
}

class CalcSuccess extends CalcResult {
  final double value;
  const CalcSuccess(this.value);
}

class CalcFailure extends CalcResult {
  final String message;
  const CalcFailure(this.message);
}

CalcResult calculate(String? rawA, String? rawOp, String? rawB) {
  final a = double.tryParse((rawA ?? '').replaceAll(',', '.'));
  final b = double.tryParse((rawB ?? '').replaceAll(',', '.'));

  if (a == null || b == null) {
    return const CalcFailure('В адресе переданы не числа');
  }

  return switch (rawOp) {
    '+' => CalcSuccess(a + b),
    '-' => CalcSuccess(a - b),
    '*' => CalcSuccess(a * b),
    '/' =>
      b == 0
          ? const CalcFailure('Деление на ноль невозможно')
          : CalcSuccess(a / b),
    _ => const CalcFailure('Неизвестная операция'),
  };
}

String formatNumber(double value) {
  if (value.isInfinite || value.isNaN) return 'Ошибка';
  var text = value.toStringAsFixed(6);
  text = text.replaceAll(RegExp(r'0+$'), '');
  text = text.replaceAll(RegExp(r'\.$'), '');
  if (text == '-0') text = '0';
  return text;
}
