import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/zana/business_management/models/business.dart';
import 'package:karakana_app/features/zana/business_management/models/business_dashboard_summary.dart';
import 'package:karakana_app/features/zana/business_management/models/business_transaction.dart';
import 'package:karakana_app/features/zana/business_management/providers/business_management_provider.dart';
import 'package:karakana_app/features/zana/business_management/services/business_management_service.dart';

void main() {
  group('BusinessManagementProvider.updateBusiness', () {
    test('successful edit updates local state and refreshes dashboard',
        () async {
      final service = _FakeService(
        business: _business(name: 'Duka la Zamani', businessType: 'duka'),
        dashboard: _dashboard(name: 'Duka la Zamani', businessType: 'duka'),
      );
      final provider = BusinessManagementProvider(service: service);
      await provider.loadInitial();

      final ok = await provider.updateBusiness(
        name: 'Duka Jipya',
        businessType: 'fundi',
      );

      expect(ok, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.isSubmitting, isFalse);
      expect(provider.business?.name, 'Duka Jipya');
      expect(provider.business?.businessType, 'fundi');
      expect(service.updateCalls.single.name, 'Duka Jipya');
      expect(service.updateCalls.single.businessType, 'fundi');
    });

    test(
      'failed edit surfaces an error without corrupting loaded state',
      () async {
        final service = _FakeService(
          business: _business(name: 'Duka la Zamani', businessType: 'duka'),
          dashboard: _dashboard(name: 'Duka la Zamani', businessType: 'duka'),
        )..failNextUpdate = DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/businesses/me/',
            ),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 400,
              data: {
                'name': ['Weka jina la biashara.'],
              },
            ),
          );
        final provider = BusinessManagementProvider(service: service);
        await provider.loadInitial();

        final ok = await provider.updateBusiness(
          name: '',
          businessType: 'fundi',
        );

        expect(ok, isFalse);
        expect(provider.errorMessage, 'Weka jina la biashara.');
        expect(provider.business?.name, 'Duka la Zamani');
        expect(provider.business?.businessType, 'duka');
        expect(provider.isSubmitting, isFalse);
      },
    );

    test(
      'does not allow overlapping submissions while one is in flight',
      () async {
        final service = _FakeService(
          business: _business(name: 'Duka la Zamani', businessType: 'duka'),
          dashboard: _dashboard(name: 'Duka la Zamani', businessType: 'duka'),
        );
        final provider = BusinessManagementProvider(service: service);
        await provider.loadInitial();

        final future = provider.updateBusiness(
          name: 'Duka Jipya',
          businessType: 'fundi',
        );
        expect(provider.isSubmitting, isTrue);

        await future;
        expect(provider.isSubmitting, isFalse);
      },
    );
  });
}

Business _business({required String name, required String businessType}) =>
    Business.fromJson({
      'id': 1,
      'name': name,
      'business_type': businessType,
      'currency': 'TZS',
      'is_active': true,
      'created_at': '2026-01-01T08:00:00Z',
      'updated_at': '2026-01-01T08:00:00Z',
    });

BusinessDashboardSummary _dashboard({
  required String name,
  required String businessType,
}) =>
    BusinessDashboardSummary.fromJson({
      'business': {
        'id': 1,
        'name': name,
        'business_type': businessType,
        'currency': 'TZS',
        'is_active': true,
        'created_at': '2026-01-01T08:00:00Z',
        'updated_at': '2026-01-01T08:00:00Z',
      },
      'summary': {
        'mauzo': '0.00',
        'matumizi': '0.00',
        'faida_hasara': '0.00',
        'status': 'sawa',
        'status_text': 'Sawa',
        'miamala': 0,
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

class _UpdateCall {
  final String name;
  final String businessType;

  const _UpdateCall(this.name, this.businessType);
}

/// Minimal fake that mimics a backend where editing the business is
/// reflected in the next fetched dashboard — used to assert the provider
/// refreshes from the (fake) server rather than trusting local edits blindly.
class _FakeService implements BusinessManagementApi {
  _FakeService({required this.business, required this.dashboard});

  Business business;
  BusinessDashboardSummary dashboard;
  Object? failNextUpdate;
  final List<_UpdateCall> updateCalls = [];

  @override
  Future<Business> updateBusiness({
    required String name,
    required String businessType,
  }) async {
    updateCalls.add(_UpdateCall(name, businessType));
    if (failNextUpdate != null) {
      final error = failNextUpdate!;
      failNextUpdate = null;
      throw error;
    }
    business = _business(name: name, businessType: businessType);
    dashboard = _dashboard(name: name, businessType: businessType);
    return business;
  }

  @override
  Future<Business?> getMyBusiness() async => business;

  @override
  Future<BusinessDashboardSummary> getDashboard() async => dashboard;

  @override
  Future<Business> createBusiness({
    required String name,
    required String businessType,
  }) =>
      throw UnimplementedError();

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
      const PaginatedTransactions(
        items: [],
        count: 0,
        next: null,
        previous: null,
      );

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
