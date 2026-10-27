import 'role.dart';

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final Role role;
  final int? customerId;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.customerId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: Role.fromApi(json['role'] as String?),
      customerId: (json['customerId'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'fullName': fullName,
        'email': email,
        'role': role.apiName,
        'customerId': customerId,
      };

  AppUser copyWith({Role? role}) {
    return AppUser(
      id: id,
      username: username,
      fullName: fullName,
      email: email,
      role: role ?? this.role,
      customerId: customerId,
    );
  }
}
