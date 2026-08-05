import '../../../../core/network/api_client.dart';
import '../models/business_debt.dart';

class PaginatedDebts {
  final List<BusinessDebt> items;
  final int count;
  final String? next;
  final String? previous;

  const PaginatedDebts({
    required this.items,
    required this.count,
    required this.next,
    required this.previous,
  });

  bool get hasNext => next != null && next!.isNotEmpty;

  factory PaginatedDebts.fromJson(dynamic data) {
    if (data is Map) {
      final results = data['results'];
      final rawItems = results is List ? results : const [];
      return PaginatedDebts(
        items: rawItems
            .whereType<Map>()
            .map((item) => BusinessDebt.fromJson(
                  item.cast<String, dynamic>(),
                ))
            .toList(),
        count: data['count'] is int ? data['count'] as int : rawItems.length,
        next: data['next']?.toString(),
        previous: data['previous']?.toString(),
      );
    }

    final rawItems = data is List ? data : const [];
    final items = rawItems
        .whereType<Map>()
        .map((item) => BusinessDebt.fromJson(item.cast<String, dynamic>()))
        .toList();
    return PaginatedDebts(
      items: items,
      count: items.length,
      next: null,
      previous: null,
    );
  }
}

abstract class DebtManagementApi {
  Future<PaginatedDebts> getDebtsPage({
    String? status,
    int page = 1,
    int pageSize = 20,
  });

  Future<BusinessDebt> createDebt({
    required String customerName,
    required String amount,
    required DateTime dateGiven,
    String itemService = '',
    String note = '',
    DateTime? dueDate,
    String status = 'outstanding',
  });

  Future<BusinessDebt> updateDebt({
    required int id,
    String? customerName,
    String? amount,
    String? itemService,
    String? note,
    DateTime? dateGiven,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? status,
  });

  Future<void> deleteDebt(int id);
}

class DebtManagementService implements DebtManagementApi {
  final _dio = ApiClient().dio;

  @override
  Future<PaginatedDebts> getDebtsPage({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/api/v1/businesses/debts/',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'page_size': pageSize,
      },
    );
    return PaginatedDebts.fromJson(response.data);
  }

  @override
  Future<BusinessDebt> createDebt({
    required String customerName,
    required String amount,
    required DateTime dateGiven,
    String itemService = '',
    String note = '',
    DateTime? dueDate,
    String status = 'outstanding',
  }) async {
    final response = await _dio.post(
      '/api/v1/businesses/debts/',
      data: {
        'customer_name': customerName,
        'amount': amount,
        'item_service': itemService,
        'note': note,
        'date_given': _dateOnly(dateGiven),
        'due_date': dueDate == null ? null : _dateOnly(dueDate),
        'status': status,
      },
    );
    return BusinessDebt.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<BusinessDebt> updateDebt({
    required int id,
    String? customerName,
    String? amount,
    String? itemService,
    String? note,
    DateTime? dateGiven,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? status,
  }) async {
    final response = await _dio.patch(
      '/api/v1/businesses/debts/$id/',
      data: {
        if (customerName != null) 'customer_name': customerName,
        if (amount != null) 'amount': amount,
        if (itemService != null) 'item_service': itemService,
        if (note != null) 'note': note,
        if (dateGiven != null) 'date_given': _dateOnly(dateGiven),
        if (clearDueDate) 'due_date': null,
        if (!clearDueDate && dueDate != null) 'due_date': _dateOnly(dueDate),
        if (status != null) 'status': status,
      },
    );
    return BusinessDebt.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<void> deleteDebt(int id) async {
    await _dio.delete('/api/v1/businesses/debts/$id/');
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
}
