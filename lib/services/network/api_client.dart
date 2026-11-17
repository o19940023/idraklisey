import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';

/// Mobile API client for `/api/mobile/v1`.
///
/// Responsibilities:
/// - bearer token injection
/// - JSON envelope unwrapping (`{success, data, message, errors, meta}`)
/// - normalized [ApiException] with field level 422 errors
/// - 401 auto-logout hook
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: const {'Accept': 'application/json'},
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _token();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            unawaited(_onUnauthorized?.call());
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          error: true,
          compact: true,
          maxWidth: 120,
        ),
      );
    }
  }

  static final ApiClient instance = ApiClient._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );
  static const _tokenKey = 'api_bearer_token';
  static const _baseUrlKey = 'api_base_url_override';

  late final Dio _dio;

  Future<void> Function()? _onUnauthorized;

  String get baseUrl => _dio.options.baseUrl;

  /// Loads a user configured base URL (set from the login screen).
  Future<void> loadSavedBaseUrl() async {
    final saved = await _storage.read(key: _baseUrlKey);
    if (saved == null || saved.isEmpty) return;
    if (!AppConfig.isAllowed(saved)) return;
    _dio.options.baseUrl = saved;
  }

  /// Persists a new base URL and validates it against the production guard.
  Future<void> setBaseUrl(String url) async {
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    AppConfig.assertSafe(normalized);
    _dio.options.baseUrl = normalized;
    await _storage.write(key: _baseUrlKey, value: normalized);
  }

  /// Clears the saved override and restores the platform default URL.
  Future<void> resetBaseUrl() async {
    await _storage.delete(key: _baseUrlKey);
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
  }

  /// Returns true when the given base URL answers HTTP requests
  /// (a 401 from `auth/me` still proves the server is reachable).
  Future<bool> probe(String url) async {
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (!AppConfig.isAllowed(normalized)) return false;

    final probeDio = Dio(BaseOptions(
      baseUrl: normalized,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: const {'Accept': 'application/json'},
    ));

    try {
      await probeDio.get('auth/me');
      return true;
    } on DioException catch (error) {
      return error.response != null;
    } catch (_) {
      return false;
    }
  }

  void setUnauthorizedHandler(Future<void> Function() handler) {
    _onUnauthorized = handler;
  }

  Future<String?> _token() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<bool> hasToken() async {
    final token = await _token();
    return token != null && token.isNotEmpty;
  }

  // -----------------------------------------------------------------
  // Verbs
  // -----------------------------------------------------------------

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _request('GET', path, query: query);

  Future<dynamic> post(String path, {Object? data}) =>
      _request('POST', path, data: data);

  Future<dynamic> put(String path, {Object? data}) =>
      _request('PUT', path, data: data);

  Future<dynamic> delete(String path, {Object? data}) =>
      _request('DELETE', path, data: data);

  // -----------------------------------------------------------------
  // Core
  // -----------------------------------------------------------------

  String _normalizePath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    var base = _dio.options.baseUrl.trim();
    if (!base.endsWith('/')) {
      base = '$base/';
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$base$cleanPath';
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? data,
  }) async {
    try {
      final normalizedUrl = _normalizePath(path);
      final response = await _dio.request<dynamic>(
        normalizedUrl,
        data: data,
        queryParameters: query,
        options: Options(method: method),
      );

      return _unwrap(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  dynamic _unwrap(dynamic body) {
    if (body is Map<String, dynamic>) {
      final success = body['success'];
      if (success == false) {
        throw ApiException(
          message: (body['message'] as String?) ?? 'Xəta baş verdi.',
          statusCode: 422,
          errors: _parseErrors(body['errors']),
        );
      }

      if (body.containsKey('data')) {
        return body;
      }
    }

    return body;
  }

  Map<String, List<String>>? _parseErrors(dynamic raw) {
    if (raw is! Map) return null;

    final result = <String, List<String>>{};
    raw.forEach((key, value) {
      if (value is List) {
        result[key.toString()] = value.map((e) => e.toString()).toList();
      } else if (value != null) {
        result[key.toString()] = [value.toString()];
      }
    });

    return result;
  }
}
