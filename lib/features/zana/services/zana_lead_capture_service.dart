import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

abstract class ZanaLeadCaptureService {
  Future<void> captureLead({
    required String name,
    required String phone,
    required String source,
  });
}

class ZanaLeadCaptureException implements Exception {
  final String message;

  const ZanaLeadCaptureException(this.message);

  @override
  String toString() => message;
}

class ApiZanaLeadCaptureService implements ZanaLeadCaptureService {
  final Dio _dio;
  final String Function(Object error) _parseError;

  ApiZanaLeadCaptureService({
    Dio? dio,
    String Function(Object error)? parseError,
  })  : _dio = dio ?? ApiClient().dio,
        _parseError = parseError ?? ApiClient().parseError;

  @override
  Future<void> captureLead({
    required String name,
    required String phone,
    required String source,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.zanaLeads,
        data: {
          'name': name,
          'phone': phone,
          'source': source,
        },
      );
    } catch (error) {
      throw ZanaLeadCaptureException(_parseError(error));
    }
  }
}
