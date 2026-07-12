/// Mirrors the response shape of `GET /api/v1/subscriptions/me/` — see
/// backend docs/apps/subscriptions.md. `status` is always the
/// backend-derived label (never/trial/active/expired/cancelled/suspended);
/// Flutter must never infer entitlement from anything else, since the
/// backend is the only source of truth for whether writes are allowed.
class EntitlementStatus {
  final bool hasActiveSubscription;
  final String status;
  final DateTime? expiryDate;

  const EntitlementStatus({
    required this.hasActiveSubscription,
    required this.status,
    required this.expiryDate,
  });

  bool get isNone => status == 'none';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';
  bool get isSuspended => status == 'suspended';

  /// True once we know (from the backend) that the user previously had
  /// access and it lapsed — as opposed to never having subscribed at all.
  /// Both render the same "read-only, needs upgrade" state in the business
  /// screens, but the messaging differs (see [BusinessManagementProvider]).
  bool get hadPriorAccess => !hasActiveSubscription && !isNone;

  factory EntitlementStatus.fromJson(Map<String, dynamic> json) {
    final subscription = json['subscription'];
    DateTime? expiryDate;
    if (subscription is Map && subscription['expiry_date'] != null) {
      expiryDate = DateTime.tryParse(subscription['expiry_date'].toString());
    }
    return EntitlementStatus(
      hasActiveSubscription: json['has_active_subscription'] == true,
      status: (json['status'] ?? 'none').toString(),
      expiryDate: expiryDate,
    );
  }
}
