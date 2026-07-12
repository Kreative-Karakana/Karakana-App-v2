import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/zana/business_management/models/business.dart';
import 'package:karakana_app/features/zana/business_management/models/business_dashboard_summary.dart';
import 'package:karakana_app/features/zana/business_management/models/business_transaction.dart';
import 'package:karakana_app/features/zana/business_management/providers/business_management_provider.dart';
import 'package:karakana_app/features/zana/business_management/services/business_management_service.dart';

void main() {
  group('BusinessManagementProvider.createSale', () {
    test('success adds the transaction and refreshes dashboard state',
        () async {
      final service = _FakeService();
      final provider = BusinessManagementProvider(service: service);

      final ok = await provider.createSale(
        amount: '5000.00',
        category: 'huduma',
        transactionDate: DateTime(2026, 7, 1),
        description: 'Mauzo ya jumla',
      );

      expect(ok, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.isSubmitting, isFalse);
      expect(service.createCalls.single.transactionType, 'sale');
      expect(service.createCalls.single.amount, '5000.00');
      expect(service.createCalls.single.category, 'huduma');
      expect(service.createCalls.single.description, 'Mauzo ya jumla');
      // createSale refreshes both the dashboard and the transaction list
      // from the (fake) server, rather than optimistically splicing the
      // new transaction into local state.
      expect(provider.dashboardSummary?.mauzoValue, 5000.0);
      expect(provider.transactions.map((t) => t.id), [1]);
    });

    test('failure surfaces a parsed error and does not touch loaded state',
        () async {
      final service = _FakeService()
        ..failNextCreate = DioException(
          requestOptions: RequestOptions(
            path: '/api/v1/businesses/transactions/',
          ),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {
              'amount': ['Weka kiasi sahihi.'],
            },
          ),
        );
      final provider = BusinessManagementProvider(service: service);

      final ok = await provider.createSale(
        amount: 'abc',
        category: 'huduma',
        transactionDate: DateTime(2026, 7, 1),
      );

      expect(ok, isFalse);
      expect(provider.errorMessage, 'Weka kiasi sahihi.');
      expect(provider.isSubmitting, isFalse);
      expect(provider.transactions, isEmpty);
    });

    test('falls back to a Swahili message when the server gives no detail',
        () async {
      final service = _FakeService()
        ..failNextCreate = DioException(
          requestOptions: RequestOptions(
            path: '/api/v1/businesses/transactions/',
          ),
          type: DioExceptionType.connectionError,
        );
      final provider = BusinessManagementProvider(service: service);

      final ok = await provider.createSale(
        amount: '1000',
        category: 'huduma',
        transactionDate: DateTime(2026, 7, 1),
      );

      expect(ok, isFalse);
      expect(
        provider.errorMessage,
        'Hakuna muunganisho wa intaneti. Tafadhali angalia mtandao wako.',
      );
    });

    test('does not allow overlapping submissions while one is in flight',
        () async {
      final service = _FakeService();
      final provider = BusinessManagementProvider(service: service);

      final future = provider.createSale(
        amount: '5000.00',
        category: 'huduma',
        transactionDate: DateTime(2026, 7, 1),
      );
      expect(provider.isSubmitting, isTrue);

      await future;
      expect(provider.isSubmitting, isFalse);
    });
  });

  group('BusinessManagementProvider.createExpense', () {
    test('records an expense-typed transaction', () async {
      final service = _FakeService();
      final provider = BusinessManagementProvider(service: service);

      final ok = await provider.createExpense(
        amount: '2000.00',
        category: 'usafiri',
        transactionDate: DateTime(2026, 7, 2),
      );

      expect(ok, isTrue);
      expect(service.createCalls.single.transactionType, 'expense');
      expect(service.createCalls.single.category, 'usafiri');
    });
  });
}

class _CreateCall {
  final String transactionType;
  final String amount;
  final String category;
  final DateTime transactionDate;
  final String description;

  const _CreateCall({
    required this.transactionType,
    required this.amount,
    required this.category,
    required this.transactionDate,
    required this.description,
  });
}

/// Fake that mimics a backend where a successful create is reflected in the
/// next fetched dashboard and transaction page — asserting the provider
/// refreshes from the (fake) server after creating a transaction.
class _FakeService implements BusinessManagementApi {
  Object? failNextCreate;
  final List<_CreateCall> createCalls = [];

  @override
  Future<BusinessTransaction> createTransaction({
    required String transactionType,
    required String amount,
    required String category,
    required DateTime transactionDate,
    String description = '',
  }) async {
    createCalls.add(_CreateCall(
      transactionType: transactionType,
      amount: amount,
      category: category,
      transactionDate: transactionDate,
      description: description,
    ));
    if (failNextCreate != null) {
      final error = failNextCreate!;
      failNextCreate = null;
      throw error;
    }
    return BusinessTransaction.fromJson(_transactionJson(
      1,
      transactionType: transactionType,
      amount: amount,
      category: category,
    ));
  }

  @override
  Future<BusinessDashboardSummary> getDashboard() async =>
      BusinessDashboardSummary.fromJson({
        'business': _businessJson(),
        'summary': {
          'mauzo': createCalls.isEmpty ? '0.00' : '5000.00',
          'matumizi': '0.00',
          'faida_hasara': '5000.00',
          'status': 'faida',
          'status_text': 'Faida',
          'miamala': createCalls.length,
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
      PaginatedTransactions(
        items: [
          for (final call in createCalls)
            BusinessTransaction.fromJson(_transactionJson(
              1,
              transactionType: call.transactionType,
              amount: call.amount,
              category: call.category,
            )),
        ],
        count: createCalls.length,
        next: null,
        previous: null,
      );

  @override
  Future<Business?> getMyBusiness() async => Business.fromJson(_businessJson());

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

Map<String, dynamic> _transactionJson(
  int id, {
  required String transactionType,
  required String amount,
  required String category,
}) =>
    {
      'id': id,
      'transaction_type': transactionType,
      'amount': amount,
      'category': category,
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
