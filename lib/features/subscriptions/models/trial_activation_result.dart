import 'entitlement_status.dart';

/// Response shape of `POST /api/v1/subscriptions/trial/activate/` — same
/// entitlement payload as `EntitlementStatus`, plus [trialStarted] so the
/// caller can tell "just started" from "already used" (see
/// docs/apps/subscriptions.md, `TrialActivateView`) without comparing
/// timestamps itself.
class TrialActivationResult {
  final bool trialStarted;
  final EntitlementStatus entitlement;

  const TrialActivationResult({
    required this.trialStarted,
    required this.entitlement,
  });

  factory TrialActivationResult.fromJson(Map<String, dynamic> json) {
    return TrialActivationResult(
      trialStarted: json['trial_started'] == true,
      entitlement: EntitlementStatus.fromJson(json),
    );
  }
}
