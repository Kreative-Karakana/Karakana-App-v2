import 'dart:io';
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/secure_storage.dart';
import '../services/auth_service.dart';
import '../services/auth_session_store.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthApi? api, AuthSessionStore? storage})
      : _api = api ?? AuthService(),
        _storage = storage ?? SecureStorage() {
    ApiClient().setUnauthorizedHandler(invalidateAuthentication);
  }

  final AuthApi _api;
  final AuthSessionStore _storage;

  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  List<dynamic>? _roles;
  String? _errorMessage;
  bool _isOnboardingComplete = false;
  Future<void>? _authenticationInvalidationInFlight;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isOnboardingComplete => _isOnboardingComplete;

  String get userFullName {
    if (_user == null) return '';
    final firstName =
        _user!['first_name'] as String? ?? _user!['firstName'] as String? ?? '';
    final lastName =
        _user!['last_name'] as String? ?? _user!['lastName'] as String? ?? '';
    return '$firstName $lastName'.trim();
  }

  String get userEmail {
    if (_user == null) return '';
    return _user!['email'] as String? ?? '';
  }

  String? get userAvatar {
    if (_user == null) return null;
    return _user!['avatar'] as String? ??
        _user!['profile_picture'] as String? ??
        _user!['photo'] as String? ??
        _user!['image'] as String?;
  }

  int? get userId => _user?['id'];

  bool get isTrainer {
    // _roles is populated from the signin response; profile/me doesn't return roles
    final rolesList = _roles ?? _user?['roles'];
    if (rolesList is List) return rolesList.contains('trainers');
    return false;
  }

  bool get passwordChangeRequired {
    final value = _user?['password_change_required'];
    return isTrainer && value == true;
  }

  List<dynamic>? _extractRoles(dynamic data) {
    if (data is! Map) return null;
    final direct = data['roles'];
    if (direct is List) return direct;
    final nested = data['user'];
    if (nested is Map) {
      final nestedRoles = nested['roles'];
      if (nestedRoles is List) return nestedRoles;
    }
    return null;
  }

  String get homeRoute {
    if (passwordChangeRequired) return '/profile/change-password';
    return isTrainer ? '/trainer/dashboard' : '/home';
  }

  Future<void> _syncBiometricSessionForCurrentUser() async {
    final accountId = userId?.toString();
    if (accountId == null || accountId.isEmpty) return;
    if (await _storage.isBiometricEnabledForAccount(accountId)) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        await _storage.saveBiometricTokenForAccount(accountId, token);
        await _storage.setActiveBiometricAccountId(accountId);
      }
    }
  }

  Future<void> initialize() async {
    _isOnboardingComplete = await _storage.isOnboardingComplete();
    final hasToken = await _storage.hasToken();
    if (hasToken) {
      _roles = await _storage.loadRoles();
      // Trust local session immediately for fast startup; refresh profile in background.
      _isAuthenticated = true;
      unawaited(getCurrentUser());
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _storage.deleteToken();
      String? deviceToken;
      try {
        deviceToken = await FirebaseMessaging.instance.getToken().timeout(
              const Duration(seconds: 5),
            );
      } catch (e) {
        debugPrint('[AUTH] FCM token fetch failed (non-fatal): $e');
        deviceToken = null;
      }
      final platform = Platform.isIOS ? 'ios' : 'android';
      final data = await _api.login(
        email: email,
        password: password,
        platform: platform,
        deviceToken: deviceToken,
      );
      final token = data['token'] ?? data['key'];
      if (token != null) {
        await _storage.saveToken(token.toString());
        _roles = _extractRoles(data);
        debugPrint('[AUTH] Signin roles: $_roles');
        if (_roles != null) await _storage.saveRoles(_roles!);
        _user = _extractUser(data);
        final profileLoaded = await getCurrentUser();
        if (!profileLoaded) {
          await invalidateAuthentication();
          _isLoading = false;
          notifyListeners();
          return false;
        }
        await _syncBiometricSessionForCurrentUser();
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Imeshindikana kuingia. Tafadhali jaribu tena.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      final parsed = ApiClient().parseError(e);
      _errorMessage = parsed.toLowerCase().contains('token')
          ? 'Barua pepe au nenosiri si sahihi.'
          : parsed;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Returns the email string on success (HTTP 306 = success), null on failure.
  Future<String?> signup(
    String firstName,
    String email,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.signup(firstName: firstName, email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return email;
    } catch (e) {
      // HTTP 306 is treated as success
      if (e is Exception && e.toString().contains('306')) {
        _isLoading = false;
        notifyListeners();
        return email;
      }
      _errorMessage = ApiClient().parseError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? deviceToken;
      try {
        deviceToken = await FirebaseMessaging.instance.getToken().timeout(
              const Duration(seconds: 5),
            );
      } catch (e) {
        debugPrint(
          '[AUTH] FCM token fetch failed during verify (non-fatal): $e',
        );
        deviceToken = null;
      }
      final platform = Platform.isIOS ? 'ios' : 'android';
      final data = await _api.verifyEmail(
        email: email,
        code: code,
        platform: platform,
        deviceToken: deviceToken,
      );
      final token = data['token'] ?? data['key'];
      if (token != null) {
        await _storage.saveToken(token.toString());
        _roles = _extractRoles(data);
        if (_roles != null) await _storage.saveRoles(_roles!);
        final profileLoaded = await getCurrentUser();
        if (!profileLoaded) {
          await invalidateAuthentication();
          _isLoading = false;
          notifyListeners();
          return false;
        }
        await _syncBiometricSessionForCurrentUser();
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Imeshindikana kuthibitisha. Tafadhali jaribu tena.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = ApiClient().parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.forgotPassword(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ApiClient().parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] remote logout failed: $e');
    } finally {
      await invalidateAuthentication();
    }
  }

  Future<void> invalidateAuthentication() {
    final inFlight = _authenticationInvalidationInFlight;
    if (inFlight != null) return inFlight;

    final future = _performAuthenticationInvalidation();
    _authenticationInvalidationInFlight = future;
    return future.whenComplete(() {
      if (identical(_authenticationInvalidationInFlight, future)) {
        _authenticationInvalidationInFlight = null;
      }
    });
  }

  Future<void> _performAuthenticationInvalidation() async {
    try {
      await _storage.clearAll();
    } finally {
      _isAuthenticated = false;
      _user = null;
      _roles = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    await _api.deleteAccount();
    await invalidateAuthentication();
  }

  Future<void> completeOnboarding() async {
    await _storage.setOnboardingComplete();
    _isOnboardingComplete = true;
    notifyListeners();
  }

  Future<bool> resendOTP(String email) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.resendOTP(email: email);
      return true;
    } catch (e) {
      _errorMessage = ApiClient().parseError(e);
      if (kDebugMode) debugPrint('[AuthProvider] resendOTP error: $e');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const iosClientId =
          '466490006316-a26dq3aarir4jl9971u7j440hsegllv8.apps.googleusercontent.com';
      const webServerClientId =
          '466490006316-0rl5eeqm70rsmg90eq2gc7n3725u4jjn.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        clientId: (!kIsWeb && Platform.isIOS) ? iosClientId : null,
        serverClientId: webServerClientId,
        scopes: ['email', 'profile'],
      );
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        throw Exception('No Google token returned');
      }
      String? deviceToken;
      try {
        deviceToken = await FirebaseMessaging.instance.getToken().timeout(
              const Duration(seconds: 5),
            );
      } catch (e) {
        debugPrint('[AUTH] FCM token fetch failed (non-fatal): $e');
        deviceToken = null;
      }
      final platform = Platform.isIOS ? 'ios' : 'android';

      final data = await _api.exchangeGoogleToken(
        idToken: idToken,
        accessToken: accessToken,
        platform: platform,
        deviceToken: deviceToken,
      );
      return await _handleOAuthResponse(data);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('[Google Sign-In] FAILED');
        debugPrint('[Error type]: ${e.runtimeType}');
        debugPrint('[Error]: $e');
        debugPrint('[Stack trace]: $stackTrace');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      // Surface the real error in debug mode so we can diagnose it
      String debugMessage = '';
      if (kDebugMode) {
        debugMessage = '\n\nDEBUG: ${e.runtimeType}: $e';
      }

      // Check for specific Google Sign-In error types
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network_error') ||
          errorStr.contains('network error')) {
        _errorMessage =
            'Hitilafu ya mtandao. Angalia muunganiko wako.$debugMessage';
      } else if (errorStr.contains('sign_in_cancelled') ||
          errorStr.contains('cancelled')) {
        _errorMessage = 'Umeghairi kuingia kwa Google.$debugMessage';
      } else if (errorStr.contains('sign_in_failed') ||
          errorStr.contains('failed')) {
        _errorMessage = 'Kuingia kwa Google kumeshindwa.$debugMessage';
      } else if (errorStr.contains('popup_closed') ||
          errorStr.contains('popup')) {
        _errorMessage = 'Dirisha la Google lilifungwa.$debugMessage';
      } else if (errorStr.contains('10:') ||
          errorStr.contains('error code: 10')) {
        _errorMessage =
            'Hitilafu ya usanidi wa Google (Code 10). SHA-1 haijasajiliwa.$debugMessage';
      } else {
        _errorMessage = 'Imeshindikana kuingia kwa Google.$debugMessage';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithApple() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) throw Exception('No identity token from Apple');

      final data = await _api.exchangeAppleToken(
        idToken: idToken,
        firstName: credential.givenName,
        lastName: credential.familyName,
      );
      return await _handleOAuthResponse(data);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _errorMessage = 'Tatizo la kuingia kwa Apple. Jaribu tena.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] loginWithApple error: $e');
      _errorMessage = 'Tatizo la kuingia kwa Apple. Jaribu tena.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _handleOAuthResponse(dynamic data) async {
    final token = data['token'] ?? data['key'];
    if (token != null) {
      await _storage.saveToken(token.toString());
      _roles = _extractRoles(data);
      if (_roles != null) await _storage.saveRoles(_roles!);
      _user = _extractUser(data);
      final profileLoaded = await getCurrentUser();
      if (!profileLoaded) {
        await invalidateAuthentication();
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await _syncBiometricSessionForCurrentUser();
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    }
    _errorMessage = 'Tatizo la kuingia. Jaribu tena.';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> getCurrentUser() async {
    try {
      final profileData = await _api.fetchProfile();
      debugPrint('[AUTH] Profile response: $profileData');
      final currentUser = _user;
      final profileUser = profileData is Map<String, dynamic>
          ? profileData
          : Map<String, dynamic>.from(profileData);
      _user = _mergeUserState(currentUser, profileUser);
      if (_user?['id'] != null) {
        await _storage.saveUserId(_user!['id'].toString());
      }
      _isAuthenticated = true;
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] getCurrentUser error: $e');
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithBiometricSession() async {
    try {
      final accountId = await _storage.getActiveBiometricAccountId();
      if (accountId == null || accountId.isEmpty) return false;
      final token = await _storage.getBiometricTokenForAccount(accountId);
      if (token == null || token.isEmpty) return false;
      await _storage.saveToken(token);
      final profileLoaded = await getCurrentUser();
      if (!profileLoaded) return false;
      final currentUserId = userId?.toString();
      if (currentUserId == null || currentUserId != accountId) {
        await invalidateAuthentication();
        return false;
      }
      notifyListeners();
      return _isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? _extractUser(dynamic data) {
    if (data is! Map) return null;
    final nested = data['user'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return Map<String, dynamic>.from(data);
  }

  Map<String, dynamic> _mergeUserState(
    Map<String, dynamic>? currentUser,
    Map<String, dynamic> profileUser,
  ) {
    final merged = <String, dynamic>{
      if (currentUser != null) ...currentUser,
      ...profileUser,
    };

    if (currentUser?['password_change_required'] == true) {
      merged['password_change_required'] = true;
    }
    if (_roles != null && !merged.containsKey('roles')) {
      merged['roles'] = _roles;
    }

    return merged;
  }
}
