import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// A singleton wrapper around [FlutterSecureStorage] for Karakana.
///
/// Provides typed, named methods for every piece of data the app
/// persists securely (auth token, onboarding state), plus a general
/// [clearAll] for full logout cleanup.
class SecureStorage {
  SecureStorage._internal();

  static final SecureStorage _instance = SecureStorage._internal();

  /// The single shared instance of [SecureStorage].
  static SecureStorage get instance => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    // Use EncryptedSharedPreferences on Android for stronger protection.
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─────────────────────────────────────────────
  // Token methods
  // ─────────────────────────────────────────────

  /// Persists the authentication [token] to secure storage.
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: AppConstants.tokenKey, value: token);
    } catch (e) {
      debugPrint('[SecureStorage] saveToken error: $e');
      rethrow;
    }
  }

  /// Returns the stored authentication token, or `null` if none exists.
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConstants.tokenKey);
    } catch (e) {
      debugPrint('[SecureStorage] getToken error: $e');
      return null;
    }
  }

  /// Removes the stored authentication token (e.g. on logout).
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: AppConstants.tokenKey);
    } catch (e) {
      debugPrint('[SecureStorage] deleteToken error: $e');
      rethrow;
    }
  }

  /// Returns `true` if an authentication token is currently stored.
  Future<bool> hasToken() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('[SecureStorage] hasToken error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Onboarding methods
  // ─────────────────────────────────────────────

  /// Marks the onboarding flow as completed so it is never shown again.
  Future<void> setOnboardingComplete() async {
    try {
      await _storage.write(key: AppConstants.onboardingKey, value: 'true');
    } catch (e) {
      debugPrint('[SecureStorage] setOnboardingComplete error: $e');
      rethrow;
    }
  }

  /// Returns `true` if the user has already completed onboarding.
  Future<bool> isOnboardingComplete() async {
    try {
      final value = await _storage.read(key: AppConstants.onboardingKey);
      return value == 'true';
    } catch (e) {
      debugPrint('[SecureStorage] isOnboardingComplete error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // General
  // ─────────────────────────────────────────────

  /// Wipes all values from secure storage.
  ///
  /// Call this on full logout to ensure no sensitive data is left behind.
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[SecureStorage] clearAll error: $e');
      rethrow;
    }
  }
}
