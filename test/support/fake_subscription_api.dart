import 'package:karakana_app/features/subscriptions/models/entitlement_status.dart';
import 'package:karakana_app/features/subscriptions/services/subscription_service.dart';

/// Always reports an active subscription unless told otherwise — the
/// default for tests that aren't specifically exercising the read-only
/// state (issue #31), so they don't depend on real network access.
class FakeSubscriptionApi implements SubscriptionApi {
  FakeSubscriptionApi({this.status = _activeStatus});

  static const _activeStatus = EntitlementStatus(
    hasActiveSubscription: true,
    status: 'active',
    expiryDate: null,
  );

  EntitlementStatus status;
  Object? failNext;

  @override
  Future<EntitlementStatus> getEntitlementStatus() async {
    if (failNext != null) {
      final error = failNext!;
      failNext = null;
      throw error;
    }
    return status;
  }
}
