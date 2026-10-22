class Validators {
  const Validators._();

  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Укажите $label';
    }
    return null;
  }

  static String? minLength(String? value, String label, int min) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Укажите $label';
    if (text.length < min) {
      return '$label: минимум $min символов';
    }
    return null;
  }

  static String? maxLength(String? value, String label, int max) {
    final text = value?.trim() ?? '';
    if (text.length > max) {
      return '$label: не больше $max символов';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Укажите почту';
    final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(text)) return 'Некорректный адрес почты';
    return null;
  }

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return 'Телефон: минимум 10 цифр';
    if (digits.length > 15) return 'Телефон: не больше 15 цифр';
    return null;
  }

  static String? positiveNumber(String? value, String label) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return 'Укажите $label';
    final parsed = double.tryParse(text);
    if (parsed == null) return '$label: ожидается число';
    if (parsed <= 0) return '$label должно быть больше нуля';
    return null;
  }

  static String? nonNegativeNumber(String? value, String label) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return 'Укажите $label';
    final parsed = double.tryParse(text);
    if (parsed == null) return '$label: ожидается число';
    if (parsed < 0) return '$label не может быть отрицательным';
    return null;
  }

  static String? positiveInt(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Укажите $label';
    final parsed = int.tryParse(text);
    if (parsed == null) return '$label: ожидается целое число';
    if (parsed <= 0) return '$label должно быть больше нуля';
    return null;
  }

  static String? nonNegativeInt(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Укажите $label';
    final parsed = int.tryParse(text);
    if (parsed == null) return '$label: ожидается целое число';
    if (parsed < 0) return '$label не может быть отрицательным';
    return null;
  }

  static String? inRange(
    String? value,
    String label, {
    required double min,
    required double max,
  }) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return 'Укажите $label';
    final parsed = double.tryParse(text);
    if (parsed == null) return '$label: ожидается число';
    if (parsed < min || parsed > max) {
      return '$label: допустимо от $min до $max';
    }
    return null;
  }

  static String? isoDate(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Укажите $label';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return '$label: ожидается дата в формате ГГГГ-ММ-ДД';
    return null;
  }

  static String? notEmptyList(List<int>? value, String label) {
    if (value == null || value.isEmpty) {
      return 'Выберите $label';
    }
    return null;
  }

  static String? notEmptyOption(int? value, String label) {
    if (value == null) return 'Выберите $label';
    return null;
  }
}
