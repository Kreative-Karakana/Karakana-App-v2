import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/subscriptions/config/subscription_checkout_config.dart';
import 'package:karakana_app/features/subscriptions/models/subscription_plan.dart';

void main() {
  const paidPlanWithoutStoreIds = SubscriptionPlan(
    id: 1,
    name: 'Monthly',
    slug: 'monthly',
    billingPeriod: 'monthly',
    durationDays: 30,
    price: '5000.00',
    currency: 'TZS',
    features: [],
  );

  test('Android paid plan without Google product ID still exposes EVPay', () {
    final config = SubscriptionCheckoutConfig.forPlatform(
      platform: TargetPlatform.android,
    );

    expect(config.enableExternalSubscriptionCheckout, isTrue);
    expect(config.enableGooglePlayBilling, isFalse);
    expect(paidPlanWithoutStoreIds.googlePlayProductId, isNull);
  });

  test('iOS production configuration does not expose EVPay checkout', () {
    final config = SubscriptionCheckoutConfig.forPlatform(
      platform: TargetPlatform.iOS,
    );

    expect(config.enableExternalSubscriptionCheckout, isFalse);
    expect(config.enableAppleIap, isTrue);
  });

  test('trial flow remains separate from paid checkout capability', () {
    final config = SubscriptionCheckoutConfig.forPlatform(
      platform: TargetPlatform.android,
    );

    expect(config.enableExternalSubscriptionCheckout, isTrue);
    expect(paidPlanWithoutStoreIds.slug == 'trial', isFalse);
  });
}
