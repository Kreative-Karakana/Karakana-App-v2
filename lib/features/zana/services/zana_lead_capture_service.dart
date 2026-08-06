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
  final Map<String, String> fieldErrors;

  const ZanaLeadCaptureException(
    this.message, {
    this.fieldErrors = const {},
  });

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
      throw ZanaLeadCaptureException(
        _parseError(error),
        fieldErrors: _parseFieldErrors(error),
      );
    }
  }

  Map<String, String> _parseFieldErrors(Object error) {
    if (error is! DioException || error.response?.statusCode != 400) {
      return const {};
    }

    final data = error.response?.data;
    if (data is! Map) return const {};

    final errors = <String, String>{};
    for (final field in const ['name', 'phone']) {
      if (!data.containsKey(field)) continue;
      errors[field] = switch (field) {
        'name' => 'Jina si sahihi. Tafadhali hakiki jina lako.',
        'phone' => 'Nambari ya simu si sahihi. Tumia mfano 0712345678.',
        _ => _parseError(error),
      };
    }
    return errors;
  }
}
