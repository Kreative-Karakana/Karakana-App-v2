import '../../../core/network/api_client.dart';
import '../models/entitlement_status.dart';

abstract class SubscriptionApi {
  Future<EntitlementStatus> getEntitlementStatus();
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
}
