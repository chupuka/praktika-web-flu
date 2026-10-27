import '../models/app_user.dart';
import '../models/page_result.dart';
import '../models/role.dart';

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      user: AppUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
    );
  }
}

abstract interface class AuthRepository {
  Future<AuthSession> login(String username, String password);
  Future<AuthSession> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  });
  Future<AuthSession> refresh(String refreshToken);
  Future<AppUser> me();
  Future<void> logout(String? refreshToken);
}

abstract interface class UserRepository {
  Future<PageResult<AppUser>> find({int page = 1, int size = 50});
  Future<AppUser> changeRole(int id, Role role);
  Future<void> delete(int id);
}
