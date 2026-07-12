import 'package:flutter/foundation.dart';

import '../../payments/services/iap_service.dart';

/// Subscription purchase/restore state for a premium-purchase screen
/// (issue #33, not built yet) to drive. Mirrors
/// `payments/providers/iap_provider.dart`'s course-purchase pattern, but
/// targets [IAPProductKind.subscription] — Apple/Google verify endpoints,
/// not the one-time course-purchase endpoint.
///
/// Nothing here decides entitlement: a [purchaseSuccess]/[restoreSuccess]
/// flip means the backend already verified the purchase and updated
/// `UserSubscription` (see `IAPService._verifySubscriptionWithBackend`) —
/// the actual "what can this user do now" state still only ever comes from
/// `SubscriptionService.getEntitlementStatus()` (`subscriptions/me/`).
class SubscriptionPurchaseProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  bool purchaseSuccess = false;
  bool restoreSuccess = false;
  bool isPending = false;

  Future<bool> initialize(String productId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final ready = await IAPService.instance.initialize();
      if (!ready) {
        errorMessage = 'Usajili haupatikani kwenye kifaa hiki.';
        return false;
      }
      await IAPService.instance.loadProducts({productId});
      return true;
    } catch (_) {
      errorMessage = 'Hitilafu ya mtandao. Jaribu tena baadaye.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> purchase(String productId) async {
    isLoading = true;
    errorMessage = null;
    purchaseSuccess = false;
    isPending = false;
    notifyListeners();

    try {
      final result = await IAPService.instance.purchase(
        productId,
        kind: IAPProductKind.subscription,
      );
      _applyResult(result, onSuccess: () => purchaseSuccess = true);
    } catch (_) {
      errorMessage = 'Hitilafu ya mtandao. Jaribu tena baadaye.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Replays existing store purchases so a reinstalled app or a new
  /// device can recover an active subscription — see
  /// `IAPService.restorePurchases`. Safe to call any number of times.
  Future<void> restore() async {
    isLoading = true;
    errorMessage = null;
    restoreSuccess = false;
    notifyListeners();

    try {
      final result = await IAPService.instance.restorePurchases();
      _applyResult(result, onSuccess: () => restoreSuccess = true);
    } catch (_) {
      errorMessage = 'Hitilafu ya mtandao. Jaribu tena baadaye.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _applyResult(IAPPurchaseResult result,
      {required VoidCallback onSuccess}) {
    switch (result.result) {
      case IAPResult.success:
        onSuccess();
        break;
      case IAPResult.pending:
        isPending = true;
        errorMessage = 'Malipo yanasubiri uthibitisho.';
        break;
      case IAPResult.cancelled:
        errorMessage = null;
        break;
      case IAPResult.error:
        errorMessage = result.message ?? 'Hitilafu ya usajili. Jaribu tena.';
        break;
    }
  }

  void reset() {
    isLoading = false;
    errorMessage = null;
    purchaseSuccess = false;
    restoreSuccess = false;
    isPending = false;
    notifyListeners();
  }
}
