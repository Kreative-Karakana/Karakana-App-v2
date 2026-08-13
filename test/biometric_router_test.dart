import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/core/router/app_router.dart';
import 'package:karakana_app/features/auth/providers/auth_provider.dart';

void main() {
  test('biometric-locked sessions cannot reach protected routes', () {
    expect(
      AppRouter.redirectFor(
        authenticationState: AuthenticationState.biometricLocked,
        isOnboarded: true,
        passwordChangeRequired: false,
        isTrainer: false,
        location: AppRoutes.home,
      ),
      AppRoutes.biometric,
    );
  });

  test('biometric unlock route remains reachable while locked', () {
    expect(
      AppRouter.redirectFor(
        authenticationState: AuthenticationState.biometricLocked,
        isOnboarded: true,
        passwordChangeRequired: false,
        isTrainer: true,
        location: AppRoutes.biometric,
      ),
      isNull,
    );
  });
}
