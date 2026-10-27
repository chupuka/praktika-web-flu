import '../core/api_client.dart';
import '../models/app_user.dart';
import '../models/page_result.dart';
import '../models/role.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient _client;

  ApiAuthRepository(this._client);

  @override
  Future<AuthSession> login(String username, String password) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username.trim(), 'password': password},
    );
    return AuthSession.fromJson(data);
  }

  @override
  Future<AuthSession> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'username': username.trim(),
        'password': password,
        'fullName': fullName.trim(),
        'email': email.trim(),
      },
    );
    return AuthSession.fromJson(data);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthSession.fromJson(data);
  }

  @override
  Future<AppUser> me() async {
    final data = await _client.get<dynamic>('/auth/me');
    return AppUser.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<void> logout(String? refreshToken) async {
    await _client.post<dynamic>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }
}

class ApiUserRepository implements UserRepository {
  final ApiClient _client;

  ApiUserRepository(this._client);

  @override
  Future<PageResult<AppUser>> find({int page = 1, int size = 50}) async {
    final data = await _client.get<dynamic>(
      '/users',
      queryParameters: {'page': page, 'size': size},
    );
    final map = Map<String, dynamic>.from(data as Map);
    final items = (map['items'] as List?) ?? const [];
    return PageResult(
      items: [
        for (final item in items)
          AppUser.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      page: (map['page'] as num?)?.toInt() ?? page,
      size: (map['size'] as num?)?.toInt() ?? size,
      total: (map['total'] as num?)?.toInt() ?? items.length,
    );
  }

  @override
  Future<AppUser> changeRole(int id, Role role) async {
    final data = await _client.patch<dynamic>(
      '/users/$id',
      data: {'role': role.apiName},
    );
    return AppUser.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<void> delete(int id) async {
    await _client.delete('/users/$id');
  }
}
