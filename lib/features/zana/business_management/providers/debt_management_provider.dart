import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../models/business_debt.dart';
import '../services/debt_management_service.dart';
import 'business_management_provider.dart';

class DebtManagementProvider extends ChangeNotifier {
  final DebtManagementApi _service;

  DebtManagementProvider({DebtManagementApi? service})
      : _service = service ?? DebtManagementService();

  static const int _pageSize = 20;
  static const String _endpointUnavailableMessage =
      'Huduma ya Madeni bado haijawashwa kwenye seva hii.';

  List<BusinessDebt> _debts = [];
  String? _selectedStatus;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  bool _hasMore = false;
  int _currentPage = 0;
  int _count = 0;
  String? _errorMessage;
  String? _loadMoreError;

  List<BusinessDebt> get debts => List.unmodifiable(_debts);
  String? get selectedStatus => _selectedStatus;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  bool get hasMore => _hasMore;
  int get count => _count;
  String? get errorMessage => _errorMessage;
  String? get loadMoreError => _loadMoreError;

  Future<void> loadDebts({String? status, bool notify = true}) async {
    _selectedStatus = status;
    _isLoading = true;
    _isLoadingMore = false;
    _currentPage = 0;
    _count = 0;
    _hasMore = false;
    _errorMessage = null;
    _loadMoreError = null;
    if (notify) notifyListeners();

    try {
      final page = await _service.getDebtsPage(
        status: _selectedStatus,
        page: 1,
        pageSize: _pageSize,
      );
      _debts = _dedupe(page.items);
      _count = page.count;
      _currentPage = 1;
      _hasMore = page.hasNext;
    } catch (error) {
      _errorMessage = _parseLoadError(error);
    } finally {
      _isLoading = false;
      if (notify) notifyListeners();
    }
  }

  Future<void> setStatusFilter(String? status) {
    return loadDebts(status: status);
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final page = await _service.getDebtsPage(
        status: _selectedStatus,
        page: _currentPage + 1,
        pageSize: _pageSize,
      );
      _debts = _dedupe([..._debts, ...page.items]);
      _count = page.count;
      _currentPage += 1;
      _hasMore = page.hasNext;
    } catch (error) {
      _loadMoreError = ApiClient().parseError(error);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createDebt({
    required String customerName,
    required String amount,
    required DateTime dateGiven,
    String itemService = '',
    String note = '',
    DateTime? dueDate,
    String status = 'outstanding',
  }) {
    return _submit(() => _service.createDebt(
          customerName: customerName,
          amount: amount,
          itemService: itemService,
          note: note,
          dateGiven: dateGiven,
          dueDate: dueDate,
          status: status,
        ));
  }

  Future<bool> updateDebt({
    required int id,
    required String customerName,
    required String amount,
    required String itemService,
    required String note,
    required DateTime dateGiven,
    DateTime? dueDate,
    required bool clearDueDate,
    required String status,
  }) {
    return _submit(() => _service.updateDebt(
          id: id,
          customerName: customerName,
          amount: amount,
          itemService: itemService,
          note: note,
          dateGiven: dateGiven,
          dueDate: dueDate,
          clearDueDate: clearDueDate,
          status: status,
        ));
  }

  Future<bool> markPaid(int id) {
    return _submit(() => _service.updateDebt(id: id, status: 'paid'));
  }

  Future<bool> deleteDebt(int id) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.deleteDebt(id);
      await loadDebts(status: _selectedStatus, notify: false);
      return true;
    } catch (error) {
      _setWriteError(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> _submit(Future<BusinessDebt> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      await loadDebts(status: _selectedStatus, notify: false);
      return true;
    } catch (error) {
      _setWriteError(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setWriteError(Object error) {
    if (error is DioException && error.response?.statusCode == 403) {
      _errorMessage = kSubscriptionRequiredMessage;
    } else if (error is DioException && error.response?.statusCode == 404) {
      _errorMessage = _endpointUnavailableMessage;
    } else {
      _errorMessage = ApiClient().parseError(error);
    }
  }

  String _parseLoadError(Object error) {
    if (error is DioException && error.response?.statusCode == 404) {
      return _endpointUnavailableMessage;
    }
    return ApiClient().parseError(error);
  }

  List<BusinessDebt> _dedupe(List<BusinessDebt> items) {
    final ids = <int>{};
    return [
      for (final item in items)
        if (ids.add(item.id)) item,
    ];
  }
}
