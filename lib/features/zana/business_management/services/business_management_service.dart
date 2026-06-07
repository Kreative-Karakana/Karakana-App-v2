import '../../../../core/network/api_client.dart';
import '../models/business.dart';
import '../models/business_dashboard_summary.dart';
import '../models/business_transaction.dart';

class BusinessManagementService {
  final _dio = ApiClient().dio;

  Future<Business?> getMyBusiness() async {
    final response = await _dio.get('/api/v1/businesses/me/');
    final data = response.data;
    if (data is Map) {
      return Business.fromJson(data.cast<String, dynamic>());
    }
    return null;
  }

  Future<Business> createBusiness({
    required String name,
    required String businessType,
  }) async {
    final response = await _dio.post(
      '/api/v1/businesses/',
      data: {
        'name': name,
        'business_type': businessType,
      },
    );
    return Business.fromJson((response.data as Map).cast<String, dynamic>());
  }

  Future<Business> updateBusiness({
    required String name,
    required String businessType,
  }) async {
    final response = await _dio.patch(
      '/api/v1/businesses/me/',
      data: {
        'name': name,
        'business_type': businessType,
      },
    );
    return Business.fromJson((response.data as Map).cast<String, dynamic>());
  }

  Future<BusinessDashboardSummary> getDashboard() async {
    final response = await _dio.get('/api/v1/businesses/dashboard/');
    return BusinessDashboardSummary.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  Future<List<BusinessTransaction>> getTransactions({
    String? transactionType,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final response = await _dio.get(
      '/api/v1/businesses/transactions/',
      queryParameters: {
        if (transactionType != null && transactionType.isNotEmpty)
          'transaction_type': transactionType,
        if (category != null && category.isNotEmpty) 'category': category,
        if (dateFrom != null) 'date_from': _dateOnly(dateFrom),
        if (dateTo != null) 'date_to': _dateOnly(dateTo),
      },
    );
    final data = response.data;
    final List results;
    if (data is Map && data['results'] is List) {
      results = data['results'] as List;
    } else if (data is List) {
      results = data;
    } else {
      results = const [];
    }

    return results
        .whereType<Map>()
        .map((item) =>
            BusinessTransaction.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<BusinessTransaction> createTransaction({
    required String transactionType,
    required String amount,
    required String category,
    required DateTime transactionDate,
    String description = '',
  }) async {
    final response = await _dio.post(
      '/api/v1/businesses/transactions/',
      data: {
        'transaction_type': transactionType,
        'amount': amount,
        'category': category,
        'description': description,
        'transaction_date': _dateOnly(transactionDate),
      },
    );
    return BusinessTransaction.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  Future<BusinessTransaction> updateTransaction({
    required int id,
    String? transactionType,
    String? amount,
    String? category,
    DateTime? transactionDate,
    String? description,
  }) async {
    final response = await _dio.patch(
      '/api/v1/businesses/transactions/$id/',
      data: {
        if (transactionType != null) 'transaction_type': transactionType,
        if (amount != null) 'amount': amount,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        if (transactionDate != null)
          'transaction_date': _dateOnly(transactionDate),
      },
    );
    return BusinessTransaction.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  Future<void> deleteTransaction(int id) async {
    await _dio.delete('/api/v1/businesses/transactions/$id/');
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
}
