import 'package:karakana_app/features/subscriptions/models/entitlement_status.dart';
import 'package:karakana_app/features/subscriptions/models/subscription_checkout.dart';
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
    trialEligible: false,
    status: 'active',
    expiryDate: null,
  );

  EntitlementStatus status;
  List<SubscriptionPlan> plans;
  TrialActivationResult? trialActivationResult;
  SubscriptionCheckoutResponse? checkoutResponse;
  PaymentStatus paymentStatus = const PaymentStatus(
    isSuccessful: false,
    isFailed: false,
    status: 'pending',
  );
  List<SubscriptionCheckoutRequest> checkoutRequests = [];
  int paymentStatusCalls = 0;
  int entitlementStatusCalls = 0;
  Object? failNext;
  Object? failNextPlans;
  Object? failNextTrialActivation;
  Object? failNextCheckout;
  Object? failNextPaymentStatus;

  @override
  Future<EntitlementStatus> getEntitlementStatus() async {
    entitlementStatusCalls += 1;
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

  @override
  Future<SubscriptionCheckoutResponse> createCheckout(
    SubscriptionCheckoutRequest request,
  ) async {
    if (failNextCheckout != null) {
      final error = failNextCheckout!;
      failNextCheckout = null;
      throw error;
    }
    checkoutRequests.add(request);
    return checkoutResponse ??
        const SubscriptionCheckoutResponse(
          payment: SubscriptionCheckoutPayment(
            externalId: 'pay-test-1',
            amount: '5000.00',
            expectedAmount: '5000.00',
            currency: 'TZS',
            purpose: 'subscription',
            plan: null,
            checkoutUrl: 'https://pay.example.test/checkout',
            gateway: 'evpay',
            success: true,
            reference: 'pay-test-1',
            responseCode: '200',
            responseDesc: 'Accepted',
            orderId: 'order-test-1',
            source: 'test',
          ),
        );
  }

  @override
  Future<PaymentStatus> getPaymentStatus(String externalId) async {
    paymentStatusCalls += 1;
    if (failNextPaymentStatus != null) {
      final error = failNextPaymentStatus!;
      failNextPaymentStatus = null;
      throw error;
    }
    return paymentStatus;
  }
}
