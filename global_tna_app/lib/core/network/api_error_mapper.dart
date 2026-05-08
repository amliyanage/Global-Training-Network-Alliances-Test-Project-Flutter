import 'package:dio/dio.dart';
import '../exceptions/exceptions.dart';

class ApiErrorMapper {
  static ServerException mapDioException(
    DioException error, {
    required String fallbackMessage,
  }) {
    final data = error.response?.data;
    final status = error.response?.statusCode;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ServerException(
        message: 'Request timed out. Please try again.',
        errorCode: 'TIMEOUT',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ServerException(
        message: 'No internet connection. Check your network and retry.',
        errorCode: 'NETWORK_ERROR',
      );
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = _extractMessage(map) ?? fallbackMessage;
      final code = _extractErrorCode(map, status);
      return ServerException(message: message, errorCode: code);
    }

    if (data is String && data.trim().isNotEmpty) {
      return ServerException(
        message: data.trim(),
        errorCode: _statusToCode(status),
      );
    }

    return ServerException(
      message: fallbackMessage,
      errorCode: _statusToCode(status),
    );
  }

  static String? _extractMessage(Map<String, dynamic> map) {
    final primary = map['message'] ?? map['error'] ?? map['detail'];
    if (primary is String && primary.trim().isNotEmpty) return primary.trim();

    final errors = map['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
      if (first is Map) {
        final fieldError = Map<String, dynamic>.from(first);
        final msg = fieldError['msg'] ?? fieldError['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
    }

    if (errors is Map) {
      final entries = errors.entries.toList();
      if (entries.isNotEmpty) {
        final firstEntry = entries.first;
        final value = firstEntry.value;
        if (value is String && value.trim().isNotEmpty) {
          return '${firstEntry.key}: ${value.trim()}';
        }
      }
    }

    final data = map['data'];
    if (data is Map) {
      return _extractMessage(Map<String, dynamic>.from(data));
    }
    return null;
  }

  static String? _extractErrorCode(Map<String, dynamic> map, int? statusCode) {
    final code = map['errorCode'] ?? map['code'];
    if (code is String && code.trim().isNotEmpty) return code.trim();
    return _statusToCode(statusCode);
  }

  static String? _statusToCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'BAD_REQUEST';
      case 401:
        return 'UNAUTHORIZED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 409:
        return 'CONFLICT';
      case 422:
        return 'VALIDATION_ERROR';
      case 500:
      case 502:
      case 503:
        return 'SERVER_ERROR';
      default:
        return null;
    }
  }
}
