import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/auth/providers/auth_provider.dart';
import 'package:karakana_app/features/auth/services/auth_service.dart';
import 'package:karakana_app/features/auth/services/auth_session_store.dart';

void main() {
  group('AuthProvider.login', () {
    test('successful login stores the token, roles, and profile', () async {
      final api = _FakeAuthApi(
        loginResponse: {
          'token': 'abc123',
          'roles': ['trainers'],
        },
        profileResponse: {
          'id': 7,
          'first_name': 'Asha',
          'last_name': 'Mrema',
          'email': 'asha@example.test',
        },
      );
      final storage = _FakeAuthSessionStore();
      final provider = AuthProvider(api: api, storage: storage);

      final ok = await provider.login('asha@example.test', 'sirisiri');

      expect(ok, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(storage.token, 'abc123');
      expect(storage.roles, ['trainers']);
      expect(provider.isTrainer, isTrue);
      expect(provider.homeRoute, '/trainer/dashboard');
      expect(provider.userFullName, 'Asha Mrema');
      expect(provider.userEmail, 'asha@example.test');
      expect(storage.userId, '7');
      expect(api.lastLoginEmail, 'asha@example.test');
      expect(api.lastLoginPassword, 'sirisiri');
    });

    test('deletes any stale token before attempting sign-in', () async {
      final storage = _FakeAuthSessionStore()..token = 'stale-token';
      final api = _FakeAuthApi(
        loginResponse: {'token': 'new-token'},
        storageToObserve: storage,
      );
      final provider = AuthProvider(api: api, storage: storage);

      await provider.login('user@example.test', 'password');

      expect(api.tokenAtLoginTime, isNull);
    });

    test('missing token in the response surfaces a Swahili error', () async {
      final api = _FakeAuthApi(loginResponse: <String, dynamic>{});
      final storage = _FakeAuthSessionStore();
      final provider = AuthProvider(api: api, storage: storage);

      final ok = await provider.login('user@example.test', 'password');

      expect(ok, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage,
          'Imeshindikana kuingia. Tafadhali jaribu tena.');
      expect(storage.token, isNull);
    });

    test('a thrown error surfaces a parsed message and clears loading state',
        () async {
      final api = _FakeAuthApi(loginError: Exception('network down'));
      final storage = _FakeAuthSessionStore();
      final provider = AuthProvider(api: api, storage: storage);

      final ok = await provider.login('user@example.test', 'password');

      expect(ok, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(storage.token, isNull);
    });
  });

  group('AuthProvider.initialize', () {
    test('restores onboarding state without a stored session', () async {
      final api = _FakeAuthApi();
      final storage = _FakeAuthSessionStore()..onboardingComplete = true;
      final provider = AuthProvider(api: api, storage: storage);

      await provider.initialize();

      expect(provider.isOnboardingComplete, isTrue);
      expect(provider.isAuthenticated, isFalse);
      expect(api.fetchProfileCallCount, 0);
    });

    test(
        'trusts a stored token immediately and refreshes profile in the '
        'background', () async {
      final api = _FakeAuthApi(
        profileResponse: {'id': 3, 'first_name': 'Juma'},
      );
      final storage = _FakeAuthSessionStore()
        ..token = 'stored-token'
        ..roles = ['trainers'];
      final provider = AuthProvider(api: api, storage: storage);

      await provider.initialize();

      expect(provider.isAuthenticated, isTrue);
      expect(provider.isTrainer, isTrue);
    });
  });

  group('AuthProvider.logout', () {
    test('clears local session state', () async {
      final api = _FakeAuthApi(
        loginResponse: {
          'token': 'abc123',
          'roles': ['trainers'],
        },
        profileResponse: {'id': 1, 'first_name': 'Asha'},
      );
      final storage = _FakeAuthSessionStore();
      final provider = AuthProvider(api: api, storage: storage);
      await provider.login('asha@example.test', 'sirisiri');

      await provider.logout();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.user, isNull);
      expect(storage.cleared, isTrue);
    });
  });

  group('AuthProvider.loginWithBiometricSession', () {
    test('restores the session when the profile matches the saved account',
        () async {
      final api =
          _FakeAuthApi(profileResponse: {'id': 42, 'first_name': 'Zena'});
      final storage = _FakeAuthSessionStore()
        ..activeBiometricAccountId = '42'
        ..biometricTokens['42'] = 'biometric-token';
      final provider = AuthProvider(api: api, storage: storage);

      final ok = await provider.loginWithBiometricSession();

      expect(ok, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(storage.token, 'biometric-token');
    });

    test('fails when the restored profile does not match the saved account',
        () async {
      final api =
          _FakeAuthApi(profileResponse: {'id': 99, 'first_name': 'Zena'});
      final storage = _FakeAuthSessionStore()
        ..activeBiometricAccountId = '42'
        ..biometricTokens['42'] = 'biometric-token';
      final provider = AuthProvider(api: api, storage: storage);

      final ok = await provider.loginWithBiometricSession();

      expect(ok, isFalse);
      expect(provider.isAuthenticated, isFalse);
    });

    test('fails when there is no saved biometric account', () async {
      final api = _FakeAuthApi();
      final storage = _FakeAuthSessionStore();
      final provider = AuthProvider(api: api, storage: storage);

      final ok = await provider.loginWithBiometricSession();

      expect(ok, isFalse);
    });
  });
}

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({
    this.loginResponse,
    this.profileResponse,
    this.loginError,
    this.storageToObserve,
  });

  dynamic loginResponse;
  dynamic profileResponse;
  Object? loginError;
  final _FakeAuthSessionStore? storageToObserve;

  int fetchProfileCallCount = 0;
  String? lastLoginEmail;
  String? lastLoginPassword;
  String? tokenAtLoginTime;

  @override
  Future<dynamic> login({
    required String email,
    required String password,
    required String platform,
    String? deviceToken,
  }) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
    tokenAtLoginTime = storageToObserve?.token;
    if (loginError != null) throw loginError!;
    return loginResponse ?? <String, dynamic>{};
  }

  @override
  Future<dynamic> fetchProfile() async {
    fetchProfileCallCount++;
    return profileResponse ?? <String, dynamic>{};
  }

  @override
  Future<void> signup({
    required String firstName,
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<dynamic> verifyEmail({
    required String email,
    required String code,
    required String platform,
    String? deviceToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> forgotPassword({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> resendOTP({required String email}) => throw UnimplementedError();

  @override
  Future<void> deleteAccount() => throw UnimplementedError();

  @override
  Future<dynamic> exchangeGoogleToken({
    String? idToken,
    String? accessToken,
    required String platform,
    String? deviceToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<dynamic> exchangeAppleToken({
    required String idToken,
    String? firstName,
    String? lastName,
  }) =>
      throw UnimplementedError();
}

class _FakeAuthSessionStore implements AuthSessionStore {
  String? token;
  bool onboardingComplete = false;
  List<dynamic>? roles;
  String? userId;
  bool cleared = false;
  String? activeBiometricAccountId;
  final Map<String, bool> biometricEnabledByAccount = {};
  final Map<String, String> biometricTokens = {};

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<bool> hasToken() async => token != null && token!.isNotEmpty;

  @override
  Future<void> saveRoles(List<dynamic> value) async => roles = value;

  @override
  Future<List<dynamic>?> loadRoles() async => roles;

  @override
  Future<bool> isOnboardingComplete() async => onboardingComplete;

  @override
  Future<void> setOnboardingComplete() async => onboardingComplete = true;

  @override
  Future<void> saveUserId(String id) async => userId = id;

  @override
  Future<void> clearAll() async {
    cleared = true;
    token = null;
    roles = null;
  }

  @override
  Future<bool> isBiometricEnabledForAccount(String accountId) async =>
      biometricEnabledByAccount[accountId] ?? false;

  @override
  Future<void> saveBiometricTokenForAccount(
          String accountId, String token) async =>
      biometricTokens[accountId] = token;

  @override
  Future<String?> getBiometricTokenForAccount(String accountId) async =>
      biometricTokens[accountId];

  @override
  Future<void> setActiveBiometricAccountId(String? accountId) async =>
      activeBiometricAccountId = accountId;

  @override
  Future<String?> getActiveBiometricAccountId() async =>
      activeBiometricAccountId;
}
