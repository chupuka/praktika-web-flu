enum PasswordRule {
  minLength('Не менее 8 символов'),
  digit('Есть цифра'),
  special('Есть специальный символ');

  const PasswordRule(this.label);

  final String label;

  bool check(String password) {
    return switch (this) {
      PasswordRule.minLength => password.length >= 8,
      PasswordRule.digit => RegExp(r'\d').hasMatch(password),
      PasswordRule.special => RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    };
  }
}

class PasswordPolicy {
  const PasswordPolicy._();

  static bool isStrong(String password) {
    return PasswordRule.values.every((rule) => rule.check(password));
  }

  static List<PasswordRule> unmet(String password) {
    return [
      for (final rule in PasswordRule.values)
        if (!rule.check(password)) rule,
    ];
  }

  static String? validate(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Укажите пароль';
    final missing = unmet(password);
    if (missing.isNotEmpty) {
      return 'Пароль: ${missing.map((r) => r.label.toLowerCase()).join(', ')}';
    }
    return null;
  }
}
