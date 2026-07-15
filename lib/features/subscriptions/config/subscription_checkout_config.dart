import 'package:flutter/foundation.dart';

class SubscriptionCheckoutConfig {
  final bool enableExternalSubscriptionCheckout;
  final bool enableAppleIap;
  final bool enableGooglePlayBilling;

  const SubscriptionCheckoutConfig({
    required this.enableExternalSubscriptionCheckout,
    required this.enableAppleIap,
    required this.enableGooglePlayBilling,
  });

  factory SubscriptionCheckoutConfig.forPlatform({TargetPlatform? platform}) {
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    return SubscriptionCheckoutConfig(
      enableExternalSubscriptionCheckout:
          resolvedPlatform == TargetPlatform.android,
      enableAppleIap: resolvedPlatform == TargetPlatform.iOS,
      enableGooglePlayBilling: resolvedPlatform == TargetPlatform.android,
    );
  }
}

class SubscriptionPurchaseAvailability {
  final bool canUseExternalCheckout;
  final bool canUseStorePurchase;
  final String? storeProductId;

  const SubscriptionPurchaseAvailability({
    required this.canUseExternalCheckout,
    required this.canUseStorePurchase,
    required this.storeProductId,
  });
}
