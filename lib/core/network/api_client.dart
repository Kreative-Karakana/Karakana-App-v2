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
        const authPaths = {
          '/api/auth/signin/',
          '/api/auth/signup/',
          '/api/auth/verify/',
          '/api/auth/verify/resend/',
          '/api/request-password-reset/',
          '/api/oauth/',
          '/api/apple-oauth/',
        };
        final shouldAttachToken = !authPaths.contains(options.path);
        final token =
            shouldAttachToken ? await SecureStorage().getToken() : null;
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
          debugPrint('[API] ERROR BODY: ${error.response?.data}');
          debugPrint('[API] ERROR TYPE: ${error.type}');
          debugPrint('[API] ERROR MESSAGE: ${error.message}');
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
          return 'Ombi si sahihi. Tafadhali hakiki taarifa zako.';
        case 401:
          return 'Muda wa kikao umeisha. Tafadhali ingia tena.';
        case 403:
          return 'Huna ruhusa ya kufanya hili.';
        case 404:
          return 'Taarifa ulizoomba hazikupatikana.';
        case 500:
          return 'Hitilafu ya seva. Tafadhali jaribu tena baadaye.';
        default:
          if (error.type == DioExceptionType.connectionTimeout) {
            return 'Muunganisho umechelewa (connection timeout). Jaribu tena.';
          }
          if (error.type == DioExceptionType.receiveTimeout) {
            return 'Seva imechelewa kujibu (receive timeout). Jaribu tena.';
          }
          if (error.type == DioExceptionType.sendTimeout) {
            return 'Kutuma ombi kumechelewa (send timeout). Jaribu tena.';
          }
          if (error.type == DioExceptionType.badCertificate) {
            return 'Hitilafu ya usalama wa cheti cha seva. Wasiliana na msaada.';
          }
          if (error.type == DioExceptionType.cancel) {
            return 'Ombi limeghairiwa kabla ya kukamilika. Jaribu tena.';
          }
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.unknown) {
            return 'Hakuna muunganisho wa intaneti. Tafadhali angalia mtandao wako.';
          }
          return 'Kuna hitilafu imetokea. Tafadhali jaribu tena.';
      }
    }
    return 'Kuna hitilafu imetokea. Tafadhali jaribu tena.';
  }
}
