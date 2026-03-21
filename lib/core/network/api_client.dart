import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// A singleton HTTP client for Karakana by Kreative Karakana.
///
/// Wraps [Dio] with:
/// - Pre-configured base URL, connection timeout, and receive timeout.
/// - An interceptor that attaches the auth token, logs in debug mode,
///   and clears the token on 401 responses.
/// - Friendly error messages for common HTTP/network failures.
class ApiClient {
  ApiClient._internal();

  static final ApiClient _instance = ApiClient._internal();

  /// The single shared instance of [ApiClient].
  static ApiClient get instance => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late final Dio _dio = _buildDio();

  /// The underlying [Dio] instance, available for direct use if needed.
  Dio get dio => _dio;

  // ─────────────────────────────────────────────
  // Dio configuration
  // ─────────────────────────────────────────────

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(_AuthInterceptor(_storage));

    return dio;
  }

  // ─────────────────────────────────────────────
  // Convenience methods
  // ─────────────────────────────────────────────

  /// Sends a GET request to [path] and returns the parsed response.
  ///
  /// Throws a [String] with a friendly error message on failure.
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Sends a POST request to [path] with an optional [data] body.
  ///
  /// Throws a [String] with a friendly error message on failure.
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Sends a PUT request to [path] with an optional [data] body.
  ///
  /// Throws a [String] with a friendly error message on failure.
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Sends a PATCH request to [path] with an optional [data] body.
  ///
  /// Throws a [String] with a friendly error message on failure.
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Sends a DELETE request to [path].
  ///
  /// Throws a [String] with a friendly error message on failure.
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────
  // Error handling
  // ─────────────────────────────────────────────

  /// Converts a [DioException] into a user-friendly error message.
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        // Typically thrown when there is no internet connectivity.
        return 'No internet connection. Please check your connection.';

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            // Return the server's own error message when present.
            final body = e.response?.data;
            if (body is Map && body.containsKey('detail')) {
              return body['detail'].toString();
            }
            if (body is Map && body.isNotEmpty) {
              // Return the first field-level error message.
              final firstValue = body.values.first;
              if (firstValue is List && firstValue.isNotEmpty) {
                return firstValue.first.toString();
              }
              return firstValue.toString();
            }
            return 'Bad request. Please check your input.';
          case 401:
            return 'Session expired. Please login again.';
          case 403:
            return 'You do not have permission to do this.';
          case 404:
            return 'The requested resource was not found.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'Unexpected error (status $statusCode). Please try again.';
        }

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';

      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

// ─────────────────────────────────────────────
// Auth interceptor
// ─────────────────────────────────────────────

/// Intercepts every Dio request/response to:
///
/// 1. Attach `Authorization: Token <token>` when a token is stored.
/// 2. Log the request URL and response status code in debug mode.
/// 3. Clear the stored token when the server returns 401.
class _AuthInterceptor extends Interceptor {
  const _AuthInterceptor(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.tokenKey);

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Token $token';
    }

    if (kDebugMode) {
      debugPrint('[ApiClient] --> ${options.method} ${options.uri}');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[ApiClient] <-- ${response.statusCode} ${response.requestOptions.uri}',
      );
    }

    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token is no longer valid — remove it so the user is sent to login.
      await _storage.delete(key: AppConstants.tokenKey);

      if (kDebugMode) {
        debugPrint('[ApiClient] 401 received — auth token cleared.');
      }
    }

    handler.next(err);
  }
}
