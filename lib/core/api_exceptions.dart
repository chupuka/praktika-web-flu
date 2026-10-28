import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте, запущен ли mock-сервер',
  ]);
}

class TimeoutException extends ApiException {
  const TimeoutException([
    super.message = 'Превышено время ожидания ответа сервера',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    super.message = 'Требуется вход в систему',
  ]);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этой операции',
  ]);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена']);
}

class ConflictException extends ApiException {
  const ConflictException(
      [super.message = 'Операция конфликтует с текущим состоянием']);
}

class ServerException extends ApiException {
  const ServerException([super.message = 'Ошибка сервера']);
}

class ApiCancelled extends ApiException {
  const ApiCancelled([super.message = 'Запрос отменён']);
}

class UnknownApiException extends ApiException {
  const UnknownApiException([super.message = 'Неизвестная ошибка запроса']);
}

class ValidationException extends ApiException {
  final Map<String, String> fieldErrors;

  const ValidationException(super.message, this.fieldErrors);

  String? errorFor(String field) => fieldErrors[field];
}

ApiException mapHttpError(int statusCode, dynamic data) {
  String message = 'Ошибка запроса';
  final errors = <String, String>{};

  if (data is Map) {
    final raw = data['message'];
    if (raw is String && raw.isNotEmpty) message = raw;
    final rawErrors = data['errors'];
    if (rawErrors is Map) {
      for (final entry in rawErrors.entries) {
        errors[entry.key.toString()] = entry.value.toString();
      }
    }
  }

  switch (statusCode) {
    case 400:
      return ValidationException(message, errors);
    case 401:
      return UnauthorizedException(message);
    case 403:
      return ForbiddenException(message);
    case 404:
      return NotFoundException(message);
    case 409:
      return ConflictException(message);
    case 422:
      return ValidationException(message, errors);
    default:
      if (statusCode >= 500) return ServerException(message);
      return UnknownApiException(message);
  }
}

ApiException mapDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutException();
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return const NetworkException();
    case DioExceptionType.badResponse:
      final response = error.response;
      if (response == null) return const ServerException();
      return mapHttpError(response.statusCode ?? 500, response.data);
    case DioExceptionType.cancel:
      return const ApiCancelled('Запрос отменён');
    case DioExceptionType.badCertificate:
      return const NetworkException('Сертификат сервера отклонён');
  }
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on ApiException {
    rethrow;
  } on DioException catch (e) {
    throw mapDioError(e);
  } catch (e) {
    throw UnknownApiException(e.toString());
  }
}
