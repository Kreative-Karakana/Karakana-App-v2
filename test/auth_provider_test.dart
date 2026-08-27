import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/core/network/api_client.dart';
import 'package:karakana_app/features/auth/providers/auth_provider.dart';
import 'package:karakana_app/features/auth/services/auth_service.dart';
import 'package:karakana_app/features/auth/services/auth_session_store.dart';
import 'package:karakana_app/features/auth/services/biometric_auth_service.dart';

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
      expect(provider.errorMessage, isNull);
    });

    test('clears local session when remote logout fails', () async {
      final api = _FakeAuthApi(logoutError: Exception('offline'));
      final storage = _FakeAuthSessionStore()
        ..token = 'abc123'
        ..biometricEnabledByAccount['42'] = true
        ..legacyBiometricTokensPresent = true;
      final provider = AuthProvider(api: api, storage: storage);

      await provider.logout();

      expect(provider.isAuthenticated, isFalse);
      expect(storage.token, isNull);
      expect(storage.legacyBiometricTokensPresent, isFalse);
      expect(storage.biometricEnabledByAccount['42'], isFalse);
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
          ..biometricEnabledByAccount['42'] = true
          ..legacyBiometricTokensPresent = true;
        final provider = AuthProvider(api: api, storage: storage);

        await provider.logout();
        final loggedIn = await provider.login('zena@example.test', 'password');

        expect(loggedIn, isTrue);
        expect(storage.biometricEnabledByAccount['42'], isFalse);
        expect(storage.token, 'fresh-token');
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
        expect(
          provider.errorMessage,
          'Session Expired, Tafadhali Ingia Tena.',
        );
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

  group('AuthProvider biometric session unlock', () {
    test(
      'real lifecycle reaches locked state then validates before learner auth',
      () async {
        final storage = _FakeAuthSessionStore();
        final api = _FakeAuthApi(
          loginResponse: {'token': 'session-token', 'roles': <String>[]},
          profileResponse: {'id': 42, 'first_name': 'Zena'},
        );
        final initialProvider = AuthProvider(api: api, storage: storage);
        expect(
          await initialProvider.login('zena@example.test', 'password'),
          isTrue,
        );
        await storage.setBiometricEnabledForAccount('42', true);

        final restartedProvider = AuthProvider(
          api: api,
          storage: storage,
          biometricAuth: _FakeBiometricAuth(),
        );
        await restartedProvider.initialize();
        expect(restartedProvider.isBiometricLocked, isTrue);
        expect(restartedProvider.isAuthenticated, isFalse);

        final result = await restartedProvider.unlockBiometricSession();

        expect(result, BiometricUnlockResult.success);
        expect(restartedProvider.isAuthenticated, isTrue);
        expect(restartedProvider.homeRoute, '/home');
      },
    );

    test(
      'restores persisted trainer roles and routes to trainer dashboard',
      () async {
        final api = _FakeAuthApi(
          profileResponse: {'id': 42, 'first_name': 'Zena'},
        );
        final storage = _FakeAuthSessionStore()
          ..token = 'session-token'
          ..userId = '42'
          ..roles = ['trainers']
          ..biometricEnabledByAccount['42'] = true;
        final provider = AuthProvider(
          api: api,
          storage: storage,
          biometricAuth: _FakeBiometricAuth(),
        );
        await provider.initialize();

        final result = await provider.unlockBiometricSession();

        expect(result, BiometricUnlockResult.success);
        expect(provider.homeRoute, '/trainer/dashboard');
      },
    );

    test('account mismatch fails closed', () async {
      final storage = _lockedStorage();
      final provider = AuthProvider(
        api: _FakeAuthApi(profileResponse: {'id': 99}),
        storage: storage,
        biometricAuth: _FakeBiometricAuth(),
      );
      await provider.initialize();

      final result = await provider.unlockBiometricSession();

      expect(result, BiometricUnlockResult.accountMismatch);
      expect(provider.isAuthenticated, isFalse);
      expect(storage.cleared, isTrue);
    });

    for (final entry in {
      BiometricVerificationResult.canceled: BiometricUnlockResult.canceled,
      BiometricVerificationResult.lockedOut: BiometricUnlockResult.lockedOut,
      BiometricVerificationResult.unavailable:
          BiometricUnlockResult.unavailable,
      BiometricVerificationResult.platformError:
          BiometricUnlockResult.platformError,
    }.entries) {
      test(
        '${entry.key.name} fails safely without backend validation',
        () async {
          final api = _FakeAuthApi(profileResponse: {'id': 42});
          final provider = AuthProvider(
            api: api,
            storage: _lockedStorage(),
            biometricAuth: _FakeBiometricAuth(result: entry.key),
          );
          await provider.initialize();

          expect(await provider.unlockBiometricSession(), entry.value);
          expect(provider.isBiometricLocked, isTrue);
          expect(api.fetchProfileCallCount, 0);
        },
      );
    }

    test('temporary profile failure remains locked for retry', () async {
      final provider = AuthProvider(
        api: _FakeAuthApi(profileError: Exception('offline')),
        storage: _lockedStorage(),
        biometricAuth: _FakeBiometricAuth(),
      );
      await provider.initialize();

      expect(
        await provider.unlockBiometricSession(),
        BiometricUnlockResult.temporaryFailure,
      );
      expect(provider.isBiometricLocked, isTrue);
    });

    test(
      'revoked session 401 fails closed and cannot be resurrected',
      () async {
        final storage = _lockedStorage();
        final provider = AuthProvider(
          api: _FakeAuthApi(profileUnauthorized: true),
          storage: storage,
          biometricAuth: _FakeBiometricAuth(),
        );
        await provider.initialize();

        expect(
          await provider.unlockBiometricSession(),
          BiometricUnlockResult.invalidSession,
        );
        expect(
          provider.authenticationState,
          AuthenticationState.unauthenticated,
        );
        expect(storage.token, isNull);
      },
    );

    test('unavailable hardware remains locked without verification', () async {
      final biometric = _FakeBiometricAuth(available: false);
      final provider = AuthProvider(
        api: _FakeAuthApi(profileResponse: {'id': 42}),
        storage: _lockedStorage(),
        biometricAuth: biometric,
      );
      await provider.initialize();

      expect(
        await provider.unlockBiometricSession(),
        BiometricUnlockResult.unavailable,
      );
      expect(provider.isBiometricLocked, isTrue);
      expect(biometric.authenticateCallCount, 0);
    });

    test(
      'global 401 while locked clears session and requires full sign-in',
      () async {
        final storage = _lockedStorage();
        final provider = AuthProvider(
          api: _FakeAuthApi(),
          storage: storage,
          biometricAuth: _FakeBiometricAuth(),
        );
        await provider.initialize();

        await ApiClient().handleUnauthorized();

        expect(
          provider.authenticationState,
          AuthenticationState.unauthenticated,
        );
        expect(storage.token, isNull);
        expect(storage.biometricEnabledByAccount['42'], isFalse);
      },
    );

    test(
      'startup removes legacy bearer-token copies but keeps session',
      () async {
        final storage = _lockedStorage()..legacyBiometricTokensPresent = true;
        final provider = AuthProvider(
          api: _FakeAuthApi(profileResponse: {'id': 42}),
          storage: storage,
          biometricAuth: _FakeBiometricAuth(),
        );

        await provider.initialize();

        expect(storage.legacyBiometricTokensPresent, isFalse);
        expect(storage.token, 'session-token');
        expect(provider.isBiometricLocked, isTrue);
      },
    );
  });
}

_FakeAuthSessionStore _lockedStorage() => _FakeAuthSessionStore()
  ..token = 'session-token'
  ..userId = '42'
  ..biometricEnabledByAccount['42'] = true;

class _FakeBiometricAuth implements BiometricAuthService {
  _FakeBiometricAuth({
    this.result = BiometricVerificationResult.success,
    this.available = true,
  });

  final BiometricVerificationResult result;
  final bool available;
  int authenticateCallCount = 0;

  @override
  Future<BiometricVerificationResult> authenticate({
    required String reason,
  }) async {
    authenticateCallCount++;
    return result;
  }

  @override
  Future<BiometricAvailability> checkAvailability() async => available
      ? const BiometricAvailability(
          isSupported: true,
          isEnrolled: true,
          kind: BiometricKind.face,
        )
      : const BiometricAvailability.unavailable();
}

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({
    this.loginResponse,
    this.profileResponse,
    this.profileError,
    this.profileUnauthorized = false,
    this.loginError,
    this.logoutError,
    this.deleteAccountError,
    this.storageToObserve,
  });

  dynamic loginResponse;
  dynamic profileResponse;
  Object? profileError;
  bool profileUnauthorized;
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
    if (profileUnauthorized) {
      await ApiClient().handleUnauthorized();
      throw Exception('401 unauthorized');
    }
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
  final Map<String, bool> biometricEnabledByAccount = {};
  bool legacyBiometricTokensPresent = false;

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
    legacyBiometricTokensPresent = false;
    biometricEnabledByAccount.updateAll((_, __) => false);
  }

  @override
  Future<bool> isBiometricEnabledForAccount(String accountId) async =>
      biometricEnabledByAccount[accountId] ?? false;

  @override
  Future<String?> getUserId() async => userId;

  @override
  Future<void> setBiometricEnabledForAccount(
    String accountId,
    bool enabled,
  ) async => biometricEnabledByAccount[accountId] = enabled;

  @override
  Future<void> removeLegacyBiometricCredentials() async =>
      legacyBiometricTokensPresent = false;
}
