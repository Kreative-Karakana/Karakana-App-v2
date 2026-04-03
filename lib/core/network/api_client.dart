import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../utils/secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio dio = _createDio();

  Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage().getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Token $token';
        }
        if (kDebugMode) {
          debugPrint('[API] --> ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
              '[API] <-- ${response.statusCode} ${response.requestOptions.uri}');
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint(
              '[API] ERROR ${error.response?.statusCode} ${error.requestOptions.uri}');
        }
        if (error.response?.statusCode == 401) {
          await SecureStorage().clearAll();
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  String parseError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        if (data.containsKey('detail')) return data['detail'].toString();
        if (data.containsKey('message')) return data['message'].toString();
        final firstKey = data.keys.first;
        final firstValue = data[firstKey];
        if (firstValue is List) return firstValue.first.toString();
        return firstValue.toString();
      }
      switch (error.response?.statusCode) {
        case 400:
          return 'Invalid request. Please check your input.';
        case 401:
          return 'Session expired. Please login again.';
        case 403:
          return 'You do not have permission to do this.';
        case 404:
          return 'The requested resource was not found.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.unknown) {
            return 'No internet connection. Please check your connection.';
          }
          return 'Something went wrong. Please try again.';
      }
    }
    return error.toString();
  }
}
