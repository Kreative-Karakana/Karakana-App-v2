import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/buttons/gradient_button.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_auth_service.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  bool _isAuthenticating = false;
  bool _failed = false;
  bool _hasFaceId = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _prepareAndAuthenticate());
  }

  Future<void> _prepareAndAuthenticate() async {
    try {
      final auth = context.read<AuthProvider>();
      final availability = await auth.getBiometricAvailability();
      final hasFace = availability.kind == BiometricKind.face;

      if (!mounted) return;
      setState(() {
        _hasFaceId = hasFace;
      });

      if (!auth.isBiometricLocked || !availability.canAuthenticate) {
        if (!mounted) return;
        setState(() {
          _failed = true;
          _statusMessage = auth.isBiometricLocked
              ? 'Biometric haipatikani kwenye kifaa hiki.'
              : 'Hakuna kikao kilichofungwa kwa biometric.';
        });
        return;
      }
      await _authenticate();
    } catch (e) {
      debugPrint('[Biometric] Error: $e');
      if (!mounted) return;
      setState(() {
        _failed = true;
        _statusMessage = 'Hitilafu ya utambuzi wa kibayolojia. Jaribu tena.';
      });
    }
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    setState(() {
      _isAuthenticating = true;
      _failed = false;
      _statusMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final result = await auth.unlockBiometricSession();
      if (!mounted) return;
      if (result == BiometricUnlockResult.success) {
        context.go(auth.homeRoute);
        return;
      }
      setState(() {
        _isAuthenticating = false;
        _failed = true;
        _statusMessage = switch (result) {
          BiometricUnlockResult.canceled =>
            'Umeghairi uthibitishaji. Jaribu tena ukiwa tayari.',
          BiometricUnlockResult.unavailable =>
            'Biometric haipatikani. Tumia njia ya kawaida kuingia.',
          BiometricUnlockResult.lockedOut =>
            'Biometric imefungwa kwa muda. Tumia njia ya kawaida kuingia.',
          BiometricUnlockResult.temporaryFailure =>
            'Imeshindikana kuthibitisha kikao kwa sasa. Angalia mtandao kisha ujaribu tena.',
          BiometricUnlockResult.accountMismatch =>
            'Kikao hakilingani na akaunti hii. Tafadhali ingia tena.',
          BiometricUnlockResult.invalidSession =>
            'Kikao kimeisha. Tafadhali ingia tena.',
          BiometricUnlockResult.platformError =>
            'Hitilafu ya biometric imetokea. Tumia njia ya kawaida kuingia.',
          BiometricUnlockResult.success => null,
        };
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _failed = true;
          _statusMessage = 'Biometric haikupatikana. Tumia nywila kuingia.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, const Color(0xFF1A0A00)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryMid.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 120),

                    // Logo
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                'K',
                                style: GoogleFonts.montserrat(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Fingerprint icon
                    Icon(
                      _hasFaceId
                          ? Icons.face_retouching_natural_rounded
                          : Icons.fingerprint,
                      size: 80,
                      color:
                          _failed ? Colors.red.shade400 : AppColors.primaryMid,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'Ingia Kwa Usalama',
                      style: AppTextStyles.h1.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      _hasFaceId
                          ? 'Tumia Face ID kuthibitisha utambulisho wako na kuingia salama'
                          : 'Tumia alama ya kidole kuthibitisha utambulisho wako na kuingia salama',
                      style: GoogleFonts.montserrat(
                        fontSize: AppTextStyles.bodyMedium.fontSize,
                        color: AppColors.textTertiary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    if (_isAuthenticating)
                      KarakanaWaveLoader(
                        color: AppColors.primaryMid,
                      )
                    else if (_failed)
                      Column(
                        children: [
                          Text(
                            _statusMessage ?? 'Uthibitishaji umeshindwa',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.red.shade300,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: GradientButton(
                              text: 'Jaribu Tena',
                              onTap: _authenticate,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: () async {
                              await context
                                  .read<AuthProvider>()
                                  .useFullSignIn();
                              if (context.mounted) context.go('/login');
                            },
                            child: Text(
                              'Ingia kwa Nywila',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryMid,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      TextButton(
                        onPressed: _authenticate,
                        child: Text(
                          'Gusa kwa kidole',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryMid,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
