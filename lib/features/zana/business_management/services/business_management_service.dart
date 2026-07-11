import '../../../../core/network/api_client.dart';
import '../models/business.dart';
import '../models/business_dashboard_summary.dart';
import '../models/business_transaction.dart';

class PaginatedTransactions {
  final List<BusinessTransaction> items;
  final int count;
  final String? next;
  final String? previous;

  const PaginatedTransactions({
    required this.items,
    required this.count,
    required this.next,
    required this.previous,
  });

  bool get hasNext => next != null && next!.isNotEmpty;

  factory PaginatedTransactions.fromJson(dynamic data) {
    if (data is Map) {
      final results = data['results'];
      final items = results is List ? results : const [];
      return PaginatedTransactions(
        items: items
            .whereType<Map>()
            .map((j) => BusinessTransaction.fromJson(j.cast<String, dynamic>()))
            .toList(),
        count: data['count'] is int ? data['count'] as int : items.length,
        next: data['next']?.toString(),
        previous: data['previous']?.toString(),
      );
    }

    final items = data is List ? data : const [];
    final parsed = items
        .whereType<Map>()
        .map((j) => BusinessTransaction.fromJson(j.cast<String, dynamic>()))
        .toList();
    return PaginatedTransactions(
      items: parsed,
      count: parsed.length,
      next: null,
      previous: null,
    );
  }
}

abstract class BusinessManagementApi {
  Future<Business?> getMyBusiness();

  Future<Business> createBusiness({
    required String name,
    required String businessType,
  });

  Future<Business> updateBusiness({
    required String name,
    required String businessType,
  });

  Future<BusinessDashboardSummary> getDashboard();

  Future<PaginatedTransactions> getTransactionsPage({
    String? transactionType,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 20,
  });

  Future<BusinessTransaction> createTransaction({
    required String transactionType,
    required String amount,
    required String category,
    required DateTime transactionDate,
    String description = '',
  });

  Future<BusinessTransaction> updateTransaction({
    required int id,
    String? transactionType,
    String? amount,
    String? category,
    DateTime? transactionDate,
    String? description,
  });

  Future<void> deleteTransaction(int id);
}

class BusinessManagementService implements BusinessManagementApi {
  final _dio = ApiClient().dio;

  @override
  Future<Business?> getMyBusiness() async {
    final response = await _dio.get('/api/v1/businesses/me/');
    final data = response.data;
    if (data is Map) {
      return Business.fromJson(data.cast<String, dynamic>());
    }
    return null;
  }

  @override
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

  @override
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

  @override
  Future<BusinessDashboardSummary> getDashboard() async {
    final response = await _dio.get('/api/v1/businesses/dashboard/');
    return BusinessDashboardSummary.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<PaginatedTransactions> getTransactionsPage({
    String? transactionType,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/api/v1/businesses/transactions/',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (transactionType != null && transactionType.isNotEmpty)
          'transaction_type': transactionType,
        if (category != null && category.isNotEmpty) 'category': category,
        if (dateFrom != null) 'date_from': _dateOnly(dateFrom),
        if (dateTo != null) 'date_to': _dateOnly(dateTo),
      },
    );
    return PaginatedTransactions.fromJson(response.data);
  }

  @override
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

  @override
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

  @override
  Future<void> deleteTransaction(int id) async {
    await _dio.delete('/api/v1/businesses/transactions/$id/');
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
}
