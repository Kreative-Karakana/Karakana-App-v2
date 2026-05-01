import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  static const String _biometricTokenKey = 'biometric_token';
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

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConstants.tokenKey);
    } catch (_) {
      await _recoverStorage();
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: AppConstants.tokenKey);
    } catch (_) {
      await _recoverStorage();
    }
  }

  Future<bool> hasToken() async {
    try {
      final t = await getToken();
      return t != null && t.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveUserId(String id) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.userIdKey, id);
  }

  Future<String?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getString(AppConstants.userIdKey);
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await _prefs;
    await prefs.setBool(AppConstants.onboardingKey, true);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(AppConstants.onboardingKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(AppConstants.biometricKey, enabled);
    if (!enabled) {
      await clearBiometricToken();
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(AppConstants.biometricKey) ?? false;
  }

  Future<void> saveBiometricToken(String token) async {
    try {
      await _storage.write(key: _biometricTokenKey, value: token);
    } catch (_) {}
  }

  Future<String?> getBiometricToken() async {
    try {
      return await _storage.read(key: _biometricTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasBiometricToken() async {
    final token = await getBiometricToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearBiometricToken() async {
    try {
      await _storage.delete(key: _biometricTokenKey);
    } catch (_) {}
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

  Future<void> setMastercardDone() async {
    final prefs = await _prefs;
    await prefs.setBool(AppConstants.mastercardDoneKey, true);
  }

  Future<void> saveRoles(List<dynamic> roles) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.rolesKey, roles.join(','));
  }

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

  Future<void> clearAll() async {
    final prefs = await _prefs;
    try {
      await _storage.delete(key: AppConstants.tokenKey);
      await _storage.delete(key: 'terms_accepted');
    } catch (_) {
      await _recoverStorage();
    }
    await prefs.remove(AppConstants.onboardingKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.ambassadorCodeKey);
    await prefs.remove(AppConstants.mastercardDoneKey);
    await prefs.remove(AppConstants.rolesKey);
  }
}
