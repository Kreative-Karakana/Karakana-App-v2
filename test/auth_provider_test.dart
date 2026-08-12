import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/core/network/api_client.dart';
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
      expect(
        provider.errorMessage,
        'Imeshindikana kuingia. Tafadhali jaribu tena.',
      );
      expect(storage.token, isNull);
    });

    test(
      'a thrown error surfaces a parsed message and clears loading state',
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
      },
    );

    test(
      'profile failure after token issuance clears the issued token',
      () async {
        final api = _FakeAuthApi(
          loginResponse: {'token': 'issued-token'},
          profileError: Exception('profile unavailable'),
        );
        final storage = _FakeAuthSessionStore();
        final provider = AuthProvider(api: api, storage: storage);

        final ok = await provider.login('user@example.test', 'password');

        expect(ok, isFalse);
        expect(provider.isAuthenticated, isFalse);
        expect(storage.token, isNull);
        expect(storage.cleared, isTrue);
      },
    );
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

    test('trusts a stored token immediately and refreshes profile in the '
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
      expect(api.logoutCallCount, 1);
    });

    test('clears local session when remote logout fails', () async {
      final api = _FakeAuthApi(logoutError: Exception('offline'));
      final storage = _FakeAuthSessionStore()
        ..token = 'abc123'
        ..activeBiometricAccountId = '42'
        ..biometricEnabledByAccount['42'] = true
        ..biometricTokens['42'] = 'biometric-token';
      final provider = AuthProvider(api: api, storage: storage);

      await provider.logout();

      expect(provider.isAuthenticated, isFalse);
      expect(storage.token, isNull);
      expect(storage.activeBiometricAccountId, isNull);
      expect(storage.biometricTokens, isEmpty);
      expect(storage.biometricEnabledByAccount['42'], isTrue);
    });

    test(
      'a later successful login can seed a fresh biometric session',
      () async {
        final api = _FakeAuthApi(
          loginResponse: {'token': 'fresh-token'},
          profileResponse: {'id': 42, 'first_name': 'Zena'},
        );
        final storage = _FakeAuthSessionStore()
          ..token = 'stale-token'
          ..activeBiometricAccountId = '42'
          ..biometricEnabledByAccount['42'] = true
          ..biometricTokens['42'] = 'stale-token';
        final provider = AuthProvider(api: api, storage: storage);

        await provider.logout();
        final restoredBeforeLogin = await provider.loginWithBiometricSession();
        final loggedIn = await provider.login('zena@example.test', 'password');

        expect(restoredBeforeLogin, isFalse);
        expect(loggedIn, isTrue);
        expect(storage.biometricEnabledByAccount['42'], isTrue);
        expect(storage.biometricTokens['42'], 'fresh-token');
        expect(storage.activeBiometricAccountId, '42');
      },
    );
  });

  group('AuthProvider authentication invalidation', () {
    test(
      'concurrent 401 notifications clear and publish logout once',
      () async {
        final api = _FakeAuthApi(
          loginResponse: {
            'token': 'abc123',
            'roles': ['trainers'],
          },
          profileResponse: {'id': 42, 'first_name': 'Zena'},
        );
        final storage = _FakeAuthSessionStore()..clearDelay = true;
        final provider = AuthProvider(api: api, storage: storage);
        await provider.login('zena@example.test', 'password');

        await Future.wait([
          ApiClient().handleUnauthorized(),
          ApiClient().handleUnauthorized(),
        ]);

        expect(storage.clearCallCount, 1);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.user, isNull);
        expect(storage.token, isNull);
      },
    );
  });

  group('AuthProvider.deleteAccount', () {
    test('successful deletion clears the local session', () async {
      final api = _FakeAuthApi();
      final storage = _FakeAuthSessionStore()..token = 'abc123';
      final provider = AuthProvider(api: api, storage: storage);

      await provider.deleteAccount();

      expect(api.deleteAccountCallCount, 1);
      expect(storage.cleared, isTrue);
      expect(provider.isAuthenticated, isFalse);
    });

    test('409-style deletion rejection preserves authentication', () async {
      final error = Exception('trainer_account_deletion_blocked');
      final api = _FakeAuthApi(deleteAccountError: error);
      final storage = _FakeAuthSessionStore()
        ..token = 'abc123'
        ..roles = ['trainers'];
      final provider = AuthProvider(api: api, storage: storage);
      await provider.initialize();

      await expectLater(provider.deleteAccount(), throwsA(same(error)));
      expect(storage.cleared, isFalse);
      expect(storage.token, 'abc123');
      expect(provider.isAuthenticated, isTrue);
    });
  });

  group('AuthProvider.loginWithBiometricSession', () {
    test(
      'restores the session when the profile matches the saved account',
      () async {
        final api = _FakeAuthApi(
          profileResponse: {'id': 42, 'first_name': 'Zena'},
        );
        final storage = _FakeAuthSessionStore()
          ..activeBiometricAccountId = '42'
          ..biometricTokens['42'] = 'biometric-token';
        final provider = AuthProvider(api: api, storage: storage);

        final ok = await provider.loginWithBiometricSession();

        expect(ok, isTrue);
        expect(provider.isAuthenticated, isTrue);
        expect(storage.token, 'biometric-token');
      },
    );

    test(
      'fails when the restored profile does not match the saved account',
      () async {
        final api = _FakeAuthApi(
          profileResponse: {'id': 99, 'first_name': 'Zena'},
        );
        final storage = _FakeAuthSessionStore()
          ..activeBiometricAccountId = '42'
          ..biometricTokens['42'] = 'biometric-token';
        final provider = AuthProvider(api: api, storage: storage);

        final ok = await provider.loginWithBiometricSession();

        expect(ok, isFalse);
        expect(provider.isAuthenticated, isFalse);
      },
    );

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
    this.profileError,
    this.loginError,
    this.logoutError,
    this.deleteAccountError,
    this.storageToObserve,
  });

  dynamic loginResponse;
  dynamic profileResponse;
  Object? profileError;
  Object? loginError;
  Object? logoutError;
  Object? deleteAccountError;
  final _FakeAuthSessionStore? storageToObserve;

  int fetchProfileCallCount = 0;
  int logoutCallCount = 0;
  int deleteAccountCallCount = 0;
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
    if (profileError != null) throw profileError!;
    return profileResponse ?? <String, dynamic>{};
  }

  @override
  Future<void> signup({
    required String firstName,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> verifyEmail({
    required String email,
    required String code,
    required String platform,
    String? deviceToken,
  }) => throw UnimplementedError();

  @override
  Future<void> forgotPassword({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> resendOTP({required String email}) => throw UnimplementedError();

  @override
  Future<void> logout() async {
    logoutCallCount++;
    if (logoutError != null) throw logoutError!;
  }

  @override
  Future<void> deleteAccount() async {
    deleteAccountCallCount++;
    if (deleteAccountError != null) throw deleteAccountError!;
  }

  @override
  Future<dynamic> exchangeGoogleToken({
    String? idToken,
    String? accessToken,
    required String platform,
    String? deviceToken,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> exchangeAppleToken({
    required String idToken,
    String? firstName,
    String? lastName,
    String? authorizationCode,
  }) => throw UnimplementedError();
}

class _FakeAuthSessionStore implements AuthSessionStore {
  String? token;
  bool onboardingComplete = false;
  List<dynamic>? roles;
  String? userId;
  bool cleared = false;
  bool clearDelay = false;
  int clearCallCount = 0;
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
    clearCallCount++;
    if (clearDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    cleared = true;
    token = null;
    roles = null;
    userId = null;
    biometricTokens.clear();
    activeBiometricAccountId = null;
  }

  @override
  Future<bool> isBiometricEnabledForAccount(String accountId) async =>
      biometricEnabledByAccount[accountId] ?? false;

  @override
  Future<void> saveBiometricTokenForAccount(
    String accountId,
    String token,
  ) async => biometricTokens[accountId] = token;

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
