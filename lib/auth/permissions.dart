import '../models/role.dart';

enum Permission {
  viewCatalog('Просмотр каталога'),
  viewOwnProfile('Своя карточка покупателя'),
  viewOwnOrders('Мои заказы'),
  viewOrders('Заказы'),
  manageProducts('Управление товарами'),
  manageReferences('Справочники'),
  manageCustomers('Покупатели'),
  manageUsers('Пользователи и роли'),
  viewStatistics('Статистика'),
  hardDelete('Окончательное удаление'),
  restoreRecords('Восстановление записей');

  const Permission(this.label);

  final String label;
}

class Permissions {
  const Permissions._();

  static const Map<Role, Set<Permission>> matrix = {
    Role.customer: {
      Permission.viewCatalog,
      Permission.viewOwnProfile,
      Permission.viewOwnOrders,
    },
    Role.manager: {
      Permission.viewCatalog,
      Permission.manageProducts,
      Permission.manageReferences,
      Permission.manageCustomers,
      Permission.viewOrders,
    },
    Role.admin: {
      Permission.viewCatalog,
      Permission.manageProducts,
      Permission.manageReferences,
      Permission.manageCustomers,
      Permission.manageUsers,
      Permission.viewStatistics,
      Permission.hardDelete,
      Permission.restoreRecords,
    },
  };

  static bool can(Role role, Permission permission) {
    return matrix[role]!.contains(permission);
  }

  static List<Permission> forRole(Role role) {
    return [
      for (final permission in Permission.values)
        if (can(role, permission)) permission,
    ];
  }
}
