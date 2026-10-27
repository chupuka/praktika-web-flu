enum Role {
  customer(1, 'customer', 'Покупатель'),
  manager(2, 'manager', 'Менеджер'),
  admin(3, 'admin', 'Администратор');

  const Role(this.level, this.apiName, this.label);

  final int level;
  final String apiName;
  final String label;

  bool atLeast(Role other) => level >= other.level;

  static Role fromApi(String? value) {
    return values.firstWhere(
      (role) => role.apiName == value,
      orElse: () => Role.customer,
    );
  }
}
