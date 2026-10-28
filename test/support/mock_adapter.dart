import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class MockResponse {
  final int statusCode;
  final Object? body;
  final Map<String, List<String>> headers;

  const MockResponse(
    this.statusCode, {
    this.body,
    this.headers = const {},
  });
}

class RecordedRequest {
  final String method;
  final String path;
  final Map<String, dynamic> query;
  final Object? data;
  final Map<String, dynamic> headers;

  const RecordedRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.data,
    required this.headers,
  });

  @override
  String toString() => '$method $path ${jsonEncode(query)}';
}

class MockAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  final List<Object> queue = [];

  void enqueue(MockResponse response) {
    queue.add(response);
  }

  void enqueueJson(int statusCode, Object body) {
    queue.add(MockResponse(statusCode, body: body));
  }

  void enqueueError(Object error) {
    queue.add(error);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      RecordedRequest(
        method: options.method,
        path: options.path,
        query: Map<String, dynamic>.from(options.queryParameters),
        data: options.data,
        headers: Map<String, dynamic>.from(options.headers),
      ),
    );

    if (queue.isEmpty) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'mock: очередь ответов пуста',
      );
    }

    final next = queue.removeAt(0);
    if (next is DioException) {
      throw next.copyWith(requestOptions: options);
    }

    final response = next as MockResponse;
    final payload = response.body == null ? '' : jsonEncode(response.body);

    return ResponseBody.fromString(
      payload,
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...response.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
