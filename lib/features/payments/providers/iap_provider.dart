import 'package:flutter/foundation.dart';

import '../services/iap_service.dart';

class IAPProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  bool purchaseSuccess = false;

  Future<void> initializeForCourse(String productId) async {
    isLoading = true;
    errorMessage = null;
    purchaseSuccess = false;
    notifyListeners();

    try {
      final ready = await IAPService.instance.initialize();
      if (!ready) {
        errorMessage = 'Uthibitisho wa malipo umeshindwa. Wasiliana na msaada.';
        return;
      }
      await IAPService.instance.loadProducts({productId});
    } catch (_) {
      errorMessage = 'Hitilafu ya mtandao. Jaribu tena baadaye.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> purchase(String productId) async {
    isLoading = true;
    errorMessage = null;
    purchaseSuccess = false;
    notifyListeners();

    try {
      final result = await IAPService.instance.purchase(productId);
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

  void reset() {
    isLoading = false;
    errorMessage = null;
    purchaseSuccess = false;
    notifyListeners();
  }
}
