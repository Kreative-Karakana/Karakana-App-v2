import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
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
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ───────────────────────
          Image.asset(
            'assets/images/Log_In_BG.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // ── Dark brown gradient overlay ────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3B1A08).withValues(alpha:0.85),
                  Color(0xFF3B1A08).withValues(alpha:0.6),
                  Color(0xFF3B1A08).withValues(alpha:0.95),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Logo
                Image.asset(
                  'assets/images/Kreative_Karakana_-_Official_Logo_(White).png',
                  width: 220,
                ),

                const SizedBox(height: 16),

                // Tagline
                Text(
                  'Empowering Entrepreneurs',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:0.85),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    letterSpacing: 2,
                  ),
                ),

                const Spacer(),

                // Loading indicator
                CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),

                const SizedBox(height: 20),

                // Version
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:0.4),
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
