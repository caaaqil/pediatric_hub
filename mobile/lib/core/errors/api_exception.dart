import 'package:dio/dio.dart';

/// A field-level validation failure as produced by
/// `backend/src/middlewares/validateRequest.js`:
/// `{ field: 'email', message: 'Invalid email format' }`.
class FieldError {
  const FieldError({required this.field, required this.message});

  final String field;
  final String message;

  factory FieldError.fromJson(Map<String, dynamic> json) {
    return FieldError(
      field: json['field']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}

/// Normalised error for every failed backend call.
///
/// The backend always answers errors as
/// `{ status: 'error', message: '...', errors?: [{field, message}] }`
/// (see `backend/src/utils/responseWrapper.js`).
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const <FieldError>[],
  });

  final String message;
  final int? statusCode;
  final List<FieldError> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  /// Validation errors flattened into one readable line.
  String get detailedMessage {
    if (fieldErrors.isEmpty) return message;
    final String details = fieldErrors
        .map((FieldError e) => e.message)
        .join('\n');
    return '$message\n$details';
  }

  factory ApiException.fromDio(DioException error) {
    final Response<dynamic>? response = error.response;

    if (response != null) {
      final dynamic body = response.data;
      String message = 'Request failed (${response.statusCode}).';
      List<FieldError> fields = const <FieldError>[];

      if (body is Map) {
        final dynamic rawMessage = body['message'];
        if (rawMessage is String && rawMessage.trim().isNotEmpty) {
          message = rawMessage;
        }
        final dynamic rawErrors = body['errors'];
        if (rawErrors is List) {
          fields = rawErrors
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> e) =>
                    FieldError.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
        }
      } else if (body is String && body.trim().isNotEmpty) {
        message = body;
      }

      return ApiException(
        message,
        statusCode: response.statusCode,
        fieldErrors: fields,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'The server took too long to respond. Check that the backend is running.',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          'Cannot reach the server. Check your API base URL and that the backend is running on port 3000.',
        );
      case DioExceptionType.cancel:
        return const ApiException('The request was cancelled.');
      case DioExceptionType.badCertificate:
        return const ApiException('The server certificate was rejected.');
      case DioExceptionType.badResponse:
        return const ApiException(
          'The server returned an unexpected response.',
        );
      default:
        return const ApiException(
          'Something went wrong talking to the server.',
        );
    }
  }

  @override
  String toString() => message;
}
