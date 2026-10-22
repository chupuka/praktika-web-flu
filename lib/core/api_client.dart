import 'dart:async';

import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio _dio;
  String? _accessToken;

  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                validateStatus: (status) => status != null && status < 500,
                headers: {'Content-Type': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null && _accessToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
      ),
    );
  }

  Dio get dio => _dio;

  String? get accessToken => _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      final data = response.data ?? const <String, dynamic>{};
      _accessToken = data['accessToken'] as String?;
      return data;
    });
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _withRetry(
      () => guard(
        () async {
          final response = await _dio.get<T>(
            path,
            queryParameters: queryParameters,
            cancelToken: cancelToken,
          );
          return _unwrap(response);
        },
      ),
    );
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return guard(
      () async {
        final response = await _dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
        );
        return _unwrap(response);
      },
    );
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return guard(
      () async {
        final response = await _dio.put<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
        );
        return _unwrap(response);
      },
    );
  }

  Future<void> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return guard(
      () async {
        final response = await _dio.delete<dynamic>(
          path,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
        );
        _ensureOk(response);
      },
    );
  }

  T _unwrap<T>(Response<T> response) {
    _ensureOk(response);
    return response.data as T;
  }

  void _ensureOk(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      throw mapHttpError(status, response.data);
    }
  }

  Future<T> _withRetry<T>(Future<T> Function() action) async {
    var attempt = 0;
    while (true) {
      try {
        return await action();
      } on ApiException catch (e) {
        attempt += 1;
        final retryable = e is NetworkException || e is TimeoutException;
        if (!retryable || attempt >= ApiConfig.maxRetries) rethrow;
        final delay = ApiConfig.retryBaseDelay * attempt;
        await Future<void>.delayed(delay);
      }
    }
  }
}
