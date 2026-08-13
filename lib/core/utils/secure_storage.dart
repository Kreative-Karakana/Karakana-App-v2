import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/services/auth_session_store.dart';
import '../constants/app_constants.dart';

class SecureStorage implements AuthSessionStore {
  static final SecureStorage _instance = SecureStorage._internal();
  static const String _biometricAccountIdKey = 'biometric_account_id';
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
  final FlutterSecureStorage _legacyStorage = const FlutterSecureStorage();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> _recoverStorage() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    try {
      await _legacyStorage.deleteAll();
    } catch (_) {}
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: AppConstants.tokenKey, value: token);
    } catch (_) {
      await _recoverStorage();
      try {
        await _storage.write(key: AppConstants.tokenKey, value: token);
      } catch (_) {}
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConstants.tokenKey);
    } catch (_) {
      await _recoverStorage();
      return null;
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: AppConstants.tokenKey);
    } catch (_) {
      await _recoverStorage();
    }
  }

  @override
  Future<bool> hasToken() async {
    try {
      final t = await getToken();
      return t != null && t.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveUserId(String id) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.userIdKey, id);
  }

  @override
  Future<String?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getString(AppConstants.userIdKey);
  }

  @override
  Future<void> setOnboardingComplete() async {
    final prefs = await _prefs;
    await prefs.setBool(AppConstants.onboardingKey, true);
  }

  @override
  Future<bool> isOnboardingComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(AppConstants.onboardingKey) ?? false;
  }

  String _biometricEnabledKey(String accountId) =>
      'biometric_enabled_$accountId';

  @override
  Future<void> setBiometricEnabledForAccount(
    String accountId,
    bool enabled,
  ) async {
    final prefs = await _prefs;
    await prefs.setBool(_biometricEnabledKey(accountId), enabled);
  }

  @override
  Future<bool> isBiometricEnabledForAccount(String accountId) async {
    final prefs = await _prefs;
    return prefs.getBool(_biometricEnabledKey(accountId)) ?? false;
  }

  @override
  Future<void> removeLegacyBiometricCredentials() async {
    try {
      await _storage.delete(key: 'biometric_token');
      final accountId = await getUserId();
      if (accountId != null && accountId.isNotEmpty) {
        await _storage.delete(key: 'biometric_token_$accountId');
      }
      final secureValues = await _storage.readAll();
      for (final key in secureValues.keys) {
        if (key == 'biometric_token' || key.startsWith('biometric_token_')) {
          await _storage.delete(key: key);
        }
      }
    } catch (_) {
      // Failure to enumerate legacy entries must never delete the canonical
      // session token or turn storage recovery into an authentication bypass.
    }
    final prefs = await _prefs;
    await prefs.remove(_biometricAccountIdKey);
    await prefs.remove(AppConstants.biometricKey);
  }

  Future<bool?> getAmbassadorCodeState() async {
    final prefs = await _prefs;
    if (!prefs.containsKey(AppConstants.ambassadorCodeKey)) return null;
    return prefs.getBool(AppConstants.ambassadorCodeKey);
  }

  Future<void> setAmbassadorCodeState(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(AppConstants.ambassadorCodeKey, value);
  }

  Future<bool> isMastercardDone() async {
    final prefs = await _prefs;
    return prefs.getBool(AppConstants.mastercardDoneKey) ?? false;
  }

  Future<void> setBusinessOnboardingDismissed() async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(AppConstants.businessOnboardingDismissedKey, true);
    } catch (_) {}
  }

  Future<bool> isBusinessOnboardingDismissed() async {
    try {
      final prefs = await _prefs;
      return prefs.getBool(AppConstants.businessOnboardingDismissedKey) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setMastercardDone() async {
    final prefs = await _prefs;
    await prefs.setBool(AppConstants.mastercardDoneKey, true);
  }

  @override
  Future<void> saveRoles(List<dynamic> roles) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.rolesKey, roles.join(','));
  }

  @override
  Future<List<dynamic>?> loadRoles() async {
    final prefs = await _prefs;
    final raw = prefs.getString(AppConstants.rolesKey);
    if (raw == null || raw.isEmpty) return null;
    return raw.split(',').where((r) => r.isNotEmpty).toList();
  }

  Future<void> setTermsAccepted() async {
    try {
      await _storage.write(key: 'terms_accepted', value: 'true');
    } catch (_) {}
  }

  Future<bool> isTermsAccepted() async {
    try {
      return await _storage.read(key: 'terms_accepted') == 'true';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _prefs;
    try {
      await _storage.delete(key: AppConstants.tokenKey);
      await _storage.delete(key: 'terms_accepted');
      final secureValues = await _storage.readAll();
      for (final key in secureValues.keys) {
        if (key == 'biometric_token' || key.startsWith('biometric_token_')) {
          await _storage.delete(key: key);
        }
      }
    } catch (_) {
      await _recoverStorage();
    }
    // Keep onboarding completion sticky across sessions/logouts so returning
    // users are not sent back to welcome slides.
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.ambassadorCodeKey);
    await prefs.remove(AppConstants.mastercardDoneKey);
    await prefs.remove(AppConstants.rolesKey);
    await prefs.remove(_biometricAccountIdKey);
    for (final key in prefs.getKeys()) {
      if (key.startsWith('biometric_enabled_')) {
        await prefs.remove(key);
      }
    }
  }
}
