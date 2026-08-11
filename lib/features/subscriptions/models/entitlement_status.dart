import 'subscription_plan.dart';

/// Mirrors the response shape of `GET /api/v1/subscriptions/me/` — see
/// backend docs/apps/subscriptions.md. `status` is always the
/// backend-derived label (never/trial/active/expired/cancelled/suspended);
/// Flutter must never infer entitlement from anything else, since the
/// backend is the only source of truth for whether writes are allowed.
class EntitlementStatus {
  final bool hasActiveSubscription;
  final bool trialEligible;
  final String status;
  final DateTime? expiryDate;
  final DateTime? startDate;
  final SubscriptionPlan? plan;
  final List<String> featureCodes;

  const EntitlementStatus({
    required this.hasActiveSubscription,
    required this.trialEligible,
    required this.status,
    required this.expiryDate,
    this.startDate,
    this.plan,
    this.featureCodes = const [],
  });

  bool get isNone => status == 'none';
  bool get isTrial => status == 'trial';
  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';
  bool get isSuspended => status == 'suspended';

  /// True once we know (from the backend) that the user previously had
  /// access and it lapsed — as opposed to never having subscribed at all.
  /// Both render the same "read-only, needs upgrade" state in the business
  /// screens, but the messaging differs (see [BusinessManagementProvider]).
  bool get hadPriorAccess => !hasActiveSubscription && !isNone;

  /// Whole calendar days left until [expiryDate], clamped to zero — never
  /// negative, and never a fractional day, so a countdown reads e.g.
  /// "Jaribio lako limebaki siku 2" instead of "1.4". Null when there's no
  /// expiry to count down to (e.g. [isNone]).
  int? get remainingDays {
    final expiry = expiryDate;
    if (expiry == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final diff = expiryDay.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory EntitlementStatus.fromJson(Map<String, dynamic> json) {
    final subscription = json['subscription'];
    DateTime? expiryDate;
    DateTime? startDate;
    SubscriptionPlan? plan;
    if (subscription is Map) {
      if (subscription['expiry_date'] != null) {
        expiryDate = DateTime.tryParse(subscription['expiry_date'].toString());
      }
      if (subscription['start_date'] != null) {
        startDate = DateTime.tryParse(subscription['start_date'].toString());
      }
      final rawPlan = subscription['plan'];
      if (rawPlan is Map) {
        plan = SubscriptionPlan.fromJson(rawPlan.cast<String, dynamic>());
      }
    }
    final rawFeatures = json['features'];
    return EntitlementStatus(
      hasActiveSubscription: json['has_active_subscription'] == true,
      trialEligible: json['trial_eligible'] == true,
      status: (json['status'] ?? 'none').toString(),
      expiryDate: expiryDate,
      startDate: startDate,
      plan: plan,
      featureCodes: rawFeatures is List
          ? rawFeatures.map((f) => f.toString()).toList()
          : const [],
    );
  }
}
