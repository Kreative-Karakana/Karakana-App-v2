import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/core/theme/app_colors.dart';
import 'package:karakana_app/core/theme/app_theme.dart';
import 'package:karakana_app/features/zana/business_management/models/business.dart';
import 'package:karakana_app/features/zana/business_management/models/business_dashboard_summary.dart';
import 'package:karakana_app/features/zana/business_management/models/business_transaction.dart';
import 'package:karakana_app/features/zana/business_management/providers/business_management_provider.dart';
import 'package:karakana_app/features/zana/business_management/screens/business_management_screen.dart';
import 'package:karakana_app/features/zana/business_management/services/business_management_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_subscription_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('initial network failure stays visible and offers retry',
      (tester) async {
    final service = _BusinessUxService(failLoads: true);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Imeshindikana kupakia biashara'), findsOneWidget);
    expect(find.text('Jaribu tena'), findsOneWidget);
    expect(find.text('Anza Kutumia Usimamizi wa Biashara'), findsNothing);

    await tester.tap(find.text('Jaribu tena'));
    await tester.pumpAndSettle();
    expect(service.businessLoadCalls, 2);
  });

  testWidgets('dashboard is responsive, theme-safe, and uses business currency',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final configurations = [
      (const Size(320, 568), Brightness.light, 1.0),
      (const Size(375, 812), Brightness.dark, 2.0),
      (const Size(768, 1024), Brightness.light, 1.0),
      (const Size(1024, 768), Brightness.dark, 1.0),
    ];

    for (final configuration in configurations) {
      tester.view.physicalSize = configuration.$1;
      await tester.pumpWidget(
        _app(
          _BusinessUxService(),
          brightness: configuration.$2,
          textScale: configuration.$3,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Duka la Asha'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Miamala ya karibuni'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('USD 15,000'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });
}

Widget _app(
  BusinessManagementApi service, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) {
  AppColors.setBrightness(brightness);
  final provider = BusinessManagementProvider(
    service: service,
    subscriptionService: FakeSubscriptionApi(),
  );
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: BusinessManagementScreen(key: UniqueKey(), provider: provider),
  );
}

class _BusinessUxService implements BusinessManagementApi {
  _BusinessUxService({this.failLoads = false});

  final bool failLoads;
  int businessLoadCalls = 0;

  Business get _business => Business.fromJson({
        'id': 1,
        'name': 'Duka la Asha',
        'business_type': 'retail',
        'currency': 'USD',
        'is_active': true,
      });

  BusinessTransaction get _transaction => BusinessTransaction.fromJson({
        'id': 1,
        'transaction_type': 'sale',
        'amount': '15000.00',
        'category': 'bidhaa',
        'description': 'Mauzo ya leo',
        'transaction_date': '2026-08-07',
      });

  @override
  Future<Business?> getMyBusiness() async {
    businessLoadCalls++;
    if (failLoads) {
      throw DioException(
        requestOptions: RequestOptions(path: '/businesses/me/'),
        type: DioExceptionType.connectionError,
      );
    }
    return _business;
  }

  @override
  Future<BusinessDashboardSummary> getDashboard() async =>
      BusinessDashboardSummary.fromJson({
        'business': {
          'id': 1,
          'name': 'Duka la Asha',
          'business_type': 'retail',
          'currency': 'USD',
          'is_active': true,
        },
        'summary': {
          'mauzo': '15000.00',
          'matumizi': '0.00',
          'faida_hasara': '15000.00',
          'status': 'faida',
          'status_text': 'Faida',
          'miamala': 1,
          'currency': 'USD',
        },
        'leo': {},
        'mwezi': {},
        'recent_transactions': [
          {
            'id': 1,
            'transaction_type': 'sale',
            'amount': '15000.00',
            'category': 'bidhaa',
            'description': 'Mauzo ya leo',
            'transaction_date': '2026-08-07',
          },
        ],
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
        items: [_transaction],
        count: 1,
        next: null,
        previous: null,
      );

  @override
  Future<Business> createBusiness({
    required String name,
    required String businessType,
  }) async =>
      _business;

  @override
  Future<Business> updateBusiness({
    required String name,
    required String businessType,
  }) async =>
      _business;

  @override
  Future<BusinessTransaction> createTransaction({
    required String transactionType,
    required String amount,
    required String category,
    required DateTime transactionDate,
    String description = '',
  }) async =>
      _transaction;

  @override
  Future<BusinessTransaction> updateTransaction({
    required int id,
    String? transactionType,
    String? amount,
    String? category,
    DateTime? transactionDate,
    String? description,
  }) async =>
      _transaction;

  @override
  Future<void> deleteTransaction(int id) async {}
}
