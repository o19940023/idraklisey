import 'package:dio/dio.dart';

/// Normalized API error mapped from the mobile JSON envelope / HTTP status.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>>? errors;
  final bool isNetworkError;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isValidation => statusCode == 422;

  /// First validation message for a specific field, if any.
  String? fieldError(String field) {
    final list = errors?[field];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    String message = 'Xəta baş verdi.';
    Map<String, List<String>>? errors;

    if (data is Map) {
      final rawMessage = data['message'];
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        message = rawMessage;
      }

      final rawErrors = data['errors'];
      if (rawErrors is Map) {
        errors = {};
        rawErrors.forEach((key, value) {
          if (value is List) {
            errors![key.toString()] = value.map((e) => e.toString()).toList();
          } else if (value != null) {
            errors![key.toString()] = [value.toString()];
          }
        });
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Server cavab vermədi. İnternet bağlantısını yoxlayın.',
          statusCode: response?.statusCode,
          isNetworkError: true,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Serverə qoşulmaq mümkün olmadı. Lokal API işləyirmi?',
          statusCode: response?.statusCode,
          isNetworkError: true,
        );
      case DioExceptionType.cancel:
        return ApiException(message: 'Sorğu ləğv edildi.', statusCode: response?.statusCode);
      default:
        // A 404/405 from the mobile API almost always means the base URL in
        // the app is wrong or mis-typed (e.g. missing `/api/mobile/v1`).
        if (response?.statusCode == 404 || response?.statusCode == 405) {
          return ApiException(
            message: 'Mobil API ünvanı yanlışdır. Sağ yuxarıdakı server '
                'ikonundan ünvanı düzəldin (emulyator: http://10.0.2.2:8000/api/mobile/v1).',
            statusCode: response?.statusCode,
            errors: errors,
          );
        }

        return ApiException(
          message: message,
          statusCode: response?.statusCode,
          errors: errors,
        );
    }
  }

  @override
  String toString() => message;
}
