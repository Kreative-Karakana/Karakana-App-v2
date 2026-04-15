import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
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
    final roles = _user?['roles'];
    if (roles is List) return roles.contains('trainer');
    return false;
  }

  Future<void> initialize() async {
    _isOnboardingComplete = await SecureStorage().isOnboardingComplete();
    final hasToken = await SecureStorage().hasToken();
    if (hasToken) {
      await getCurrentUser();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SecureStorage().deleteToken();
      final response = await ApiClient().dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final token = response.data['token'] ?? response.data['key'];
      if (token != null) {
        await SecureStorage().saveToken(token.toString());
        await getCurrentUser();
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Login failed. Please try again.';
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
      final response = await ApiClient().dio.post(
        ApiEndpoints.verifyEmail,
        data: {'email': email, 'code': code},
      );
      final token = response.data['token'] ?? response.data['key'];
      if (token != null) {
        await SecureStorage().saveToken(token.toString());
        await getCurrentUser();
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Verification failed. Please try again.';
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
}
