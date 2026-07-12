/// Session-storage operations used by `AuthProvider`. `SecureStorage`
/// implements this so tests can substitute an in-memory fake instead of
/// touching secure-storage platform channels.
abstract class AuthSessionStore {
  Future<void> deleteToken();
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<bool> hasToken();
  Future<void> saveRoles(List<dynamic> roles);
  Future<List<dynamic>?> loadRoles();
  Future<bool> isOnboardingComplete();
  Future<void> setOnboardingComplete();
  Future<void> saveUserId(String id);
  Future<void> clearAll();
  Future<bool> isBiometricEnabledForAccount(String accountId);
  Future<void> saveBiometricTokenForAccount(String accountId, String token);
  Future<String?> getBiometricTokenForAccount(String accountId);
  Future<void> setActiveBiometricAccountId(String? accountId);
  Future<String?> getActiveBiometricAccountId();
}
