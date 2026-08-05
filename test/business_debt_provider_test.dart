import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/zana/business_management/models/business_debt.dart';
import 'package:karakana_app/features/zana/business_management/providers/business_management_provider.dart';
import 'package:karakana_app/features/zana/business_management/providers/debt_management_provider.dart';
import 'package:karakana_app/features/zana/business_management/services/debt_management_service.dart';

void main() {
  group('DebtManagementProvider', () {
    test('loads and filters outstanding and paid debts', () async {
      final service = _FakeDebtService([
        _debt(1),
        _debt(2, status: 'paid'),
      ]);
      final provider = DebtManagementProvider(service: service);

      await provider.loadDebts();
      expect(provider.debts.map((debt) => debt.id), [1, 2]);
      expect(provider.count, 2);

      await provider.setStatusFilter('outstanding');
      expect(provider.selectedStatus, 'outstanding');
      expect(provider.debts.single.id, 1);

      await provider.setStatusFilter('paid');
      expect(provider.debts.single.id, 2);
    });

    test('creates and edits a debt then refreshes server state', () async {
      final service = _FakeDebtService([]);
      final provider = DebtManagementProvider(service: service);
      await provider.loadDebts();

      final created = await provider.createDebt(
        customerName: 'Asha',
        amount: '12000',
        itemService: 'Bidhaa',
        note: 'Atalipa Ijumaa',
        dateGiven: DateTime(2026, 8, 1),
      );
      expect(created, isTrue);
      expect(provider.debts.single.customerName, 'Asha');

      final debt = provider.debts.single;
      final updated = await provider.updateDebt(
        id: debt.id,
        customerName: 'Asha Ali',
        amount: '15000',
        itemService: 'Huduma',
        note: '',
        dateGiven: DateTime(2026, 8, 2),
        dueDate: DateTime(2026, 8, 9),
        clearDueDate: false,
        status: 'outstanding',
      );

      expect(updated, isTrue);
      expect(provider.debts.single.customerName, 'Asha Ali');
      expect(provider.debts.single.amount, '15000.00');
    });

    test('mark paid and delete update the active list', () async {
      final service = _FakeDebtService([_debt(1), _debt(2)]);
      final provider = DebtManagementProvider(service: service);
      await provider.loadDebts(status: 'outstanding');

      expect(await provider.markPaid(1), isTrue);
      expect(provider.debts.map((debt) => debt.id), [2]);

      expect(await provider.deleteDebt(2), isTrue);
      expect(provider.debts, isEmpty);
      expect(provider.count, 0);
    });

    test('paginates without duplicate debts', () async {
      final service = _FakeDebtService([
        for (var id = 1; id <= 25; id++) _debt(id),
      ]);
      final provider = DebtManagementProvider(service: service);

      await provider.loadDebts();
      expect(provider.debts.length, 20);
      expect(provider.hasMore, isTrue);

      await provider.loadMore();
      expect(provider.debts.length, 25);
      expect(provider.debts.map((debt) => debt.id).toSet().length, 25);
      expect(provider.hasMore, isFalse);
    });

    test('subscription write denial uses the existing friendly message',
        () async {
      final service = _FakeDebtService([_debt(1)])
        ..failNextWrite = DioException(
          requestOptions: RequestOptions(path: '/api/v1/businesses/debts/1/'),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 403,
          ),
        );
      final provider = DebtManagementProvider(service: service);
      await provider.loadDebts();

      final ok = await provider.markPaid(1);

      expect(ok, isFalse);
      expect(provider.errorMessage, kSubscriptionRequiredMessage);
      expect(provider.debts.single.isOutstanding, isTrue);
    });

    test('missing debt endpoint shows the same availability message', () async {
      final notFound = DioException(
        requestOptions: RequestOptions(path: '/api/v1/businesses/debts/'),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 404,
        ),
      );
      final service = _FakeDebtService([])..failNextLoad = notFound;
      final provider = DebtManagementProvider(service: service);

      await provider.loadDebts();

      const expected = 'Huduma ya Madeni bado haijawashwa kwenye seva hii.';
      expect(provider.errorMessage, expected);

      service.failNextWrite = DioException(
        requestOptions: RequestOptions(path: '/api/v1/businesses/debts/'),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 404,
        ),
      );
      final saved = await provider.createDebt(
        customerName: 'Asha',
        amount: '15000',
        dateGiven: DateTime(2026, 8, 5),
      );

      expect(saved, isFalse);
      expect(provider.errorMessage, expected);
    });
  });
}

class _FakeDebtService implements DebtManagementApi {
  _FakeDebtService(List<BusinessDebt> debts) : _debts = [...debts];

  List<BusinessDebt> _debts;
  Object? failNextWrite;
  Object? failNextLoad;
  int _nextId = 100;

  @override
  Future<PaginatedDebts> getDebtsPage({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (failNextLoad case final error?) {
      failNextLoad = null;
      throw error;
    }
    final filtered = status == null
        ? _debts
        : _debts.where((debt) => debt.status == status).toList();
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);
    final items = start >= filtered.length
        ? <BusinessDebt>[]
        : filtered.sublist(start, end);
    return PaginatedDebts(
      items: items,
      count: filtered.length,
      next: end < filtered.length ? 'next' : null,
      previous: page > 1 ? 'previous' : null,
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
    _throwIfNeeded();
    final debt = _fromValues(
      id: _nextId++,
      customerName: customerName,
      amount: amount,
      itemService: itemService,
      note: note,
      dateGiven: dateGiven,
      dueDate: dueDate,
      status: status,
    );
    _debts = [..._debts, debt];
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
    _throwIfNeeded();
    final index = _debts.indexWhere((debt) => debt.id == id);
    final current = _debts[index];
    final updated = _fromValues(
      id: id,
      customerName: customerName ?? current.customerName,
      amount: amount ?? current.amount,
      itemService: itemService ?? current.itemService,
      note: note ?? current.note,
      dateGiven: dateGiven ?? current.dateGiven!,
      dueDate: clearDueDate ? null : (dueDate ?? current.dueDate),
      status: status ?? current.status,
    );
    _debts[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteDebt(int id) async {
    _throwIfNeeded();
    _debts = _debts.where((debt) => debt.id != id).toList();
  }

  void _throwIfNeeded() {
    if (failNextWrite == null) return;
    final error = failNextWrite!;
    failNextWrite = null;
    throw error;
  }
}

BusinessDebt _debt(int id, {String status = 'outstanding'}) => _fromValues(
      id: id,
      customerName: 'Mteja $id',
      amount: '1000.00',
      itemService: '',
      note: '',
      dateGiven: DateTime(2026, 8, 1),
      dueDate: null,
      status: status,
    );

BusinessDebt _fromValues({
  required int id,
  required String customerName,
  required String amount,
  required String itemService,
  required String note,
  required DateTime dateGiven,
  required DateTime? dueDate,
  required String status,
}) {
  return BusinessDebt.fromJson({
    'id': id,
    'customer_name': customerName,
    'amount': amount,
    'item_service': itemService,
    'note': note,
    'date_given': dateGiven.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
    'status': status,
    'created_at': '2026-08-01T08:00:00Z',
    'updated_at': '2026-08-01T08:00:00Z',
  });
}
