import 'dart:async';

import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio _dio;
  String? _accessToken;

  Future<bool> Function()? onUnauthorized;

  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                validateStatus: (status) => status != null && status < 500,
                headers: {
                  'Content-Type': 'application/json',
                  'apikey': ApiConfig.anonKey,
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null &&
              _accessToken!.isNotEmpty &&
              options.headers['Authorization'] == null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          final options = response.requestOptions;
          final isAuthPath = options.path.contains('/auth/');
          final alreadyRetried = options.extra['retriedAfterRefresh'] == true;
          final callback = onUnauthorized;
          if (response.statusCode != 401 ||
              isAuthPath ||
              alreadyRetried ||
              callback == null) {
            return handler.next(response);
          }
          final refreshed = await callback();
          if (!refreshed) return handler.next(response);

          options.extra['retriedAfterRefresh'] = true;
          options.headers['Authorization'] = 'Bearer $_accessToken';
          try {
            final retried = await _dio.fetch<dynamic>(options);
            return handler.resolve(retried);
          } catch (_) {
            return handler.next(response);
          }
        },
      ),
    );
  }

  Dio get dio => _dio;

  String? get accessToken => _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
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

  Future<Response<T>> getRaw<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool checkStatus = true,
  }) {
    return _withRetry(
      () => guard(
        () async {
          final response = await _dio.get<T>(
            path,
            queryParameters: queryParameters,
            options: Options(headers: headers),
            cancelToken: cancelToken,
          );
          if (checkStatus) _ensureOk(response);
          return response;
        },
      ),
    );
  }

  Future<Response<T>> postRaw<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool checkStatus = true,
  }) {
    return guard(
      () async {
        final response = await _dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: Options(headers: headers),
          cancelToken: cancelToken,
        );
        if (checkStatus) _ensureOk(response);
        return response;
      },
    );
  }

  Future<Response<T>> patchRaw<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool checkStatus = true,
  }) {
    return guard(
      () async {
        final response = await _dio.patch<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: Options(headers: headers),
          cancelToken: cancelToken,
        );
        if (checkStatus) _ensureOk(response);
        return response;
      },
    );
  }

  Future<Response<T>> deleteRaw<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool checkStatus = true,
  }) {
    return guard(
      () async {
        final response = await _dio.delete<T>(
          path,
          queryParameters: queryParameters,
          options: Options(headers: headers),
          cancelToken: cancelToken,
        );
        if (checkStatus) _ensureOk(response);
        return response;
      },
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

  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return guard(
      () async {
        final response = await _dio.patch<T>(
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
