import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricKind { face, fingerprint, none }

class BiometricAvailability {
  const BiometricAvailability({
    required this.isSupported,
    required this.isEnrolled,
    required this.kind,
  });

  const BiometricAvailability.unavailable()
      : isSupported = false,
        isEnrolled = false,
        kind = BiometricKind.none;

  final bool isSupported;
  final bool isEnrolled;
  final BiometricKind kind;

  bool get canAuthenticate =>
      isSupported && isEnrolled && kind != BiometricKind.none;
}

enum BiometricVerificationResult {
  success,
  canceled,
  unavailable,
  lockedOut,
  platformError,
}

abstract class BiometricAuthService {
  Future<BiometricAvailability> checkAvailability();

  Future<BiometricVerificationResult> authenticate({
    required String reason,
  });
}

class LocalBiometricAuthService implements BiometricAuthService {
  LocalBiometricAuthService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  @override
  Future<BiometricAvailability> checkAvailability() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final enrolled = await _localAuth.canCheckBiometrics;
      if (!supported || !enrolled) {
        return BiometricAvailability(
          isSupported: supported,
          isEnrolled: enrolled,
          kind: BiometricKind.none,
        );
      }

      final types = await _localAuth.getAvailableBiometrics();
      final kind = types.contains(BiometricType.face)
          ? BiometricKind.face
          : types.any(
              (type) =>
                  type == BiometricType.fingerprint ||
                  type == BiometricType.strong ||
                  type == BiometricType.weak,
            )
              ? BiometricKind.fingerprint
              : BiometricKind.none;
      return BiometricAvailability(
        isSupported: supported,
        isEnrolled: enrolled,
        kind: kind,
      );
    } on PlatformException {
      return const BiometricAvailability.unavailable();
    }
  }

  @override
  Future<BiometricVerificationResult> authenticate({
    required String reason,
  }) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      return authenticated
          ? BiometricVerificationResult.success
          : BiometricVerificationResult.canceled;
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      if (code.contains('lockedout') || code.contains('permanentlylockedout')) {
        return BiometricVerificationResult.lockedOut;
      }
      if (code.contains('notenrolled') ||
          code.contains('not_available') ||
          code.contains('notavailable') ||
          code.contains('no_biometric_hardware') ||
          code.contains('passcodenotenrolled')) {
        return BiometricVerificationResult.unavailable;
      }
      return BiometricVerificationResult.platformError;
    } catch (_) {
      return BiometricVerificationResult.platformError;
    }
  }
}
