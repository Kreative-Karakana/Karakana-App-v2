import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/zana/business_management/models/business.dart';
import 'package:karakana_app/features/zana/business_management/models/business_dashboard_summary.dart';
import 'package:karakana_app/features/zana/business_management/models/business_transaction.dart';
import 'package:karakana_app/features/zana/business_management/providers/business_management_provider.dart';
import 'package:karakana_app/features/zana/business_management/services/business_management_service.dart';

void main() {
  group('BusinessManagementProvider.updateTransaction', () {
    test('successful edit updates local state and refreshes data', () async {
      final service = _FakeService(
        transactionsPage: _page([_transaction(1, amount: '1000.00')]),
        dashboard: _dashboard(),
      );
      final provider = BusinessManagementProvider(service: service);
      await provider.loadTransactions();

      final ok = await provider.updateTransaction(
        id: 1,
        amount: '2500.00',
        category: 'bidhaa',
        transactionDate: DateTime(2026, 7, 5),
        description: 'Imesahihishwa',
      );

      expect(ok, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.isSubmitting, isFalse);
      // Refresh pulls the (fake) post-edit page back from the service.
      expect(provider.transactions.single.amount, '2500.00');
      expect(service.updateCalls.single.id, 1);
      expect(service.updateCalls.single.amount, '2500.00');
    });

    test(
      'failed edit surfaces an error without corrupting loaded state',
      () async {
        final service = _FakeService(
          transactionsPage: _page([_transaction(1, amount: '1000.00')]),
          dashboard: _dashboard(),
        )..failNextUpdate = DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/businesses/transactions/1/',
            ),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 400,
              data: {
                'amount': ['Kiasi lazima kiwe zaidi ya sifuri.'],
              },
            ),
          );
        final provider = BusinessManagementProvider(service: service);
        await provider.loadTransactions();

        final ok = await provider.updateTransaction(
          id: 1,
          amount: '-5.00',
          category: 'bidhaa',
          transactionDate: DateTime(2026, 7, 5),
          description: 'Jaribio lisilofaulu',
        );

        expect(ok, isFalse);
        expect(provider.errorMessage, 'Kiasi lazima kiwe zaidi ya sifuri.');
        // Local list must remain exactly what it was before the failed edit.
        expect(provider.transactions.single.amount, '1000.00');
        expect(provider.isSubmitting, isFalse);
      },
    );

    test(
      'does not allow overlapping submissions while one is in flight',
      () async {
        final service = _FakeService(
          transactionsPage: _page([_transaction(1)]),
          dashboard: _dashboard(),
        );
        final provider = BusinessManagementProvider(service: service);
        await provider.loadTransactions();

        final future = provider.updateTransaction(
          id: 1,
          amount: '3000.00',
          category: 'bidhaa',
          transactionDate: DateTime(2026, 7, 5),
          description: '',
        );
        expect(provider.isSubmitting, isTrue);

        await future;
        expect(provider.isSubmitting, isFalse);
      },
    );
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

class _UpdateCall {
  final int id;
  final String? amount;

  const _UpdateCall(this.id, this.amount);
}

/// Minimal fake that mimics a backend where editing transaction [id] is
/// reflected in the next fetched page — used to assert the provider
/// refreshes from the (fake) server rather than trusting local edits blindly.
class _FakeService implements BusinessManagementApi {
  _FakeService({required this.transactionsPage, required this.dashboard});

  PaginatedTransactions transactionsPage;
  BusinessDashboardSummary dashboard;
  Object? failNextUpdate;
  final List<_UpdateCall> updateCalls = [];

  @override
  Future<BusinessTransaction> updateTransaction({
    required int id,
    String? transactionType,
    String? amount,
    String? category,
    DateTime? transactionDate,
    String? description,
  }) async {
    updateCalls.add(_UpdateCall(id, amount));
    if (failNextUpdate != null) {
      final error = failNextUpdate!;
      failNextUpdate = null;
      throw error;
    }
    final updated = BusinessTransaction.fromJson({
      'id': id,
      'transaction_type': transactionType ?? 'sale',
      'amount': amount ?? '1000.00',
      'category': category ?? 'huduma',
      'description': description ?? '',
      'transaction_date': '2026-07-05',
      'created_at': '2026-07-01T08:00:00Z',
      'updated_at': '2026-07-05T08:00:00Z',
    });
    transactionsPage = _page([updated]);
    return updated;
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
  Future<void> deleteTransaction(int id) => throw UnimplementedError();
}
