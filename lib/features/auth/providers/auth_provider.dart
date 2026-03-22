import 'package:flutter/material.dart';

import '../../../core/utils/secure_storage.dart';
import '../services/auth_service.dart';

/// Manages authentication state for the entire Karakana app.
///
/// Consumed by any widget that needs to know whether a user is logged in,
/// who they are, or whether an auth operation is in progress.
/// Register this at the root of the widget tree via [ChangeNotifierProvider].
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final SecureStorage _storage = SecureStorage.instance;

  // ─────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────

  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _errorMessage;
  bool _isOnboardingComplete = false;

  /// The email address awaiting OTP verification after a successful sign-up.
  String? _pendingVerificationEmail;

  // ─────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────

  /// Whether an auth operation (login, signup, etc.) is currently running.
  bool get isLoading => _isLoading;

  /// Whether the user has a valid session.
  bool get isAuthenticated => _isAuthenticated;

  /// The current user's profile data, or `null` if not logged in.
  Map<String, dynamic>? get user => _user;

  /// The latest error message to display, or `null` when there is none.
  String? get errorMessage => _errorMessage;

  /// Whether the user has already completed the onboarding flow.
  bool get isOnboardingComplete => _isOnboardingComplete;

  /// The user's full name derived from [user], or an empty string.
  String get userFullName {
    if (_user == null) return '';
    final first = _user!['first_name']?.toString() ?? '';
    final last = _user!['last_name']?.toString() ?? '';
    return '$first $last'.trim();
  }

  /// The user's email address derived from [user], or an empty string.
  String get userEmail => _user?['email']?.toString() ?? '';

  /// The user's avatar URL derived from [user], or `null` if not set.
  String? get userAvatar => _user?['avatar']?.toString();

  /// The email address waiting for OTP verification, set after a successful
  /// sign-up and cleared once verification completes.
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  // ─────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────

  /// Called once on app start to restore previous session state.
  ///
  /// Checks secure storage for an existing token and onboarding flag.
  /// If a token is found, marks the user as authenticated and fetches
  /// their current profile in the background.
  Future<void> initialize() async {
    final hasToken = await _storage.hasToken();
    _isOnboardingComplete = await _storage.isOnboardingComplete();

    if (hasToken) {
      _isAuthenticated = true;
      notifyListeners();
      // Fetch fresh profile data without blocking the splash screen.
      await _getCurrentUser();
    } else {
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Login
  // ─────────────────────────────────────────────

  /// Logs the user in with [email] and [password].
  ///
  /// Returns `true` on success and `false` on failure.
  /// On failure, [errorMessage] is updated with a descriptive message.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final userData = await _authService.login(email, password);
      _user = userData;
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────
  // Sign-up
  // ─────────────────────────────────────────────

  /// Registers a new account with [firstName], [email], and [password].
  ///
  /// Returns the [email] string on success so the caller can navigate to the
  /// email-verification screen. Returns `null` on failure and updates
  /// [errorMessage] with a descriptive message.
  Future<String?> signup(
    String firstName,
    String email,
    String password,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final confirmedEmail = await _authService.signup(
        firstName: firstName,
        email: email,
        password: password,
      );
      _pendingVerificationEmail = confirmedEmail;
      return confirmedEmail;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────
  // Email verification
  // ─────────────────────────────────────────────

  /// Verifies the user's email with the OTP [code] sent to [email].
  ///
  /// On success, marks the user as authenticated and clears
  /// [pendingVerificationEmail]. Returns `true` on success, `false` on
  /// failure (with [errorMessage] updated).
  Future<bool> verifyEmail(String email, String code) async {
    _setLoading(true);
    _clearError();

    try {
      final userData = await _authService.verifyEmail(email, code);
      _user = userData;
      _isAuthenticated = true;
      _pendingVerificationEmail = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────
  // Resend OTP
  // ─────────────────────────────────────────────

  /// Requests a new OTP to be sent to [email].
  ///
  /// Returns `true` on success and `false` on failure.
  /// On failure, [errorMessage] is updated with a descriptive message.
  Future<bool> resendOTP(String email) async {
    _clearError();

    try {
      await _authService.resendOTP(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Forgot password
  // ─────────────────────────────────────────────

  /// Sends a password-reset email to [email].
  ///
  /// Returns `true` on success and `false` on failure.
  /// On failure, [errorMessage] is updated with a descriptive message.
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.forgotPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────

  /// Logs the current user out and clears all local state.
  ///
  /// Always succeeds — [AuthService.logout] is infallible and guarantees
  /// that secure storage is wiped even when the server is unreachable.
  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Onboarding
  // ─────────────────────────────────────────────

  /// Persists the onboarding-complete flag and updates local state.
  ///
  /// Call this at the end of the onboarding flow so the user is never
  /// shown it again.
  Future<void> completeOnboarding() async {
    await _storage.setOnboardingComplete();
    _isOnboardingComplete = true;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Error handling
  // ─────────────────────────────────────────────

  /// Clears the current error message.
  ///
  /// Call this when dismissing an error banner or navigating away from
  /// a screen that displayed an error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────

  /// Fetches the authenticated user's profile from the API and updates state.
  ///
  /// Errors are silently swallowed — the app can still function with cached
  /// user data or without a profile (e.g. during a poor connection).
  Future<void> _getCurrentUser() async {
    try {
      final userData = await _authService.getCurrentUser();
      _user = userData;
      notifyListeners();
    } catch (_) {
      // Non-fatal: authentication is already confirmed via the stored token.
    }
  }

  /// Sets [_isLoading] and notifies listeners.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Clears [_errorMessage] without notifying listeners.
  ///
  /// Used internally before starting an operation so stale errors are
  /// removed before the new result (success or failure) is applied.
  void _clearError() {
    _errorMessage = null;
  }
}
