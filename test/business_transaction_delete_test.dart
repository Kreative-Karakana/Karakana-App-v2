import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/zana/business_management/models/business.dart';
import 'package:karakana_app/features/zana/business_management/models/business_dashboard_summary.dart';
import 'package:karakana_app/features/zana/business_management/models/business_transaction.dart';
import 'package:karakana_app/features/zana/business_management/providers/business_management_provider.dart';
import 'package:karakana_app/features/zana/business_management/services/business_management_service.dart';

void main() {
  group('BusinessManagementProvider.deleteTransaction', () {
    test('successful delete removes the transaction and refreshes data',
        () async {
      final service = _FakeService(
        transactionsPage: _page([_transaction(1), _transaction(2)]),
        dashboard: _dashboard(),
      );
      final provider = BusinessManagementProvider(service: service);
      await provider.loadTransactions();

      final ok = await provider.deleteTransaction(1);

      expect(ok, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.isSubmitting, isFalse);
      expect(service.deleteCalls, [1]);
      // Refresh pulls the (fake) post-delete page back from the service.
      expect(provider.transactions.single.id, 2);
    });

    test('unauthorized/not-found delete surfaces an error and keeps state',
        () async {
      final service = _FakeService(
        transactionsPage: _page([_transaction(1)]),
        dashboard: _dashboard(),
      )..failNextDelete = DioException(
          requestOptions: RequestOptions(
            path: '/api/v1/businesses/transactions/1/',
          ),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'detail': 'Muamala haukupatikana.'},
          ),
        );
      final provider = BusinessManagementProvider(service: service);
      await provider.loadTransactions();

      final ok = await provider.deleteTransaction(1);

      expect(ok, isFalse);
      expect(provider.errorMessage, 'Muamala haukupatikana.');
      // Local list must remain exactly what it was before the failed delete.
      expect(provider.transactions.single.id, 1);
      expect(provider.isSubmitting, isFalse);
    });

    test('does not allow overlapping submissions while one is in flight',
        () async {
      final service = _FakeService(
        transactionsPage: _page([_transaction(1)]),
        dashboard: _dashboard(),
      );
      final provider = BusinessManagementProvider(service: service);
      await provider.loadTransactions();

      final future = provider.deleteTransaction(1);
      expect(provider.isSubmitting, isTrue);

      await future;
      expect(provider.isSubmitting, isFalse);
    });
  });
}

PaginatedTransactions _page(List<BusinessTransaction> items) {
  return PaginatedTransactions(
    items: items,
    count: items.length,
    next: null,
    previous: null,
  );
}

BusinessTransaction _transaction(int id, {String amount = '1000.00'}) =>
    BusinessTransaction.fromJson({
      'id': id,
      'transaction_type': 'sale',
      'amount': amount,
      'category': 'huduma',
      'description': '',
      'transaction_date': '2026-07-01',
      'created_at': '2026-07-01T08:00:00Z',
      'updated_at': '2026-07-01T08:00:00Z',
    });

BusinessDashboardSummary _dashboard() => BusinessDashboardSummary.fromJson({
      'business': {
        'id': 1,
        'name': 'Duka la Jaribio',
        'business_type': 'duka',
        'currency': 'TZS',
        'is_active': true,
        'created_at': '2026-01-01T08:00:00Z',
        'updated_at': '2026-01-01T08:00:00Z',
      },
      'summary': {
        'mauzo': '2500.00',
        'matumizi': '0.00',
        'faida_hasara': '2500.00',
        'status': 'faida',
        'status_text': 'Faida',
        'miamala': 1,
        'currency': 'TZS',
      },
      'leo': {
        'mauzo': '0.00',
        'matumizi': '0.00',
        'faida_hasara': '0.00',
        'status': 'sawa',
        'status_text': 'Sawa',
        'miamala': 0,
        'currency': 'TZS',
      },
      'mwezi': {
        'mauzo': '2500.00',
        'matumizi': '0.00',
        'faida_hasara': '2500.00',
        'status': 'faida',
        'status_text': 'Faida',
        'miamala': 1,
        'currency': 'TZS',
      },
      'recent_transactions': [],
    });

/// Minimal fake that mimics a backend where deleting transaction [id] is
/// reflected in the next fetched page — used to assert the provider
/// refreshes from the (fake) server rather than trusting local removal blindly.
class _FakeService implements BusinessManagementApi {
  _FakeService({required this.transactionsPage, required this.dashboard});

  PaginatedTransactions transactionsPage;
  BusinessDashboardSummary dashboard;
  Object? failNextDelete;
  final List<int> deleteCalls = [];

  @override
  Future<void> deleteTransaction(int id) async {
    deleteCalls.add(id);
    if (failNextDelete != null) {
      final error = failNextDelete!;
      failNextDelete = null;
      throw error;
    }
    transactionsPage = _page(
      transactionsPage.items.where((item) => item.id != id).toList(),
    );
  }

  @override
  Future<PaginatedTransactions> getTransactionsPage({
    String? transactionType,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async =>
      transactionsPage;

  @override
  Future<BusinessDashboardSummary> getDashboard() async => dashboard;

  @override
  Future<Business?> getMyBusiness() async => dashboard.business;

  @override
  Future<Business> createBusiness({
    required String name,
    required String businessType,
  }) =>
      throw UnimplementedError();

  @override
  Future<Business> updateBusiness({
    required String name,
    required String businessType,
  }) =>
      throw UnimplementedError();

  @override
  Future<BusinessTransaction> createTransaction({
    required String transactionType,
    required String amount,
    required String category,
    required DateTime transactionDate,
    String description = '',
  }) =>
      throw UnimplementedError();

  @override
  Future<BusinessTransaction> updateTransaction({
    required int id,
    String? transactionType,
    String? amount,
    String? category,
    DateTime? transactionDate,
    String? description,
  }) =>
      throw UnimplementedError();
}
