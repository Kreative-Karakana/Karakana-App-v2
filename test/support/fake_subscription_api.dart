import 'package:karakana_app/features/subscriptions/models/entitlement_status.dart';
import 'package:karakana_app/features/subscriptions/models/subscription_plan.dart';
import 'package:karakana_app/features/subscriptions/models/trial_activation_result.dart';
import 'package:karakana_app/features/subscriptions/services/subscription_service.dart';

/// Always reports an active subscription unless told otherwise — the
/// default for tests that aren't specifically exercising the read-only
/// state (issue #31), so they don't depend on real network access.
class FakeSubscriptionApi implements SubscriptionApi {
  FakeSubscriptionApi({
    this.status = _activeStatus,
    this.plans = const [],
    this.trialActivationResult,
  });

  static const _activeStatus = EntitlementStatus(
    hasActiveSubscription: true,
    status: 'active',
    expiryDate: null,
  );

  EntitlementStatus status;
  List<SubscriptionPlan> plans;
  TrialActivationResult? trialActivationResult;
  Object? failNext;
  Object? failNextPlans;
  Object? failNextTrialActivation;

  @override
  Future<EntitlementStatus> getEntitlementStatus() async {
    if (failNext != null) {
      final error = failNext!;
      failNext = null;
      throw error;
    }
    return status;
  }

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    if (failNextPlans != null) {
      final error = failNextPlans!;
      failNextPlans = null;
      throw error;
    }
    return plans;
  }

  @override
  Future<TrialActivationResult> activateTrial() async {
    if (failNextTrialActivation != null) {
      final error = failNextTrialActivation!;
      failNextTrialActivation = null;
      throw error;
    }
    final result = trialActivationResult ??
        TrialActivationResult(trialStarted: true, entitlement: status);
    status = result.entitlement;
    return result;
  }
}
