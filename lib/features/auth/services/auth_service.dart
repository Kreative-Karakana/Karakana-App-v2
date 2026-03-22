import 'package:dio/dio.dart';

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

      // Return only the nested user map so callers work with a clean profile.
      return data['user'] as Map<String, dynamic>;
    } catch (e) {
      // ApiClient already converts DioException to a friendly string;
      // re-throw as-is so callers receive a consistent message type.
      throw e.toString();
    }
  }

  // ─────────────────────────────────────────────
  // Sign-up
  // ─────────────────────────────────────────────

  /// Registers a new user account with [firstName], [email], and [password].
  ///
  /// The backend sends an OTP to [email] for verification — no token is
  /// issued at this stage. Returns [email] on success so the caller can
  /// route the user to the verification screen.
  ///
  /// Throws a descriptive [String] message on failure.
  Future<String> signup({
    required String firstName,
    required String email,
    required String password,
  }) async {
    try {
      // Use the underlying Dio instance directly so we can pass Options.
      // The registered interceptors (auth token, logging) still apply.
      final response = await _api.dio.post(
        ApiEndpoints.signup,
        data: {
          'first_name': firstName,
          'email': email,
          'password': password,
        },
        options: Options(
          // This backend returns 306 to indicate that the account was created
          // and a verification email was sent. Without this, Dio would treat
          // any status > 299 as an error and throw before we can inspect it.
          validateStatus: (status) => status != null && status <= 306,
        ),
      );

      final statusCode = response.statusCode ?? 0;

      if (statusCode == 200 || statusCode == 306) {
        // Both codes mean success — the OTP has been dispatched to [email].
        return email;
      }

      // Any other status is a real failure — surface the server message.
      final body = response.data;
      if (body is Map<String, dynamic> && body.containsKey('detail')) {
        throw body['detail'].toString();
      }
      throw 'Sign-up failed (status $statusCode). Please try again.';
    } catch (e) {
      throw e.toString();
    }
  }

  // ─────────────────────────────────────────────
  // Email verification
  // ─────────────────────────────────────────────

  /// Verifies the user's email address using the OTP [code] sent to [email].
  ///
  /// On success, the returned token is saved to secure storage and the
  /// user data map is returned.
  ///
  /// Throws a descriptive [String] message on failure.
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final response = await _api.post(
        ApiEndpoints.verifyEmail,
        data: {'email': email, 'code': code},
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;

      if (token != null && token.isNotEmpty) {
        await _storage.saveToken(token);
      }

      return data['user'] as Map<String, dynamic>;
    } catch (e) {
      throw e.toString();
    }
  }

  // ─────────────────────────────────────────────
  // Resend OTP
  // ─────────────────────────────────────────────

  /// Requests a new OTP to be sent to [email].
  ///
  /// Returns a success message string on success.
  /// Throws a descriptive [String] message on failure.
  Future<String> resendOTP(String email) async {
    try {
      final response = await _api.post(
        ApiEndpoints.resendVerification,
        data: {'email': email},
      );

      final data = response.data;

      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        return data['detail'].toString();
      }

      return 'Verification code resent. Please check your inbox.';
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
      await _api.post('/api/v1/accounts/logout/');
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
