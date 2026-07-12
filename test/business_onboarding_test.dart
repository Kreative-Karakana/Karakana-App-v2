import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:karakana_app/features/zana/business_management/models/business.dart';
import 'package:karakana_app/features/zana/business_management/models/business_dashboard_summary.dart';
import 'package:karakana_app/features/zana/business_management/models/business_transaction.dart';
import 'package:karakana_app/features/zana/business_management/providers/business_management_provider.dart';
import 'package:karakana_app/features/zana/business_management/services/business_management_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BusinessManagementProvider.showFirstTransactionGuide', () {
    test('is false while no business has been created yet', () async {
      final provider = BusinessManagementProvider(
        service: _FakeService(hasBusiness: false),
      );
      await provider.loadInitial();

      expect(provider.showFirstTransactionGuide, isFalse);
    });

    test('is true for a new business that has never recorded a transaction',
        () async {
      final provider = BusinessManagementProvider(
        service: _FakeService(hasBusiness: true, transactionCount: 0),
      );
      await provider.loadInitial();

      expect(provider.showFirstTransactionGuide, isTrue);
    });

    test('is false once the business has at least one transaction', () async {
      final provider = BusinessManagementProvider(
        service: _FakeService(hasBusiness: true, transactionCount: 1),
      );
      await provider.loadInitial();

      expect(provider.showFirstTransactionGuide, isFalse);
    });

    test('dismissFirstTransactionGuide hides it and persists the choice',
        () async {
      final provider = BusinessManagementProvider(
        service: _FakeService(hasBusiness: true, transactionCount: 0),
      );
      await provider.loadInitial();
      expect(provider.showFirstTransactionGuide, isTrue);

      await provider.dismissFirstTransactionGuide();
      expect(provider.showFirstTransactionGuide, isFalse);

      // A fresh provider (e.g. after navigating back to the screen) should
      // read the persisted dismissal instead of showing the guide again.
      final reopened = BusinessManagementProvider(
        service: _FakeService(hasBusiness: true, transactionCount: 0),
      );
      await reopened.loadInitial();
      await Future<void>.delayed(Duration.zero);

      expect(reopened.showFirstTransactionGuide, isFalse);
    });
  });
}

/// Fake that mimics a backend for a business with a configurable
/// all-time transaction count, used to drive [showFirstTransactionGuide].
class _FakeService implements BusinessManagementApi {
  final bool hasBusiness;
  final int transactionCount;

  _FakeService({required this.hasBusiness, this.transactionCount = 0});

  @override
  Future<Business?> getMyBusiness() async =>
      hasBusiness ? Business.fromJson(_businessJson()) : null;

  @override
  Future<BusinessDashboardSummary> getDashboard() async =>
      BusinessDashboardSummary.fromJson({
        'business': _businessJson(),
        'summary': {
          'mauzo': '0.00',
          'matumizi': '0.00',
          'faida_hasara': '0.00',
          'status': 'sawa',
          'status_text': 'Sawa',
          'miamala': transactionCount,
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
      const PaginatedTransactions(
          items: [], count: 0, next: null, previous: null);

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

Map<String, dynamic> _businessJson() => {
      'id': 1,
      'name': 'Duka la Jaribio',
      'business_type': 'duka',
      'currency': 'TZS',
      'is_active': true,
      'created_at': '2026-01-01T08:00:00Z',
      'updated_at': '2026-01-01T08:00:00Z',
    };
