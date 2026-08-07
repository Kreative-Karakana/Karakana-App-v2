import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/core/theme/app_colors.dart';
import 'package:karakana_app/core/theme/app_theme.dart';
import 'package:karakana_app/features/zana/business_management/models/business_debt.dart';
import 'package:karakana_app/features/zana/business_management/screens/debt_management_screen.dart';
import 'package:karakana_app/features/zana/business_management/services/debt_management_service.dart';

void main() {
  testWidgets('shows a polished empty state and opens the create form',
      (tester) async {
    final service = _ScreenDebtService([]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Hakuna madeni bado'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-debt-button')));
    await tester.pumpAndSettle();
    expect(find.text('Ongeza Deni'), findsWidgets);
    expect(find.byKey(const Key('debt-customer-field')), findsOneWidget);
    expect(find.text('Kiasi (TZS) *'), findsOneWidget);
    expect(find.byKey(const Key('debt-status-field')), findsNothing);
  });

  testWidgets('required fields show friendly validation', (tester) async {
    final service = _ScreenDebtService([]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-debt-button')));
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const Key('save-debt-button'));
    await tester.ensureVisible(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('Weka jina la mteja.'), findsOneWidget);
    expect(find.text('Weka kiasi cha deni.'), findsOneWidget);
    expect(service.createCalls, 0);
  });

  testWidgets('formats debt amount by thousands and submits a clean value',
      (tester) async {
    final service = _ScreenDebtService([]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-debt-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('debt-customer-field')),
      'Asha Juma',
    );
    await tester.enterText(
      find.byKey(const Key('debt-amount-field')),
      '15000',
    );
    await tester.pump();

    expect(find.text('15,000'), findsOneWidget);
    final saveButton = find.byKey(const Key('save-debt-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(service.lastAmount, '15000');
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('outstanding debt can be marked paid', (tester) async {
    final service = _ScreenDebtService([_screenDebt(status: 'outstanding')]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Haijalipwa'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mark-paid-1')));
    await tester.pumpAndSettle();

    expect(service.lastStatus, 'paid');
    expect(find.text('Imelipwa'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('read-only mode delegates write attempts without calling API',
      (tester) async {
    final service = _ScreenDebtService([]);
    var lockedCalls = 0;
    await tester.pumpWidget(_app(
      service,
      readOnly: true,
      onLocked: () async => lockedCalls++,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-debt-button')));
    await tester.pump();

    expect(lockedCalls, 1);
    expect(find.byKey(const Key('debt-customer-field')), findsNothing);
    expect(service.createCalls, 0);
  });

  testWidgets('keyboard inset keeps the debt save action reachable at 2x text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      _app(
        _ScreenDebtService([]),
        textScale: 2,
        viewInsets: const EdgeInsets.only(bottom: 260),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-debt-button')));
    await tester.pumpAndSettle();

    final save = find.byKey(const Key('save-debt-button'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();

    expect(save, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('has no overflow across required responsive configurations',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final configurations = [
      (const Size(320, 568), Brightness.light, 2.0),
      (const Size(375, 812), Brightness.dark, 2.0),
      (const Size(768, 1024), Brightness.light, 2.0),
      (const Size(1024, 768), Brightness.dark, 2.0),
      (const Size(568, 320), Brightness.light, 2.0),
      (const Size(812, 375), Brightness.dark, 2.0),
    ];

    for (final configuration in configurations) {
      tester.view.physicalSize = configuration.$1;
      await tester.pumpWidget(_app(
        _ScreenDebtService([_screenDebt(status: 'outstanding')]),
        brightness: configuration.$2,
        textScale: configuration.$3,
      ));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Asha Juma'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Asha Juma'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

Widget _app(
  DebtManagementApi service, {
  bool readOnly = false,
  Future<void> Function()? onLocked,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  AppColors.setBrightness(brightness);
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        viewInsets: viewInsets,
      ),
      child: child!,
    ),
    home: DebtManagementScreen(
      currency: 'TZS',
      isReadOnly: readOnly,
      onLockedAction: onLocked ?? () async {},
      service: service,
    ),
  );
}

class _ScreenDebtService implements DebtManagementApi {
  _ScreenDebtService(List<BusinessDebt> debts) : debts = [...debts];

  List<BusinessDebt> debts;
  int createCalls = 0;
  String? lastStatus;
  String? lastAmount;

  @override
  Future<PaginatedDebts> getDebtsPage({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final items = status == null
        ? debts
        : debts.where((debt) => debt.status == status).toList();
    return PaginatedDebts(
      items: items,
      count: items.length,
      next: null,
      previous: null,
    );
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
    createCalls++;
    lastAmount = amount;
    final debt = _screenDebt(status: status);
    debts = [...debts, debt];
    return debt;
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
    lastStatus = status;
    final current = debts.singleWhere((debt) => debt.id == id);
    final updated = BusinessDebt.fromJson({
      'id': id,
      'customer_name': customerName ?? current.customerName,
      'amount': amount ?? current.amount,
      'item_service': itemService ?? current.itemService,
      'note': note ?? current.note,
      'date_given': (dateGiven ?? current.dateGiven)!.toIso8601String(),
      'due_date':
          clearDueDate ? null : (dueDate ?? current.dueDate)?.toIso8601String(),
      'status': status ?? current.status,
    });
    debts = [updated];
    return updated;
  }

  @override
  Future<void> deleteDebt(int id) async {
    debts = debts.where((debt) => debt.id != id).toList();
  }
}

BusinessDebt _screenDebt({required String status}) => BusinessDebt.fromJson({
      'id': 1,
      'customer_name': 'Asha Juma',
      'amount': '15000.00',
      'item_service': 'Bidhaa za dukani',
      'note': '',
      'date_given': '2026-08-01',
      'due_date': null,
      'status': status,
    });
