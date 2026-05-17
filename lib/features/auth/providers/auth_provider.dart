import 'dart:io';
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  List<dynamic>? _roles;
  String? _errorMessage;
  bool _isOnboardingComplete = false;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isOnboardingComplete => _isOnboardingComplete;

  String get userFullName {
    if (_user == null) return '';
    final firstName = _user!['first_name'] as String? ??
                      _user!['firstName'] as String? ?? '';
    final lastName = _user!['last_name'] as String? ??
                     _user!['lastName'] as String? ?? '';
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

  String get homeRoute => isTrainer ? '/trainer/dashboard' : '/home';

  Future<void> initialize() async {
    _isOnboardingComplete = await SecureStorage().isOnboardingComplete();
    final hasToken = await SecureStorage().hasToken();
    if (hasToken) {
      _roles = await SecureStorage().loadRoles();
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
      await SecureStorage().deleteToken();
      String? deviceToken;
      try {
        deviceToken = await FirebaseMessaging.instance.getToken()
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[AUTH] FCM token fetch failed (non-fatal): $e');
        deviceToken = null;
      }
      final platform = Platform.isIOS ? 'ios' : 'android';
      final response = await ApiClient().dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
          'platform': platform,
          if (deviceToken != null) 'device_token': deviceToken,
        },
      );
      final token = response.data['token'] ?? response.data['key'];
      if (token != null) {
        await SecureStorage().saveToken(token.toString());
        if (await SecureStorage().isBiometricEnabled()) {
          await SecureStorage().saveBiometricToken(token.toString());
        }
        _roles = _extractRoles(response.data);
        debugPrint('[AUTH] Signin roles: $_roles');
        if (_roles != null) await SecureStorage().saveRoles(_roles!);
        await getCurrentUser();
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
      debugPrint('[LOGIN] Raw error: $e');
      debugPrint('[LOGIN] Parsed error: $parsed');
      debugPrint('[LOGIN] Error type: ${e.runtimeType}');
      if (e is DioException) {
        debugPrint('[LOGIN] DioException type: ${e.type}');
        debugPrint('[LOGIN] DioException response: ${e.response?.data}');
        debugPrint('[LOGIN] DioException status: ${e.response?.statusCode}');
        _errorMessage = 'DEBUG: ${e.type} - ${e.response?.statusCode} - $parsed';
      } else {
        _errorMessage = parsed.toLowerCase().contains('token')
            ? 'Barua pepe au nenosiri si sahihi.'
            : 'DEBUG: ${e.runtimeType} - $parsed';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Returns the email string on success (HTTP 306 = success), null on failure.
  Future<String?> signup(
      String firstName, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient().dio.post(
        ApiEndpoints.signup,
        data: {
          'first_name': firstName,
          'email': email,
          'password': password,
        },
      );
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
      final deviceToken = await FirebaseMessaging.instance.getToken();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final response = await ApiClient().dio.post(
        ApiEndpoints.verifyEmail,
        data: {
          'email': email,
          'code': code,
          'platform': platform,
          if (deviceToken != null) 'device_token': deviceToken,
        },
      );
      final token = response.data['token'] ?? response.data['key'];
      if (token != null) {
        await SecureStorage().saveToken(token.toString());
        if (await SecureStorage().isBiometricEnabled()) {
          await SecureStorage().saveBiometricToken(token.toString());
        }
        _roles = _extractRoles(response.data);
        if (_roles != null) await SecureStorage().saveRoles(_roles!);
        await getCurrentUser();
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
      await ApiClient().dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
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
    await SecureStorage().clearAll();
    _isAuthenticated = false;
    _user = null;
    _roles = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await SecureStorage().setOnboardingComplete();
    _isOnboardingComplete = true;
    notifyListeners();
  }

  Future<bool> resendOTP(String email) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient().dio.post(
        ApiEndpoints.resendOTP,
        data: {'email': email},
      );
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
        deviceToken = await FirebaseMessaging.instance.getToken()
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[AUTH] FCM token fetch failed (non-fatal): $e');
        deviceToken = null;
      }
      final platform = Platform.isIOS ? 'ios' : 'android';

      final response = await ApiClient().dio.post(
        ApiEndpoints.googleAuth,
        data: {
          if (idToken != null && idToken.isNotEmpty) 'id_token': idToken,
          if (accessToken != null && accessToken.isNotEmpty)
            'access_token': accessToken,
          'platform': platform,
          if (deviceToken != null) 'device_token': deviceToken,
        },
      );
      return await _handleOAuthResponse(response.data);
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
        _errorMessage = 'Hitilafu ya mtandao. Angalia muunganiko wako.$debugMessage';
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
        _errorMessage = 'Hitilafu ya usanidi wa Google (Code 10). SHA-1 haijasajiliwa.$debugMessage';
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

      final response = await ApiClient().dio.post(
        ApiEndpoints.appleAuth,
        data: {
          'id_token': idToken,
          if (credential.givenName != null) 'first_name': credential.givenName,
          if (credential.familyName != null) 'last_name': credential.familyName,
        },
      );
      return await _handleOAuthResponse(response.data);
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
      await SecureStorage().saveToken(token.toString());
      if (await SecureStorage().isBiometricEnabled()) {
        await SecureStorage().saveBiometricToken(token.toString());
      }
      _roles = _extractRoles(data);
      if (_roles != null) await SecureStorage().saveRoles(_roles!);
      await getCurrentUser();
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

  Future<void> getCurrentUser() async {
    try {
      final response = await ApiClient().dio.get(ApiEndpoints.profileMe);
      debugPrint('[AUTH] Profile response: ${response.data}');
      _user = response.data is Map<String, dynamic>
          ? response.data
          : Map<String, dynamic>.from(response.data);
      if (_user?['id'] != null) {
        await SecureStorage().saveUserId(_user!['id'].toString());
      }
      _isAuthenticated = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] getCurrentUser error: $e');
      _isAuthenticated = false;
    }
  }

  Future<bool> loginWithBiometricSession() async {
    try {
      final token = await SecureStorage().getBiometricToken();
      if (token == null || token.isEmpty) return false;
      await SecureStorage().saveToken(token);
      await getCurrentUser();
      notifyListeners();
      return _isAuthenticated;
    } catch (_) {
      return false;
    }
  }
}

