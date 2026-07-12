/// A gate-able capability granted by a [SubscriptionPlan] — mirrors
/// `subscriptions.Feature` on the backend (see docs/apps/subscriptions.md).
class SubscriptionFeature {
  final String code;
  final String name;
  final String description;

  const SubscriptionFeature({
    required this.code,
    required this.name,
    required this.description,
  });

  factory SubscriptionFeature.fromJson(Map<String, dynamic> json) {
    return SubscriptionFeature(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

/// Mirrors `SubscriptionPlanSerializer` (`GET /api/v1/subscriptions/plans/`
/// and the `subscription.plan` shape nested in `subscriptions/me/`) — see
/// docs/apps/subscriptions.md. Display-only: nothing here decides
/// entitlement, it only describes a plan Flutter can show or offer to buy.
class SubscriptionPlan {
  final int id;
  final String name;
  final String slug;
  final String billingPeriod;
  final int durationDays;
  final String price;
  final String currency;
  final List<SubscriptionFeature> features;

  /// Store product ids for [IAPService.purchase]. Not yet returned by
  /// `SubscriptionPlanSerializer` as of issue #33 — always null until a
  /// backend follow-up exposes `SubscriptionPlan.apple_iap_product_id`/
  /// `google_play_product_id` on the catalog endpoints. Parsed defensively
  /// so the purchase UI degrades to "unavailable" instead of crashing, and
  /// starts working the moment the backend adds them, with no Flutter
  /// change required.
  final String? appleIapProductId;
  final String? googlePlayProductId;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.slug,
    required this.billingPeriod,
    required this.durationDays,
    required this.price,
    required this.currency,
    required this.features,
    this.appleIapProductId,
    this.googlePlayProductId,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    return SubscriptionPlan(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      billingPeriod: (json['billing_period'] ?? '').toString(),
      durationDays: json['duration_days'] is int
          ? json['duration_days'] as int
          : int.tryParse('${json['duration_days']}') ?? 0,
      price: (json['price'] ?? '0').toString(),
      currency: (json['currency'] ?? 'TZS').toString(),
      features: rawFeatures is List
          ? rawFeatures
              .whereType<Map>()
              .map((f) =>
                  SubscriptionFeature.fromJson(f.cast<String, dynamic>()))
              .toList()
          : const [],
      appleIapProductId: json['apple_iap_product_id']?.toString(),
      googlePlayProductId: json['google_play_product_id']?.toString(),
    );
  }
}
