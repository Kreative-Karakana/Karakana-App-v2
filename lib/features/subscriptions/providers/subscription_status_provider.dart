import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/entitlement_status.dart';
import '../models/subscription_plan.dart';
import '../services/subscription_service.dart';

/// Drives the subscription status screen (issue #33): fetches the
/// backend's entitlement state and plan catalog for display, and starts a
/// trial when the user opts in. Mirrors [BusinessManagementProvider]'s
/// entitlement-loading pattern — this never decides access itself, it only
/// reports what `subscriptions/me/` already decided (see
/// docs/apps/subscriptions.md, Security).
class SubscriptionStatusProvider extends ChangeNotifier {
  final SubscriptionApi _service;

  SubscriptionStatusProvider({SubscriptionApi? service})
      : _service = service ?? SubscriptionService();

  EntitlementStatus? _entitlement;
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = false;
  bool _isLoadingPlans = false;
  bool _isActivatingTrial = false;
  String? _errorMessage;
  String? _plansErrorMessage;
  String? _trialErrorMessage;

  EntitlementStatus? get entitlement => _entitlement;
  List<SubscriptionPlan> get plans => List.unmodifiable(_plans);
  bool get isLoading => _isLoading;
  bool get isLoadingPlans => _isLoadingPlans;
  bool get isActivatingTrial => _isActivatingTrial;
  String? get errorMessage => _errorMessage;
  String? get plansErrorMessage => _plansErrorMessage;
  String? get trialErrorMessage => _trialErrorMessage;

  /// Fetches entitlement and the plan catalog concurrently. A plans
  /// failure never blocks or clears the entitlement the user opened this
  /// screen to see — it only leaves the upgrade section empty with its own
  /// [plansErrorMessage]/retry, tracked independently of [errorMessage].
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.wait([_loadEntitlement(), loadPlans()]);

    _isLoading = false;
    notifyListeners();
  }

  Future<EntitlementStatus?> _loadEntitlement() async {
    try {
      final entitlement = await _service.getEntitlementStatus();
      _entitlement = entitlement;
      return entitlement;
    } catch (e) {
      _errorMessage = ApiClient().parseError(e);
      if (kDebugMode) {
        debugPrint('[SubscriptionStatusProvider] load: $e');
      }
      return null;
    }
  }

  /// Re-fetches only the backend-owned entitlement. Unlike [load], this does
  /// not reload the plan catalog and returns the fresh response so callers can
  /// make a backend-confirmed post-activation navigation decision.
  Future<EntitlementStatus?> refreshEntitlement() async {
    _errorMessage = null;
    final entitlement = await _loadEntitlement();
    notifyListeners();
    return entitlement;
  }

  Future<void> loadPlans() async {
    _isLoadingPlans = true;
    _plansErrorMessage = null;
    notifyListeners();

    try {
      _plans = await _service.getPlans();
    } catch (e) {
      _plansErrorMessage = ApiClient().parseError(e);
      if (kDebugMode) {
        debugPrint('[SubscriptionStatusProvider] loadPlans: $e');
      }
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }

  /// Starts the user's one-time free trial. Returns `true` only when a
  /// brand-new trial actually began (`trial_started`) — never inferred
  /// client-side, always the backend's own flag (see
  /// docs/apps/subscriptions.md, Trial activation). Either way,
  /// [entitlement] is refreshed from the response so the screen reflects
  /// whatever the backend now reports, including the harmless case of a
  /// double-tap replaying an already-started trial.
  Future<bool> activateTrial() async {
    _isActivatingTrial = true;
    _trialErrorMessage = null;
    notifyListeners();

    try {
      final result = await _service.activateTrial();
      _entitlement = result.entitlement;
      return result.trialStarted;
    } catch (e) {
      _trialErrorMessage = ApiClient().parseError(e);
      if (kDebugMode) {
        debugPrint('[SubscriptionStatusProvider] activateTrial: $e');
      }
      return false;
    } finally {
      _isActivatingTrial = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearTrialError() {
    _trialErrorMessage = null;
    notifyListeners();
  }
}
