import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: AppConstants.tokenKey, value: token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConstants.tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: AppConstants.tokenKey);
    } catch (_) {}
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
    try {
      await _storage.write(key: AppConstants.userIdKey, value: id);
    } catch (_) {}
  }

  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: AppConstants.userIdKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> setOnboardingComplete() async {
    try {
      await _storage.write(key: AppConstants.onboardingKey, value: 'true');
    } catch (_) {}
  }

  Future<bool> isOnboardingComplete() async {
    try {
      return await _storage.read(key: AppConstants.onboardingKey) == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
          key: AppConstants.biometricKey, value: enabled.toString());
    } catch (_) {}
  }

  Future<bool> isBiometricEnabled() async {
    try {
      return await _storage.read(key: AppConstants.biometricKey) == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
