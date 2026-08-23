import '../../../core/network/api_client.dart';

abstract class CourseCheckoutApi {
  Future<Map<String, dynamic>> createCheckout({
    required int courseId,
    required String accountNumber,
    required String provider,
  });

  Future<Map<String, dynamic>?> findActiveAttempt(int courseId);

  Future<Map<String, dynamic>> getPaymentStatus(String externalId);
}

class ApiCourseCheckoutService implements CourseCheckoutApi {
  @override
  Future<Map<String, dynamic>> createCheckout({
    required int courseId,
    required String accountNumber,
    required String provider,
  }) async {
    final response = await ApiClient().dio.post(
      '/api/v1/payments/checkout/',
      data: {
        'accountNumber': accountNumber,
        'provider': provider,
        'course_id': courseId,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<Map<String, dynamic>?> findActiveAttempt(int courseId) async {
    final response = await ApiClient().dio.get(
      '/api/v1/payments/checkout/',
      queryParameters: {'course_id': courseId, 'active': true},
    );
    final data = response.data;
    final rows =
        data is Map ? (data['results'] as List? ?? const []) : data as List;
    if (rows.isEmpty || rows.first is! Map) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  @override
  Future<Map<String, dynamic>> getPaymentStatus(String externalId) async {
    final response = await ApiClient().dio.get('/api/v1/payments/$externalId/');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
