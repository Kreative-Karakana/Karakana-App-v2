import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../models/business.dart';
import '../models/business_dashboard_summary.dart';
import '../models/business_transaction.dart';
import '../services/business_management_service.dart';

class BusinessManagementProvider extends ChangeNotifier {
  final BusinessManagementService _service = BusinessManagementService();

  Business? _business;
  BusinessDashboardSummary? _dashboardSummary;
  List<BusinessTransaction> _transactions = [];
  bool _isLoading = false;
  bool _isLoadingDashboard = false;
  bool _isLoadingTransactions = false;
  bool _isSubmitting = false;
  bool _hasNoBusiness = false;
  String? _errorMessage;
  String? _selectedTransactionType;
  String? _selectedCategory;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  Business? get business => _business;
  BusinessDashboardSummary? get dashboardSummary => _dashboardSummary;
  List<BusinessTransaction> get transactions =>
      List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isSubmitting => _isSubmitting;
  bool get hasNoBusiness => _hasNoBusiness;
  String? get errorMessage => _errorMessage;
  String? get selectedTransactionType => _selectedTransactionType;
  String? get selectedCategory => _selectedCategory;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  Future<void> loadInitial() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _business = await _service.getMyBusiness();
      _hasNoBusiness = _business == null;
      if (!_hasNoBusiness) {
        await Future.wait([
          loadDashboard(notify: false),
          loadTransactions(notify: false),
        ]);
      }
    } catch (e) {
      if (_isNotFound(e)) {
        _business = null;
        _dashboardSummary = null;
        _transactions = [];
        _hasNoBusiness = true;
      } else {
        _errorMessage = ApiClient().parseError(e);
        if (kDebugMode) {
          debugPrint('[BusinessManagementProvider] loadInitial: $e');
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBusiness({
    required String name,
    required String businessType,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _business = await _service.createBusiness(
        name: name,
        businessType: businessType,
      );
      _hasNoBusiness = false;
      await Future.wait([
        loadDashboard(notify: false),
        loadTransactions(notify: false),
      ]);
      return true;
    } catch (e) {
      _errorMessage = ApiClient().parseError(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateBusiness({
    required String name,
    required String businessType,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _business = await _service.updateBusiness(
        name: name,
        businessType: businessType,
      );
      await loadDashboard(notify: false);
      return true;
    } catch (e) {
      _errorMessage = ApiClient().parseError(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboard({bool notify = true}) async {
    _isLoadingDashboard = true;
    _errorMessage = null;
    if (notify) notifyListeners();

    try {
      _dashboardSummary = await _service.getDashboard();
      _business = _dashboardSummary?.business ?? _business;
      _hasNoBusiness = false;
    } catch (e) {
      if (_isNotFound(e)) {
        _hasNoBusiness = true;
        _dashboardSummary = null;
      } else {
        _errorMessage = ApiClient().parseError(e);
      }
    } finally {
      _isLoadingDashboard = false;
      if (notify) notifyListeners();
    }
  }

  Future<void> loadTransactions({
    String? transactionType,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool notify = true,
  }) async {
    _selectedTransactionType = transactionType ?? _selectedTransactionType;
    _selectedCategory = category ?? _selectedCategory;
    _dateFrom = dateFrom ?? _dateFrom;
    _dateTo = dateTo ?? _dateTo;
    _isLoadingTransactions = true;
    _errorMessage = null;
    if (notify) notifyListeners();

    try {
      _transactions = await _service.getTransactions(
        transactionType: _selectedTransactionType,
        category: _selectedCategory,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );
      _hasNoBusiness = false;
    } catch (e) {
      if (_isNotFound(e)) {
        _hasNoBusiness = true;
        _transactions = [];
      } else {
        _errorMessage = ApiClient().parseError(e);
      }
    } finally {
      _isLoadingTransactions = false;
      if (notify) notifyListeners();
    }
  }

  Future<bool> createSale({
    required String amount,
    required String category,
    required DateTime transactionDate,
    String description = '',
  }) {
    return _createTransaction(
      transactionType: 'sale',
      amount: amount,
      category: category,
      transactionDate: transactionDate,
      description: description,
      fallbackError: 'Imeshindikana kurekodi Mauzo. Tafadhali jaribu tena.',
    );
  }

  Future<bool> createExpense({
    required String amount,
    required String category,
    required DateTime transactionDate,
    String description = '',
  }) {
    return _createTransaction(
      transactionType: 'expense',
      amount: amount,
      category: category,
      transactionDate: transactionDate,
      description: description,
      fallbackError: 'Imeshindikana kurekodi Matumizi. Tafadhali jaribu tena.',
    );
  }

  Future<bool> updateTransaction({
    required int id,
    String? transactionType,
    String? amount,
    String? category,
    DateTime? transactionDate,
    String? description,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateTransaction(
        id: id,
        transactionType: transactionType,
        amount: amount,
        category: category,
        transactionDate: transactionDate,
        description: description,
      );
      await Future.wait([
        loadDashboard(notify: false),
        loadTransactions(notify: false),
      ]);
      return true;
    } catch (e) {
      _errorMessage = ApiClient().parseError(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTransaction(int id) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteTransaction(id);
      await Future.wait([
        loadDashboard(notify: false),
        loadTransactions(notify: false),
      ]);
      return true;
    } catch (e) {
      _errorMessage = ApiClient().parseError(e);
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

  void clearFilters() {
    _selectedTransactionType = null;
    _selectedCategory = null;
    _dateFrom = null;
    _dateTo = null;
    notifyListeners();
  }

  Future<bool> _createTransaction({
    required String transactionType,
    required String amount,
    required String category,
    required DateTime transactionDate,
    required String description,
    required String fallbackError,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createTransaction(
        transactionType: transactionType,
        amount: amount,
        category: category,
        transactionDate: transactionDate,
        description: description,
      );
      await Future.wait([
        loadDashboard(notify: false),
        loadTransactions(notify: false),
      ]);
      return true;
    } catch (e) {
      final parsed = ApiClient().parseError(e);
      _errorMessage = parsed.isEmpty ? fallbackError : parsed;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  bool _isNotFound(Object error) {
    return error is DioException && error.response?.statusCode == 404;
  }
}
