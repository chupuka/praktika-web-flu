import 'dart:convert';

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../models/page_result.dart';
import '../models/role.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient _client;

  ApiAuthRepository(this._client);

  String _email(String username) {
    final value = username.trim().toLowerCase();
    if (value.contains('@')) return value;
    return '$value@${ApiConfig.emailDomain}';
  }

  Future<Map<String, dynamic>> _tokenRequest(
    String grantType,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.postRaw<dynamic>(
      '${ApiConfig.authUrl}/token?grant_type=$grantType',
      data: body,
      checkStatus: false,
    );
    final data = response.data;
    if ((response.statusCode ?? 500) >= 400 || data is! Map) {
      throw _authError(response.statusCode ?? 500, data);
    }
    return Map<String, dynamic>.from(data);
  }

  ApiException _authError(int status, dynamic data) {
    final text = data is Map
        ? (data['error_description'] ?? data['msg'] ?? data['message'] ?? '')
            .toString()
        : '';
    if (text.contains('Invalid login credentials') ||
        text.contains('invalid_grant')) {
      return const UnauthorizedException('Неверный логин или пароль');
    }
    if (text.contains('already registered') ||
        text.contains('already been registered')) {
      return const ConflictException('Пользователь с таким email уже есть');
    }
    if (status == 400 || status == 422) {
      return ValidationException(
        text.isEmpty ? 'Проверьте введённые данные' : text,
        const {},
      );
    }
    return UnauthorizedException(
      text.isEmpty ? 'Не удалось войти в систему' : text,
    );
  }

  String? _userId(String token) {
    try {
      final part = token.split('.')[1];
      final normalized = base64Url.normalize(part);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      return (payload as Map)['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<AppUser> _profile(String token) async {
    final id = _userId(token);
    if (id == null) throw const UnauthorizedException('Сессия истекла');
    final response = await _client.getRaw<dynamic>(
      'profiles',
      queryParameters: {'id': 'eq.$id', 'select': '*'},
      headers: {'Authorization': 'Bearer $token'},
    );
    final rows = response.data;
    if (rows is List && rows.isNotEmpty) {
      return userFromRow(Map<String, dynamic>.from(rows.first as Map));
    }
    throw const UnauthorizedException('Учётная запись заблокирована');
  }

  @override
  Future<AuthSession> login(String username, String password) async {
    final data = await _tokenRequest(
      'password',
      {'email': _email(username), 'password': password},
    );
    final token = data['access_token'] as String? ?? '';
    final user = await _profile(token);
    return AuthSession(
      accessToken: token,
      refreshToken: data['refresh_token'] as String? ?? '',
      expiresIn: (data['expires_in'] as num?)?.toInt() ?? 0,
      user: user,
    );
  }

  @override
  Future<AuthSession> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) async {
    final response = await _client.postRaw<dynamic>(
      '${ApiConfig.authUrl}/signup',
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'data': {
          'username': username.trim(),
          'full_name': fullName.trim(),
        },
      },
      checkStatus: false,
    );
    final data = response.data;
    if ((response.statusCode ?? 500) >= 400 ||
        data is! Map ||
        data['access_token'] == null) {
      throw _authError(response.statusCode ?? 500, data);
    }
    final token = data['access_token'] as String;
    final user = await _profile(token);
    return AuthSession(
      accessToken: token,
      refreshToken: data['refresh_token'] as String? ?? '',
      expiresIn: (data['expires_in'] as num?)?.toInt() ?? 0,
      user: user,
    );
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final data = await _tokenRequest(
      'refresh_token',
      {'refresh_token': refreshToken},
    );
    final token = data['access_token'] as String? ?? '';
    final user = await _profile(token);
    return AuthSession(
      accessToken: token,
      refreshToken: data['refresh_token'] as String? ?? '',
      expiresIn: (data['expires_in'] as num?)?.toInt() ?? 0,
      user: user,
    );
  }

  @override
  Future<AppUser> me() async {
    final token = _client.accessToken;
    if (token == null || token.isEmpty) {
      throw const UnauthorizedException('Требуется вход в систему');
    }
    return _profile(token);
  }

  @override
  Future<void> logout(String? refreshToken) async {
    final token = _client.accessToken;
    try {
      await _client.postRaw<dynamic>(
        '${ApiConfig.authUrl}/logout',
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        checkStatus: false,
      );
    } on ApiException catch (_) {}
  }
}

AppUser userFromRow(Map<String, dynamic> row) {
  return AppUser(
    id: row['id']?.toString() ?? '',
    username: row['username'] as String? ?? '',
    fullName: row['full_name'] as String? ?? '',
    email: row['email'] as String? ?? '',
    role: Role.fromApi(row['role'] as String?),
    customerId: (row['customer_id'] as num?)?.toInt(),
  );
}

class ApiUserRepository implements UserRepository {
  final ApiClient _client;

  ApiUserRepository(this._client);

  @override
  Future<PageResult<AppUser>> find({int page = 1, int size = 50}) async {
    final response = await _client.getRaw<dynamic>(
      'profiles',
      queryParameters: {
        'select': '*',
        'deleted_at': 'is.null',
        'order': 'username.asc',
        'limit': '$size',
        'offset': '${(page - 1) * size}',
      },
      headers: {'Prefer': 'count=exact'},
    );
    final rows = (response.data as List?) ?? const [];
    final range = response.headers.value('content-range') ?? '';
    final total = int.tryParse(range.split('/').last) ?? rows.length;
    return PageResult(
      items: [
        for (final row in rows)
          userFromRow(Map<String, dynamic>.from(row as Map)),
      ],
      page: page,
      size: size,
      total: total,
    );
  }

  @override
  Future<AppUser> changeRole(String id, Role role) async {
    final response = await _client.patchRaw<dynamic>(
      'profiles',
      data: {'role': role.apiName},
      queryParameters: {'id': 'eq.$id', 'select': '*'},
      headers: {'Prefer': 'return=representation'},
    );
    final rows = response.data;
    if (rows is List && rows.isNotEmpty) {
      return userFromRow(Map<String, dynamic>.from(rows.first as Map));
    }
    throw const NotFoundException();
  }

  @override
  Future<void> delete(String id) async {
    await _client.patchRaw<dynamic>(
      'profiles',
      data: {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      queryParameters: {'id': 'eq.$id'},
    );
  }
}
