import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_config.dart';
import '../auth/permissions.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../models/role.dart';
import '../repositories/auth_repository.dart';

enum SessionEndReason {
  manual,
  idle,
  absolute,
  expired,
}

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user';
  static const _kStartedAt = 'auth_started_at';

  final SharedPreferences _prefs;
  final AuthRepository _api;
  final ApiClient _client;

  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _startedAt;
  SessionEndReason? _endedReason;
  Timer? _absoluteTimer;
  Future<void>? _refreshing;
  bool _loggingOut = false;

  AuthNotifier({
    required SharedPreferences prefs,
    required AuthRepository api,
    required ApiClient client,
  })  : _prefs = prefs,
        _api = api,
        _client = client {
    _client.onUnauthorized = _refreshAfterUnauthorized;
  }

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;
  SessionEndReason? get endedReason => _endedReason;
  DateTime? get sessionStartedAt => _startedAt;
  DateTime? get sessionExpiresAt => _startedAt?.add(AuthConfig.sessionLimit);

  bool has(Role role) => _user != null && _user!.role.atLeast(role);
  bool can(Permission permission) =>
      _user != null && Permissions.can(_user!.role, permission);

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    if (access == null || access.isEmpty) return;

    _accessToken = access;
    _refreshToken = refresh;
    _client.setAccessToken(access);
    _startedAt = DateTime.tryParse(_prefs.getString(_kStartedAt) ?? '');

    final cachedUser = _prefs.getString(_kUser);
    if (cachedUser != null) {
      try {
        _user = AppUser.fromJson(
          Map<String, dynamic>.from(jsonDecode(cachedUser) as Map),
        );
      } catch (_) {
        _user = null;
      }
    }

    if (_user == null) {
      try {
        _user = await _api.me();
        await _storeUser(_user!);
      } on ApiException {
        await logout(reason: SessionEndReason.expired);
        return;
      }
    }

    if (_startedAt == null) {
      _startedAt = DateTime.now();
      await _prefs.setString(_kStartedAt, _startedAt!.toIso8601String());
    }

    if (_isSessionLimitReached()) {
      await logout(reason: SessionEndReason.absolute);
      return;
    }

    _scheduleAbsoluteLimit();
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final session = await _api.login(username, password);
    await _applySession(session, newSession: true);
  }

  Future<void> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) async {
    final session = await _api.register(
      username: username,
      password: password,
      fullName: fullName,
      email: email,
    );
    await _applySession(session, newSession: true);
  }

  Future<void> refreshTokens() {
    final pending = _refreshing;
    if (pending != null) return pending;
    final future = _refresh();
    _refreshing = future;
    return future.whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
  }

  Future<void> _refresh() async {
    final token = _refreshToken;
    if (token == null || token.isEmpty) {
      throw const UnauthorizedException('Сессия истекла');
    }
    final session = await _api.refresh(token);
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _user = session.user;
    _client.setAccessToken(session.accessToken);
    await _prefs.setString(_kAccess, session.accessToken);
    await _prefs.setString(_kRefresh, session.refreshToken);
    await _storeUser(session.user);
    notifyListeners();
  }

  Future<void> logout({SessionEndReason reason = SessionEndReason.manual}) async {
    if (_loggingOut) return;
    _loggingOut = true;
    final refresh = _refreshToken;
    _absoluteTimer?.cancel();
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _startedAt = null;
    _client.setAccessToken(null);
    _endedReason = reason;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kStartedAt);
    notifyListeners();
    try {
      if (refresh != null) await _api.logout(refresh);
    } on ApiException catch (_) {
      _loggingOut = false;
      return;
    }
    _loggingOut = false;
  }

  Future<void> _applySession(
    AuthSession session, {
    required bool newSession,
  }) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _user = session.user;
    _client.setAccessToken(session.accessToken);
    if (newSession || _startedAt == null) {
      _startedAt = DateTime.now();
      await _prefs.setString(_kStartedAt, _startedAt!.toIso8601String());
    }
    await _prefs.setString(_kAccess, session.accessToken);
    await _prefs.setString(_kRefresh, session.refreshToken);
    await _storeUser(session.user);
    _endedReason = null;
    _scheduleAbsoluteLimit();
    notifyListeners();
  }

  Future<void> _storeUser(AppUser user) async {
    await _prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  Future<bool> _refreshAfterUnauthorized() async {
    if (_refreshToken == null) return false;
    try {
      await refreshTokens();
      return true;
    } on ApiException {
      await logout(reason: SessionEndReason.expired);
      return false;
    } catch (_) {
      await logout(reason: SessionEndReason.expired);
      return false;
    }
  }

  bool _isSessionLimitReached() {
    final started = _startedAt;
    if (started == null) return false;
    return DateTime.now().difference(started) >= AuthConfig.sessionLimit;
  }

  void _scheduleAbsoluteLimit() {
    _absoluteTimer?.cancel();
    final started = _startedAt;
    if (started == null) return;
    final remaining = AuthConfig.sessionLimit - DateTime.now().difference(started);
    if (remaining <= Duration.zero) {
      logout(reason: SessionEndReason.absolute);
      return;
    }
    _absoluteTimer = Timer(
      remaining,
      () => logout(reason: SessionEndReason.absolute),
    );
  }

  @override
  void dispose() {
    _absoluteTimer?.cancel();
    if (identical(_client.onUnauthorized, _refreshAfterUnauthorized)) {
      _client.onUnauthorized = null;
    }
    super.dispose();
  }
}
