import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/auth/permissions.dart';
import 'package:mebel_web/models/role.dart';

void main() {
  group('Права ролей', () {
    test('покупатель видит каталог и только свою карточку', () {
      expect(Permissions.can(Role.customer, Permission.viewCatalog), isTrue);
      expect(
        Permissions.can(Role.customer, Permission.viewOwnProfile),
        isTrue,
      );
      expect(
        Permissions.can(Role.customer, Permission.manageProducts),
        isFalse,
      );
      expect(Permissions.can(Role.customer, Permission.manageUsers), isFalse);
    });

    test('менеджер управляет товарами и справочниками', () {
      expect(
        Permissions.can(Role.manager, Permission.manageProducts),
        isTrue,
      );
      expect(
        Permissions.can(Role.manager, Permission.manageReferences),
        isTrue,
      );
      expect(Permissions.can(Role.manager, Permission.manageCustomers), isTrue);
    });

    test('менеджер не управляет пользователями и не смотрит статистику', () {
      expect(Permissions.can(Role.manager, Permission.manageUsers), isFalse);
      expect(Permissions.can(Role.manager, Permission.viewStatistics), isFalse);
    });

    test('окончательное удаление доступно только администратору', () {
      expect(Permissions.can(Role.admin, Permission.hardDelete), isTrue);
      expect(Permissions.can(Role.manager, Permission.hardDelete), isFalse);
      expect(Permissions.can(Role.customer, Permission.hardDelete), isFalse);
    });

    test('восстановление записей доступно только администратору', () {
      expect(Permissions.can(Role.admin, Permission.restoreRecords), isTrue);
      expect(Permissions.can(Role.manager, Permission.restoreRecords), isFalse);
    });

    test('администратор наследует права менеджера', () {
      for (final permission in Permissions.forRole(Role.manager)) {
        expect(Permissions.can(Role.admin, permission), isTrue);
      }
    });

    test('матрица прав не выдаёт менеджеру прав администратора', () {
      final manager = Permissions.matrix[Role.manager]!;
      expect(manager.contains(Permission.manageUsers), isFalse);
      expect(manager.contains(Permission.viewStatistics), isFalse);
      expect(manager.contains(Permission.hardDelete), isFalse);
    });

    test('роль из API разбирается по имени, неизвестная — покупатель', () {
      expect(Role.fromApi('admin'), Role.admin);
      expect(Role.fromApi('manager'), Role.manager);
      expect(Role.fromApi('customer'), Role.customer);
      expect(Role.fromApi('unknown'), Role.customer);
    });
  });
}
