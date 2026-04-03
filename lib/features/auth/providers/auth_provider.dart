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
    final first = _user!['first_name'] ?? '';
    final last = _user!['last_name'] ?? '';
    return '$first $last'.trim();
  }

  String get userEmail => _user?['email'] ?? '';
  String? get userAvatar => _user?['avatar'];
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
      _errorMessage = ApiClient().parseError(e);
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
        data: {'email': email, 'otp': code},
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> getCurrentUser() async {
    try {
      final response = await ApiClient().dio.get(ApiEndpoints.profileMe);
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
