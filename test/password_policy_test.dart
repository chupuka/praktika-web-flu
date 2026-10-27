import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/auth/password_policy.dart';

void main() {
  group('Политика пароля', () {
    test('сильный пароль проходит все правила', () {
      expect(PasswordPolicy.isStrong('Mebel#2026'), isTrue);
      expect(PasswordPolicy.validate('Mebel#2026'), isNull);
    });

    test('короткий пароль отклоняется', () {
      expect(PasswordPolicy.isStrong('Ab#1'), isFalse);
      expect(
        PasswordPolicy.unmet('Ab#1'),
        contains(PasswordRule.minLength),
      );
    });

    test('пароль без цифры отклоняется', () {
      expect(PasswordPolicy.isStrong('Mebel###'), isFalse);
      expect(PasswordPolicy.unmet('Mebel###'), [PasswordRule.digit]);
    });

    test('пароль без специального символа отклоняется', () {
      expect(PasswordPolicy.isStrong('Mebel2026'), isFalse);
      expect(PasswordPolicy.unmet('Mebel2026'), [PasswordRule.special]);
    });

    test('пустой пароль не проходит', () {
      expect(PasswordPolicy.validate(''), isNotNull);
    });
  });
}
