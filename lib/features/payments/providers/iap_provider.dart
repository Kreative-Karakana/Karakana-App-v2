import 'package:flutter/foundation.dart';

import '../services/iap_service.dart';

class IAPProvider extends ChangeNotifier {
  IAPProvider({SubscriptionPurchaseStore? store})
    : _store = store ?? IAPService.instance;

  final SubscriptionPurchaseStore _store;

  bool isLoading = false;
  String? errorMessage;
  bool purchaseSuccess = false;

  Future<void> initializeForCourse(String productId) =>
      initializeForProduct(productId, kind: IAPProductKind.course);

  Future<void> initializeForEbook(String productId) =>
      initializeForProduct(productId, kind: IAPProductKind.ebook);

  Future<void> initializeForProduct(
    String productId, {
    required IAPProductKind kind,
  }) async {
    isLoading = true;
    errorMessage = null;
    purchaseSuccess = false;
    notifyListeners();

    try {
      final ready = await _store.initialize();
      if (!ready) {
        errorMessage = 'Uthibitisho wa malipo umeshindwa. Wasiliana na msaada.';
        return;
      }
      await _store.loadProducts({productId}, kind: kind);
    } catch (_) {
      errorMessage = 'Hitilafu ya mtandao. Jaribu tena baadaye.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> purchase(
    String productId, {
    IAPProductKind kind = IAPProductKind.course,
  }) async {
    isLoading = true;
    errorMessage = null;
    purchaseSuccess = false;
    notifyListeners();

    try {
      final result = await _store.purchase(productId, kind: kind);
      switch (result.result) {
        case IAPResult.success:
          purchaseSuccess = true;
          break;
        case IAPResult.pending:
          errorMessage = 'Malipo yanasubiri uthibitisho.';
          break;
        case IAPResult.cancelled:
          errorMessage = null;
          break;
        case IAPResult.nothingToRestore:
          errorMessage = null;
          break;
        case IAPResult.error:
          errorMessage = result.message ?? 'Hitilafu ya malipo. Jaribu tena.';
          break;
      }
    } catch (_) {
      errorMessage = 'Hitilafu ya mtandao. Jaribu tena baadaye.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? localizedPrice(String productId) =>
      _store.getProduct(productId)?.price;

  void reset() {
    isLoading = false;
    errorMessage = null;
    purchaseSuccess = false;
    notifyListeners();
  }
}
