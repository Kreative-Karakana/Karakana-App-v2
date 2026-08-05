import '../models/entitlement_status.dart';

const businessManagementRoute = '/zana/biz-manager';

typedef EntitlementLoader = Future<EntitlementStatus?> Function();
typedef RedirectCallback = Future<void> Function();
typedef DelayCallback = Future<void> Function(Duration duration);

/// Confirms a newly activated entitlement with the backend before allowing
/// the subscription screen to redirect into Business Management.
///
/// Multiple payment/trial callbacks can arrive close together. Sharing the
/// in-flight check and remembering a completed redirect prevents duplicate
/// navigation while still allowing a later retry when a gateway callback is
/// slower than the first bounded check.
class PostActivationRedirectCoordinator {
  Future<bool>? _inFlight;
  bool _hasRedirected = false;

  bool get hasRedirected => _hasRedirected;

  Future<bool> confirmAndRedirect({
    required EntitlementLoader refreshEntitlement,
    required RedirectCallback redirect,
    int maxAttempts = 4,
    Duration retryDelay = const Duration(milliseconds: 750),
    DelayCallback? delay,
  }) async {
    if (_hasRedirected) return true;
    final current = _inFlight;
    if (current != null) return await current;

    final operation = _confirmAndRedirect(
      refreshEntitlement: refreshEntitlement,
      redirect: redirect,
      maxAttempts: maxAttempts < 1 ? 1 : maxAttempts,
      retryDelay: retryDelay,
      delay: delay ?? Future<void>.delayed,
    );
    _inFlight = operation;
    try {
      return await operation;
    } finally {
      if (identical(_inFlight, operation)) _inFlight = null;
    }
  }

  Future<bool> _confirmAndRedirect({
    required EntitlementLoader refreshEntitlement,
    required RedirectCallback redirect,
    required int maxAttempts,
    required Duration retryDelay,
    required DelayCallback delay,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt += 1) {
      EntitlementStatus? entitlement;
      try {
        entitlement = await refreshEntitlement();
      } catch (_) {
        // A transient refresh failure is treated like an unconfirmed result.
      }

      if (entitlement?.hasActiveSubscription == true) {
        _hasRedirected = true;
        await redirect();
        return true;
      }

      if (attempt + 1 < maxAttempts) await delay(retryDelay);
    }
    return false;
  }
}
