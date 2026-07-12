import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/subscriptions/models/entitlement_status.dart';
import 'package:karakana_app/features/zana/business_management/models/business.dart';
import 'package:karakana_app/features/zana/business_management/models/business_dashboard_summary.dart';
import 'package:karakana_app/features/zana/business_management/models/business_transaction.dart';
import 'package:karakana_app/features/zana/business_management/providers/business_management_provider.dart';
import 'package:karakana_app/features/zana/business_management/services/business_management_service.dart';

import 'support/fake_subscription_api.dart';

/// Issue #31: once a trial/subscription expires, the businesses screens
/// must keep showing existing data while blocking new writes — these
/// tests exercise the Flutter-side half of that (read/write state, the
/// friendly upgrade message, and re-syncing after a 403), independent of
/// the backend tests that prove the actual enforcement.
void main() {
  group('BusinessManagementProvider read-only entitlement state', () {
    test('active entitlement leaves isReadOnly false', () async {
      final provider = BusinessManagementProvider(
        service: _FakeService(business: _business(), dashboard: _dashboard()),
        subscriptionService: FakeSubscriptionApi(),
      );

      await provider.loadInitial();

      expect(provider.isReadOnly, isFalse);
    });

    test('expired entitlement flips isReadOnly to true', () async {
      final provider = BusinessManagementProvider(
        service: _FakeService(business: _business(), dashboard: _dashboard()),
        subscriptionService: FakeSubscriptionApi(
          status: const EntitlementStatus(
            hasActiveSubscription: false,
            status: 'expired',
            expiryDate: null,
          ),
        ),
      );

      await provider.loadInitial();

      expect(provider.isReadOnly, isTrue);
    });

    test('existing business data still loads while read-only', () async {
      final provider = BusinessManagementProvider(
        service: _FakeService(
          business: _business(name: 'Duka Langu'),
          dashboard: _dashboard(name: 'Duka Langu'),
        ),
        subscriptionService: FakeSubscriptionApi(
          status: const EntitlementStatus(
            hasActiveSubscription: false,
            status: 'expired',
            expiryDate: null,
          ),
        ),
      );

      await provider.loadInitial();

      expect(provider.isReadOnly, isTrue);
      expect(provider.business?.name, 'Duka Langu');
      expect(provider.hasNoBusiness, isFalse);
    });

    test(
        'a 403 on a write call surfaces the upgrade message and syncs '
        'isReadOnly, without needing the entitlement to have been loaded '
        'as expired beforehand', () async {
      final service =
          _FakeService(business: _business(), dashboard: _dashboard())
            ..failNextUpdate = DioException(
              requestOptions: RequestOptions(path: '/api/v1/businesses/me/'),
              response: Response(
                requestOptions: RequestOptions(path: ''),
                statusCode: 403,
                data: {'detail': 'Huduma hii inahitaji usajili amilifu.'},
              ),
            );
      final subscriptionApi = FakeSubscriptionApi();
      final provider = BusinessManagementProvider(
        service: service,
        subscriptionService: subscriptionApi,
      );
      await provider.loadInitial();
      expect(provider.isReadOnly, isFalse);

      // Access lapses server-side between the initial load and this call —
      // the provider must react to the 403 itself, not to a pre-fetched flag.
      subscriptionApi.status = const EntitlementStatus(
        hasActiveSubscription: false,
        status: 'expired',
        expiryDate: null,
      );

      final ok = await provider.updateBusiness(
          name: 'Jina Jipya', businessType: 'duka');

      expect(ok, isFalse);
      expect(provider.errorMessage, kSubscriptionRequiredMessage);
      expect(provider.isReadOnly, isTrue);
    });
  });
}

Business _business({String name = 'Duka la Jaribio'}) => Business.fromJson({
      'id': 1,
      'name': name,
      'business_type': 'duka',
      'currency': 'TZS',
      'is_active': true,
      'created_at': '2026-01-01T08:00:00Z',
      'updated_at': '2026-01-01T08:00:00Z',
    });

BusinessDashboardSummary _dashboard({String name = 'Duka la Jaribio'}) =>
    BusinessDashboardSummary.fromJson({
      'business': {
        'id': 1,
        'name': name,
        'business_type': 'duka',
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

class _FakeService implements BusinessManagementApi {
  _FakeService({required this.business, required this.dashboard});

  Business business;
  BusinessDashboardSummary dashboard;
  Object? failNextUpdate;

  @override
  Future<Business> updateBusiness({
    required String name,
    required String businessType,
  }) async {
    if (failNextUpdate != null) {
      final error = failNextUpdate!;
      failNextUpdate = null;
      throw error;
    }
    business = Business.fromJson({
      'id': 1,
      'name': name,
      'business_type': businessType,
      'currency': 'TZS',
      'is_active': true,
      'created_at': '2026-01-01T08:00:00Z',
      'updated_at': '2026-01-01T08:00:00Z',
    });
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
