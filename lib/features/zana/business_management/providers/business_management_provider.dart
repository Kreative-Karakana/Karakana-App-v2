import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../models/business.dart';
import '../models/business_dashboard_summary.dart';
import '../models/business_transaction.dart';
import '../services/business_management_service.dart';

class BusinessManagementProvider extends ChangeNotifier {
  final BusinessManagementApi _service;

  BusinessManagementProvider({BusinessManagementApi? service})
      : _service = service ?? BusinessManagementService();

  static const int _transactionPageSize = 20;

  Business? _business;
  BusinessDashboardSummary? _dashboardSummary;
  List<BusinessTransaction> _transactions = [];
  bool _isLoading = false;
  bool _isLoadingDashboard = false;
  bool _isLoadingTransactions = false;
  bool _isLoadingMoreTransactions = false;
  bool _isSubmitting = false;
  bool _hasNoBusiness = false;
  String? _errorMessage;
  String? _loadMoreTransactionsError;
  String? _selectedTransactionType;
  String? _selectedCategory;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _searchQuery = '';
  String? _ordering;
  int _currentTransactionPage = 0;
  int _transactionCount = 0;
  bool _hasMoreTransactions = false;

  Business? get business => _business;
  BusinessDashboardSummary? get dashboardSummary => _dashboardSummary;
  List<BusinessTransaction> get transactions =>
      List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isLoadingMoreTransactions => _isLoadingMoreTransactions;
  bool get isSubmitting => _isSubmitting;
  bool get hasNoBusiness => _hasNoBusiness;
  String? get errorMessage => _errorMessage;
  String? get loadMoreTransactionsError => _loadMoreTransactionsError;
  String? get selectedTransactionType => _selectedTransactionType;
  String? get selectedCategory => _selectedCategory;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  String get searchQuery => _searchQuery;
  String? get ordering => _ordering;
  int get transactionCount => _transactionCount;
  bool get hasMoreTransactions => _hasMoreTransactions;
  bool get hasActiveFilters =>
      _selectedTransactionType != null ||
      _selectedCategory != null ||
      _dateFrom != null ||
      _dateTo != null ||
      _searchQuery.isNotEmpty ||
      _ordering != null;

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
        _resetTransactions();
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

  /// Loads the first page of transactions for the given filters, replacing
  /// whatever is currently loaded and resetting pagination state.
  Future<void> loadTransactions({
    String? transactionType,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    String? ordering,
    bool notify = true,
  }) async {
    _selectedTransactionType = transactionType ?? _selectedTransactionType;
    _selectedCategory = category ?? _selectedCategory;
    _dateFrom = dateFrom ?? _dateFrom;
    _dateTo = dateTo ?? _dateTo;
    _searchQuery = search ?? _searchQuery;
    _ordering = ordering ?? _ordering;
    _isLoadingTransactions = true;
    _isLoadingMoreTransactions = false;
    _errorMessage = null;
    _loadMoreTransactionsError = null;
    _currentTransactionPage = 0;
    _transactionCount = 0;
    _hasMoreTransactions = false;
    if (notify) notifyListeners();

    try {
      final page = await _service.getTransactionsPage(
        transactionType: _selectedTransactionType,
        category: _selectedCategory,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        search: _searchQuery,
        ordering: _ordering,
        page: 1,
        pageSize: _transactionPageSize,
      );
      _currentTransactionPage = 1;
      _transactionCount = page.count;
      _hasMoreTransactions = page.hasNext;
      _transactions = _dedupeTransactions(page.items);
      _hasNoBusiness = false;
    } catch (e) {
      if (_isNotFound(e)) {
        _hasNoBusiness = true;
        _resetTransactions();
      } else {
        _errorMessage = ApiClient().parseError(e);
      }
    } finally {
      _isLoadingTransactions = false;
      if (notify) notifyListeners();
    }
  }

  /// Fetches the next page of transactions for the current filters and
  /// appends it to the already-loaded list, deduplicating by id.
  Future<void> loadMoreTransactions() async {
    if (_isLoadingTransactions ||
        _isLoadingMoreTransactions ||
        !_hasMoreTransactions) {
      return;
    }

    _isLoadingMoreTransactions = true;
    _loadMoreTransactionsError = null;
    notifyListeners();

    try {
      final page = await _service.getTransactionsPage(
        transactionType: _selectedTransactionType,
        category: _selectedCategory,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        search: _searchQuery,
        ordering: _ordering,
        page: _currentTransactionPage + 1,
        pageSize: _transactionPageSize,
      );
      _currentTransactionPage += 1;
      _transactionCount = page.count;
      _hasMoreTransactions = page.hasNext;
      _transactions = _dedupeTransactions([..._transactions, ...page.items]);
    } catch (e) {
      _loadMoreTransactionsError = ApiClient().parseError(e);
    } finally {
      _isLoadingMoreTransactions = false;
      notifyListeners();
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

  /// Replaces every transaction-history filter/search/sort dimension in one
  /// call and reloads page 1. Unlike [loadTransactions] — which only merges
  /// non-null values into whatever filters are already active — every
  /// argument here (including a null/empty one) becomes the new value, so
  /// this is the only way to clear a single dimension (e.g. category) while
  /// leaving the others as they are: read the current getters and pass them
  /// back alongside the one that's changing.
  Future<void> applyFilters({
    String? transactionType,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    String search = '',
    String? ordering,
  }) {
    _selectedTransactionType = transactionType;
    _selectedCategory = category;
    _dateFrom = dateFrom;
    _dateTo = dateTo;
    _searchQuery = search;
    _ordering = ordering;
    return loadTransactions();
  }

  /// Quick single-tap switch between Yote/Mauzo/Matumizi. Resets category,
  /// since sale and expense categories don't overlap.
  Future<void> setTransactionType(String? value) {
    return applyFilters(
      transactionType: value,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      search: _searchQuery,
      ordering: _ordering,
    );
  }

  /// Clears every active filter, search term, and sort order and reloads
  /// page 1 of the unfiltered transaction history.
  Future<void> resetFilters() => applyFilters();

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

  void _resetTransactions() {
    _transactions = [];
    _currentTransactionPage = 0;
    _transactionCount = 0;
    _hasMoreTransactions = false;
  }

  List<BusinessTransaction> _dedupeTransactions(
    List<BusinessTransaction> items,
  ) {
    final seen = <int>{};
    return [
      for (final item in items)
        if (seen.add(item.id)) item,
    ];
  }

  bool _isNotFound(Object error) {
    return error is DioException && error.response?.statusCode == 404;
  }
}
