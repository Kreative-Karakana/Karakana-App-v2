import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

/// Network calls used by `AuthProvider`, extracted behind an interface so
/// tests can supply a fake instead of hitting the real backend.
abstract class AuthApi {
  Future<dynamic> login({
    required String email,
    required String password,
    required String platform,
    String? deviceToken,
  });

  Future<void> signup({
    required String firstName,
    required String email,
    required String password,
  });

  Future<dynamic> verifyEmail({
    required String email,
    required String code,
    required String platform,
    String? deviceToken,
  });

  Future<void> forgotPassword({required String email});

  Future<void> resendOTP({required String email});

  Future<dynamic> fetchProfile();

  Future<void> deleteAccount();

  Future<dynamic> exchangeGoogleToken({
    String? idToken,
    String? accessToken,
    required String platform,
    String? deviceToken,
  });

  Future<dynamic> exchangeAppleToken({
    required String idToken,
    String? firstName,
    String? lastName,
  });
}

class AuthService implements AuthApi {
  @override
  Future<dynamic> login({
    required String email,
    required String password,
    required String platform,
    String? deviceToken,
  }) async {
    final response = await ApiClient().dio.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
        'platform': platform,
        if (deviceToken != null) 'device_token': deviceToken,
      },
    );
    return response.data;
  }

  @override
  Future<void> signup({
    required String firstName,
    required String email,
    required String password,
  }) async {
    await ApiClient().dio.post(
      ApiEndpoints.signup,
      data: {
        'first_name': firstName,
        'email': email,
        'password': password,
      },
    );
  }

  @override
  Future<dynamic> verifyEmail({
    required String email,
    required String code,
    required String platform,
    String? deviceToken,
  }) async {
    final response = await ApiClient().dio.post(
      ApiEndpoints.verifyEmail,
      data: {
        'email': email,
        'code': code,
        'platform': platform,
        if (deviceToken != null) 'device_token': deviceToken,
      },
    );
    return response.data;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await ApiClient().dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  @override
  Future<void> resendOTP({required String email}) async {
    await ApiClient().dio.post(
      ApiEndpoints.resendOTP,
      data: {'email': email},
    );
  }

  @override
  Future<dynamic> fetchProfile() async {
    final response = await ApiClient().dio.get(ApiEndpoints.profileMe);
    return response.data;
  }

  @override
  Future<void> deleteAccount() async {
    await ApiClient().dio.delete('/api/v1/auth/user/delete/');
  }

  @override
  Future<dynamic> exchangeGoogleToken({
    String? idToken,
    String? accessToken,
    required String platform,
    String? deviceToken,
  }) async {
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
    return response.data;
  }

  @override
  Future<dynamic> exchangeAppleToken({
    required String idToken,
    String? firstName,
    String? lastName,
  }) async {
    final response = await ApiClient().dio.post(
      ApiEndpoints.appleAuth,
      data: {
        'id_token': idToken,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
      },
    );
    return response.data;
  }
}
