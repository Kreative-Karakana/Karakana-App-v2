import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';

/// The first screen shown when the app launches.
///
/// Displays Karakana branding for 2 seconds while the app determines
/// the correct destination based on authentication and onboarding state,
/// then navigates automatically.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  /// Waits 2 seconds then redirects to the appropriate screen.
  void _navigateAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      final auth = context.read<AuthProvider>();

      if (!auth.isOnboardingComplete) {
        context.go(AppRoutes.onboarding);
      } else if (auth.isAuthenticated) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo placeholder ──────────────────────
            // Replace this container with an Image.asset widget once
            // the real Karakana logo asset is available.
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                'K',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── App name ──────────────────────────────
            Text(
              'KARAKANA',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),

            const SizedBox(height: 8),

            // ── Tagline ───────────────────────────────
            Text(
              'Empowering Entrepreneurs',
              style: TextStyle(
                color: AppColors.lightOrange,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 48),

            // ── Loading indicator ─────────────────────
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
