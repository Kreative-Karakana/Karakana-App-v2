import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/secure_storage.dart';

/// Handles all authentication-related API calls for Karakana.
///
/// Uses [ApiClient] for HTTP requests, [SecureStorage] for persisting
/// the auth token, and [ApiEndpoints] for endpoint paths.
class AuthService {
  AuthService._internal();

  static final AuthService _instance = AuthService._internal();

  /// The single shared instance of [AuthService].
  static AuthService get instance => _instance;

  final ApiClient _api = ApiClient.instance;
  final SecureStorage _storage = SecureStorage.instance;

  // ─────────────────────────────────────────────
  // Login
  // ─────────────────────────────────────────────

  /// Authenticates the user with [email] and [password].
  ///
  /// On success, the returned token is saved to secure storage and the
  /// user data map is returned.
  ///
  /// Throws a descriptive [String] message on failure.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;

      if (token != null && token.isNotEmpty) {
        await _storage.saveToken(token);
      }

      return data;
    } catch (e) {
      // ApiClient already converts DioException to a friendly string;
      // re-throw as-is so callers receive a consistent message type.
      throw e.toString();
    }
  }

  // ─────────────────────────────────────────────
  // Sign-up
  // ─────────────────────────────────────────────

  /// Registers a new user account with the supplied details.
  ///
  /// On success, the returned token is saved to secure storage and the
  /// user data map is returned.
  ///
  /// Throws a descriptive [String] message on failure.
  Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.signup,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;

      if (token != null && token.isNotEmpty) {
        await _storage.saveToken(token);
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  // ─────────────────────────────────────────────
  // Forgot password
  // ─────────────────────────────────────────────

  /// Sends a password-reset email to [email].
  ///
  /// Returns a success message string on success.
  /// Throws a descriptive [String] message on failure.
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _api.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      final data = response.data;

      // Return the server's detail message when available, otherwise a default.
      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        return data['detail'].toString();
      }

      return 'Password reset email sent. Please check your inbox.';
    } catch (e) {
      throw e.toString();
    }
  }

  // ─────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────

  /// Logs the user out by notifying the API and clearing all local storage.
  ///
  /// Local storage is always cleared, even if the API call fails, so the
  /// user is never left in a broken half-authenticated state.
  /// This method never throws.
  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {
      // Intentionally swallowed — local cleanup always runs below.
    } finally {
      await _storage.clearAll();
    }
  }

  // ─────────────────────────────────────────────
  // Get current user
  // ─────────────────────────────────────────────

  /// Fetches the authenticated user's profile from the API.
  ///
  /// Returns a [Map<String, dynamic>] of the user profile on success.
  /// Throws a descriptive [String] message on failure.
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _api.get(ApiEndpoints.profileMe);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw e.toString();
    }
  }
}
