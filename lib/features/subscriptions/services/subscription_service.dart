import '../../../core/network/api_client.dart';
import '../models/entitlement_status.dart';
import '../models/subscription_plan.dart';
import '../models/trial_activation_result.dart';

abstract class SubscriptionApi {
  Future<EntitlementStatus> getEntitlementStatus();
  Future<List<SubscriptionPlan>> getPlans();
  Future<TrialActivationResult> activateTrial();
}

/// Read-only client for the entitlement status the backend already
/// computes (subscriptions/me/) — see docs/apps/subscriptions.md. Nothing
/// here decides access; it only reports what the backend already decided,
/// so screens can render the right state. The actual enforcement always
/// happens server-side on the write call itself (issue #31).
class SubscriptionService implements SubscriptionApi {
  final _dio = ApiClient().dio;

  @override
  Future<EntitlementStatus> getEntitlementStatus() async {
    final response = await _dio.get('/api/v1/subscriptions/me/');
    return EntitlementStatus.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    final response = await _dio.get('/api/v1/subscriptions/plans/');
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((p) => SubscriptionPlan.fromJson(p.cast<String, dynamic>()))
        .toList();
  }

  /// Starts the caller's one-time free trial, or no-ops if already used —
  /// see `TrialActivateView` in docs/apps/subscriptions.md. Safe to call
  /// more than once (retry, double-tap): `trial_started` on the response
  /// is the only signal to act on, never anything inferred client-side.
  @override
  Future<TrialActivationResult> activateTrial() async {
    final response = await _dio.post('/api/v1/subscriptions/trial/activate/');
    return TrialActivationResult.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }
}
