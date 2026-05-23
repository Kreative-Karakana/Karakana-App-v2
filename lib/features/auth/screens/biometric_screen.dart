import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/secure_storage.dart';
import '../../../widgets/buttons/gradient_button.dart';
import '../providers/auth_provider.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  bool _failed = false;
  bool _hasFaceId = false;
  bool _hasFingerprint = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _prepareAndAuthenticate());
  }

  Future<void> _prepareAndAuthenticate() async {
    try {
      final enabled = await SecureStorage().isBiometricEnabled();
      final hasSession = await SecureStorage().hasBiometricToken();
      final supported = await _localAuth.isDeviceSupported();
      final enrolled = await _localAuth.canCheckBiometrics;
      final biometrics = (supported && enrolled)
          ? await _localAuth.getAvailableBiometrics()
          : const <BiometricType>[];
      final hasFace = biometrics.contains(BiometricType.face);
      final hasFingerprint = biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.strong) ||
          biometrics.contains(BiometricType.weak);

      if (!mounted) return;
      setState(() {
        _hasFaceId = hasFace;
        _hasFingerprint = hasFingerprint;
      });

      if (!enabled || !hasSession || (!hasFace && !hasFingerprint)) {
        if (!mounted) return;
        setState(() {
          _failed = true;
          _statusMessage = 'Biometric haijawashwa kwa akaunti hii.';
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
      final success = await _localAuth.authenticate(
        localizedReason: _hasFaceId
            ? 'Thibitisha kwa Face ID ili kuingia'
            : 'Thibitisha kwa alama ya kidole ili kuingia',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      if (success && mounted) {
        final auth = context.read<AuthProvider>();
        final loggedIn = await auth.loginWithBiometricSession();
        if (!loggedIn) {
          setState(() {
            _isAuthenticating = false;
            _failed = true;
            _statusMessage =
                'Kikao cha biometric kimeisha. Ingia kwa nywila kisha washa tena biometric.';
          });
          return;
        }
        if (!mounted) return;
        context.go(auth.homeRoute);
      } else if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _failed = true;
          _statusMessage = 'Uthibitishaji umeshindikana. Jaribu tena.';
        });
      }
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, Color(0xFF1A0A00)],
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
                      const KarakanaWaveLoader(
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
                            onPressed: () => context.go('/login'),
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
