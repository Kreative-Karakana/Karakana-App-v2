import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/payments/utils/payment_url_launcher.dart';
import 'package:karakana_app/features/subscriptions/models/entitlement_status.dart';
import 'package:karakana_app/features/subscriptions/models/subscription_checkout.dart';
import 'package:karakana_app/features/subscriptions/models/subscription_plan.dart';
import 'package:karakana_app/features/subscriptions/providers/subscription_checkout_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'support/fake_subscription_api.dart';

void main() {
  const plan = SubscriptionPlan(
    id: 1,
    name: 'Monthly',
    slug: 'monthly',
    billingPeriod: 'monthly',
    durationDays: 30,
    price: '5000.00',
    currency: 'TZS',
    features: [],
  );

  PaymentUrlLauncher launcher({bool opens = true}) {
    return PaymentUrlLauncher(
      launchUrlDelegate: (uri, mode) async => opens,
    );
  }

  test('pending state does not grant entitlement', () async {
    final api = FakeSubscriptionApi();
    var refreshes = 0;
    final provider = SubscriptionCheckoutProvider(
      service: api,
      urlLauncher: launcher(),
      pollInterval: const Duration(milliseconds: 10),
    );

    await provider.startCheckout(
      plan: plan,
      rawPhoneNumber: '0712345678',
      provider: 'mpesa',
      refreshEntitlement: () async => refreshes += 1,
    );
    provider.dispose();

    expect(provider.state, SubscriptionCheckoutState.waitingForPayment);
    expect(refreshes, 0);
  });

  test('successful payment polling triggers entitlement refresh', () async {
    final api = FakeSubscriptionApi()
      ..paymentStatus = const PaymentStatus(
        isSuccessful: true,
        isFailed: false,
        status: 'success',
      );
    var refreshes = 0;
    final provider = SubscriptionCheckoutProvider(
      service: api,
      urlLauncher: launcher(),
    );

    await provider.startCheckout(
      plan: plan,
      rawPhoneNumber: '0712345678',
      provider: 'mpesa',
      refreshEntitlement: () async => refreshes += 1,
    );
    await provider.checkPendingPayment(
      refreshEntitlement: () async => refreshes += 1,
    );
    provider.dispose();

    expect(provider.state, SubscriptionCheckoutState.successful);
    expect(refreshes, 1);
  });

  test('failed payment does not grant entitlement', () async {
    final api = FakeSubscriptionApi()
      ..paymentStatus = const PaymentStatus(
        isSuccessful: false,
        isFailed: true,
        status: 'failed',
      );
    var refreshes = 0;
    final provider = SubscriptionCheckoutProvider(
      service: api,
      urlLauncher: launcher(),
    );

    await provider.startCheckout(
      plan: plan,
      rawPhoneNumber: '0712345678',
      provider: 'mpesa',
      refreshEntitlement: () async => refreshes += 1,
    );
    await provider.checkPendingPayment(
      refreshEntitlement: () async => refreshes += 1,
    );
    provider.dispose();

    expect(provider.state, SubscriptionCheckoutState.failed);
    expect(refreshes, 0);
  });

  test('timed-out payment remains available for a later status check',
      () async {
    final api = FakeSubscriptionApi();
    final provider = SubscriptionCheckoutProvider(
      service: api,
      urlLauncher: launcher(),
      pollInterval: const Duration(days: 1),
      maxPollAttempts: 1,
    );

    await provider.startCheckout(
      plan: plan,
      rawPhoneNumber: '0712345678',
      provider: 'mpesa',
      refreshEntitlement: () async {},
    );
    await provider.checkPendingPayment(refreshEntitlement: () async {});

    expect(provider.state, SubscriptionCheckoutState.timedOut);
    expect(provider.hasPendingCheckout, isTrue);
    expect(provider.pendingPlanSlug, plan.slug);
    provider.dispose();
  });

  test('duplicate polling does not duplicate state transitions', () async {
    final api = FakeSubscriptionApi();
    final provider = SubscriptionCheckoutProvider(
      service: api,
      urlLauncher: launcher(),
      pollInterval: const Duration(days: 1),
    );

    await provider.startCheckout(
      plan: plan,
      rawPhoneNumber: '0712345678',
      provider: 'mpesa',
      refreshEntitlement: () async {},
    );
    provider.startPolling(refreshEntitlement: () async {});
    provider.startPolling(refreshEntitlement: () async {});
    await provider.checkPendingPayment(refreshEntitlement: () async {});
    provider.dispose();

    expect(api.paymentStatusCalls, 1);
    expect(provider.state, SubscriptionCheckoutState.waitingForPayment);
  });

  test('app resume checks a pending payment and reloads entitlement', () async {
    final api = FakeSubscriptionApi()
      ..status = const EntitlementStatus(
        hasActiveSubscription: false,
        status: 'none',
        expiryDate: null,
      );
    final provider = SubscriptionCheckoutProvider(
      service: api,
      urlLauncher: launcher(),
      pollInterval: const Duration(days: 1),
    );

    await provider.startCheckout(
      plan: plan,
      rawPhoneNumber: '0712345678',
      provider: 'mpesa',
      refreshEntitlement: api.getEntitlementStatus,
    );
    await provider.handleAppResumed(
      refreshEntitlement: api.getEntitlementStatus,
    );
    provider.dispose();

    expect(api.paymentStatusCalls, 1);
    expect(api.entitlementStatusCalls, greaterThanOrEqualTo(1));
  });

  test('checkout request normalizes phone and provider alias for backend',
      () async {
    final api = FakeSubscriptionApi();
    final provider = SubscriptionCheckoutProvider(
      service: api,
      urlLauncher: launcher(),
    );

    await provider.startCheckout(
      plan: plan,
      rawPhoneNumber: '071 234 5678',
      provider: 'mpesa',
      refreshEntitlement: () async {},
    );
    provider.dispose();

    expect(api.checkoutRequests.single.toJson(), {
      'plan_slug': 'monthly',
      'accountNumber': '255712345678',
      'provider': 'mpesa',
    });
  });

  test('URL launcher uses robust fallback order', () async {
    final modes = <LaunchMode>[];
    final urlLauncher = PaymentUrlLauncher(
      launchUrlDelegate: (uri, mode) async {
        modes.add(mode);
        return mode == LaunchMode.platformDefault;
      },
    );

    final opened =
        await urlLauncher.openCheckoutUrl('https://pay.example.test/checkout');

    expect(opened, isTrue);
    expect(modes, [
      LaunchMode.externalApplication,
      LaunchMode.inAppBrowserView,
      LaunchMode.platformDefault,
    ]);
  });
}
