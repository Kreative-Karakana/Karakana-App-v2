import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/zana/business_management/models/business.dart';
import 'package:karakana_app/features/zana/business_management/models/business_dashboard_summary.dart';
import 'package:karakana_app/features/zana/business_management/models/business_transaction.dart';
import 'package:karakana_app/features/zana/business_management/providers/business_management_provider.dart';
import 'package:karakana_app/features/zana/business_management/services/business_management_service.dart';

void main() {
  group('PaginatedTransactions', () {
    test('parses DRF paginated response metadata', () {
      final page = PaginatedTransactions.fromJson({
        'count': 15,
        'next': 'https://example.test/api/v1/businesses/transactions/?page=2',
        'previous': null,
        'results': [_transactionJson(1), _transactionJson(2)],
      });

      expect(page.items.map((t) => t.id), [1, 2]);
      expect(page.count, 15);
      expect(page.hasNext, isTrue);
      expect(page.previous, isNull);
    });
  });

  group('BusinessDashboardSummary', () {
    test('parses distinct all-time, leo, and mwezi aggregates', () {
      final summary = BusinessDashboardSummary.fromJson({
        'business': _businessJson(),
        'summary': {
          'mauzo': '14000.00',
          'matumizi': '1500.00',
          'faida_hasara': '12500.00',
          'status': 'faida',
          'status_text': 'Faida',
          'miamala': 3,
          'currency': 'TZS',
        },
        'leo': {
          'mauzo': '10000.00',
          'matumizi': '0.00',
          'faida_hasara': '10000.00',
          'status': 'faida',
          'status_text': 'Faida',
          'miamala': 1,
          'currency': 'TZS',
        },
        'mwezi': {
          'mauzo': '14000.00',
          'matumizi': '0.00',
          'faida_hasara': '14000.00',
          'status': 'faida',
          'status_text': 'Faida',
          'miamala': 2,
          'currency': 'TZS',
        },
        'recent_transactions': [],
      });

      // All-time totals (backward-compatible accessors) stay all-time.
      expect(summary.mauzoValue, 14000.00);
      // Today and this-month are distinct, backend-scoped aggregates —
      // not derived from whatever page of transactions Flutter happens
      // to have loaded.
      expect(summary.today.mauzoValue, 10000.00);
      expect(summary.today.miamala, 1);
      expect(summary.month.mauzoValue, 14000.00);
      expect(summary.month.miamala, 2);
    });

    test('missing leo/mwezi falls back to zero instead of crashing', () {
      final summary = BusinessDashboardSummary.fromJson({
        'business': null,
        'summary': {
          'mauzo': '0.00',
          'matumizi': '0.00',
          'faida_hasara': '0.00',
          'status': 'sawa',
          'status_text': 'Sawa',
          'miamala': 0,
          'currency': 'TZS',
        },
        'recent_transactions': [],
      });

      expect(summary.today.mauzoValue, 0.0);
      expect(summary.month.mauzoValue, 0.0);
    });
  });

  group('BusinessManagementProvider transaction pagination', () {
    test('loads the initial page and preserves pagination metadata',
        () async {
      final service = _FakeBusinessManagementService({
        const _PageRequest(page: 1):
            _page([_transaction(1), _transaction(2)], hasNext: true),
      });
      final provider = BusinessManagementProvider(service: service);

      await provider.loadTransactions();

      expect(provider.transactions.map((t) => t.id), [1, 2]);
      expect(provider.transactionCount, 3);
      expect(provider.hasMoreTransactions, isTrue);
      expect(provider.isLoadingTransactions, isFalse);
    });

    test('loads the next page and prevents duplicate transactions',
        () async {
      final service = _FakeBusinessManagementService({
        const _PageRequest(page: 1):
            _page([_transaction(1), _transaction(2)], hasNext: true),
        const _PageRequest(page: 2): _page([_transaction(2), _transaction(3)]),
      });
      final provider = BusinessManagementProvider(service: service);

      await provider.loadTransactions();
      await provider.loadMoreTransactions();

      expect(provider.transactions.map((t) => t.id), [1, 2, 3]);
      expect(provider.hasMoreTransactions, isFalse);
    });

    test('refresh resets pagination to the first page', () async {
      final service = _FakeBusinessManagementService({
        const _PageRequest(page: 1): _page([_transaction(1)], hasNext: true),
        const _PageRequest(page: 2): _page([_transaction(2)]),
      });
      final provider = BusinessManagementProvider(service: service);

      await provider.loadTransactions();
      await provider.loadMoreTransactions();
      await provider.loadTransactions();

      expect(provider.transactions.map((t) => t.id), [1]);
      expect(
        service.requests.map((r) => r.page),
        [1, 2, 1],
      );
    });

    test('filter change resets pagination and uses the backend filter',
        () async {
      final service = _FakeBusinessManagementService({
        const _PageRequest(page: 1): _page([_transaction(1)], hasNext: true),
        const _PageRequest(page: 1, transactionType: 'sale'):
            _page([_transaction(10)], hasNext: true),
        const _PageRequest(page: 2, transactionType: 'sale'):
            _page([_transaction(11)]),
      });
      final provider = BusinessManagementProvider(service: service);

      await provider.loadTransactions();
      await provider.loadTransactions(transactionType: 'sale');
      await provider.loadMoreTransactions();

      expect(provider.transactions.map((t) => t.id), [10, 11]);
      expect(service.requests.last.transactionType, 'sale');
      expect(service.requests.last.page, 2);
    });

    test('load-more failure preserves loaded items and can retry', () async {
      final service = _FakeBusinessManagementService({
        const _PageRequest(page: 1): _page([_transaction(1)], hasNext: true),
        const _PageRequest(page: 2): _page([_transaction(2)]),
      })
        ..failOnceFor(const _PageRequest(page: 2));
      final provider = BusinessManagementProvider(service: service);

      await provider.loadTransactions();
      await provider.loadMoreTransactions();

      expect(provider.transactions.map((t) => t.id), [1]);
      expect(provider.loadMoreTransactionsError, isNotNull);
      expect(provider.hasMoreTransactions, isTrue);

      await provider.loadMoreTransactions();

      expect(provider.transactions.map((t) => t.id), [1, 2]);
      expect(provider.loadMoreTransactionsError, isNull);
    });

    test('loadMoreTransactions is a no-op once there is no next page',
        () async {
      final service = _FakeBusinessManagementService({
        const _PageRequest(page: 1): _page([_transaction(1)]),
      });
      final provider = BusinessManagementProvider(service: service);

      await provider.loadTransactions();
      await provider.loadMoreTransactions();

      expect(service.requests.length, 1);
      expect(provider.transactions.map((t) => t.id), [1]);
    });
  });
}

PaginatedTransactions _page(List<BusinessTransaction> items,
    {bool hasNext = false}) {
  return PaginatedTransactions(
    items: items,
    count: hasNext ? items.length + 1 : items.length,
    next: hasNext
        ? 'https://example.test/api/v1/businesses/transactions/?page=2'
        : null,
    previous: null,
  );
}

BusinessTransaction _transaction(int id) =>
    BusinessTransaction.fromJson(_transactionJson(id));

Map<String, dynamic> _transactionJson(int id) => {
      'id': id,
      'transaction_type': 'sale',
      'amount': '1000.00',
      'category': 'huduma',
      'description': '',
      'transaction_date': '2026-07-01',
      'created_at': '2026-07-01T08:00:00Z',
      'updated_at': '2026-07-01T08:00:00Z',
    };

Map<String, dynamic> _businessJson() => {
      'id': 1,
      'name': 'Duka la Jaribio',
      'business_type': 'duka',
      'currency': 'TZS',
      'is_active': true,
      'created_at': '2026-01-01T08:00:00Z',
      'updated_at': '2026-01-01T08:00:00Z',
    };

class _FakeBusinessManagementService implements BusinessManagementApi {
  _FakeBusinessManagementService(this.pages);

  final Map<_PageRequest, PaginatedTransactions> pages;
  final List<_PageRequest> requests = [];
  final Set<_PageRequest> _failOnce = {};

  void failOnceFor(_PageRequest request) => _failOnce.add(request);

  @override
  Future<PaginatedTransactions> getTransactionsPage({
    String? transactionType,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 20,
  }) async {
    final request = _PageRequest(
      page: page,
      transactionType:
          transactionType == null || transactionType.isEmpty
              ? null
              : transactionType,
    );
    requests.add(request);
    if (_failOnce.remove(request)) {
      throw Exception('Network failed');
    }
    final response = pages[request];
    if (response == null) {
      throw StateError('Unexpected request: $request');
    }
    return response;
  }

  @override
  Future<Business?> getMyBusiness() async =>
      Business.fromJson(_businessJson());

  @override
  Future<BusinessDashboardSummary> getDashboard() =>
      throw UnimplementedError();

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

  @override
  Future<void> deleteTransaction(int id) => throw UnimplementedError();
}

class _PageRequest {
  final int page;
  final String? transactionType;

  const _PageRequest({required this.page, this.transactionType});

  @override
  bool operator ==(Object other) {
    return other is _PageRequest &&
        other.page == page &&
        other.transactionType == transactionType;
  }

  @override
  int get hashCode => Object.hash(page, transactionType);

  @override
  String toString() =>
      '_PageRequest(page: $page, transactionType: $transactionType)';
}
