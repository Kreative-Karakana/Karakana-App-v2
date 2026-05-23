import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with AutomaticKeepAliveClientMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _obscurePassword = true;
  OverlayEntry? _errorOverlayEntry;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _removeErrorOverlay();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<_BiometricState> _getBiometricState() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final enrolled = await _localAuth.canCheckBiometrics;
      if (!supported || !enrolled) {
        return const _BiometricState();
      }
      final biometrics = await _localAuth.getAvailableBiometrics();
      final enabled = await SecureStorage().isBiometricEnabled();
      final hasSession = await SecureStorage().hasBiometricToken();
      final hasFaceId = biometrics.contains(BiometricType.face);
      final hasFingerprint = biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.strong) ||
          biometrics.contains(BiometricType.weak);

      return _BiometricState(
        hasFaceId: hasFaceId,
        hasFingerprint: hasFingerprint,
        enabled: enabled,
        hasSession: hasSession,
      );
    } catch (_) {
      return const _BiometricState();
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) {
      if (mounted) context.go(auth.homeRoute);
    } else if (mounted) {
      _showTopErrorPopup(
        auth.errorMessage ?? 'Imeshindikana kuingia. Tafadhali jaribu tena.',
      );
    }
  }

  void _removeErrorOverlay() {
    _errorOverlayEntry?.remove();
    _errorOverlayEntry = null;
  }

  void _showTopErrorPopup(String message) {
    _removeErrorOverlay();
    final overlay = Overlay.of(context);
    _errorOverlayEntry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(40 * (1 - value), -22 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5A2118), Color(0xFF7A2D1F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.red.shade300.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 20.r,
                          color: Colors.red.shade200,
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_errorOverlayEntry!);
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      _removeErrorOverlay();
    });
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();
    if (success && mounted) {
      context.go(auth.homeRoute);
    } else if (mounted) {
      _showTopErrorPopup(
        auth.errorMessage ??
            'Imeshindikana kuingia kwa Google. Tafadhali jaribu tena.',
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithApple();
    if (success && mounted) {
      context.go(auth.homeRoute);
    } else if (!success && mounted) {
      final msg = auth.errorMessage;
      if (msg != null && msg.isNotEmpty) {
        _showTopErrorPopup(msg);
      }
    }
  }

  void _handleBiometricUnavailable() {
    _showTopErrorPopup('Biometric haijawezeshwa kwenye kifaa hiki bado.');
  }

  Future<void> _handleBiometricTap(_BiometricState state) async {
    final available = state.hasFaceId || state.hasFingerprint;
    if (!available) {
      _handleBiometricUnavailable();
      return;
    }

    if (!state.enabled) {
      _showTopErrorPopup(
        'Washa biometric kwenye sehemu ya Akaunti baada ya kuingia.',
      );
      return;
    }

    if (!state.hasSession) {
      _showTopErrorPopup('Washa biometric kwanza ndani ya akaunti yako.');
      return;
    }

    if (mounted) context.go('/biometric');
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    required bool compact,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.montserrat(
          fontSize: compact ? 13 : 14, color: Colors.white),
      cursorColor: AppColors.primaryMid,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(
          fontSize: compact ? 11.5 : 12,
          color: AppColors.textTertiary,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          fontSize: compact ? 12.5 : 13,
          color: AppColors.textTertiary.withValues(alpha: 0.55),
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryMid, size: 18.r),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF5A3525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: compact ? 14 : 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 760;
          final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

          return Stack(
            children: [
              const _AuthBackground(),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.only(
                          bottom: keyboardOpen
                              ? MediaQuery.viewInsetsOf(context).bottom
                              : 0,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            22,
                            compact ? 14 : 24,
                            22,
                            compact ? 10 : 16,
                          ),
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    constraints.maxHeight - (compact ? 24 : 40),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: 28.h),
                                  Center(
                                    child: Container(
                                      width: 88,
                                      height: 88,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(16.r),
                                        child: Image.asset(
                                          'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              'K',
                                              style: GoogleFonts.poppins(
                                                fontSize: 32.sp,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.sm.h),
                                  Text(
                                    'Karakana',
                                    style: GoogleFonts.poppins(
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.md.h),
                                  Align(
                                    alignment: Alignment.center,
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 420),
                                      child: Container(
                                        padding:
                                            EdgeInsets.all(compact ? 18 : 22),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.06),
                                          borderRadius:
                                              BorderRadius.circular(30.r),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.08),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.18),
                                              blurRadius: 28,
                                              offset: const Offset(0, 16),
                                            ),
                                          ],
                                        ),
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Karibu Tena',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: compact
                                                      ? 22
                                                      : AppTextStyles
                                                          .h1.fontSize,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  height: 1.02,
                                                ),
                                              ),
                                              SizedBox(height: AppSpacing.sm.h),
                                              Text(
                                                'Ingia kwa akaunti yako na uendelee na masomo yako bila usumbufu.',
                                                style: GoogleFonts.montserrat(
                                                  fontSize:
                                                      compact ? 12.5 : 13.5,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.72),
                                                  height: 1.35,
                                                ),
                                              ),
                                              SizedBox(
                                                  height: compact ? 18 : 22),
                                              _buildField(
                                                label: 'Barua Pepe',
                                                hint: 'jina@mfano.com',
                                                icon: Icons.email_outlined,
                                                controller: _emailController,
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                compact: compact,
                                                validator: (v) => v!.isEmpty ||
                                                        !v.contains('@')
                                                    ? 'Barua pepe si sahihi'
                                                    : null,
                                                onChanged: (_) => context
                                                    .read<AuthProvider>()
                                                    .clearError(),
                                              ),
                                              SizedBox(
                                                  height: compact ? 10 : 12),
                                              _buildField(
                                                label: 'Neno la Siri',
                                                hint: 'Weka neno la siri',
                                                icon: Icons.lock_outline,
                                                controller: _passwordController,
                                                obscureText: _obscurePassword,
                                                compact: compact,
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscurePassword
                                                        ? Icons
                                                            .visibility_outlined
                                                        : Icons
                                                            .visibility_off_outlined,
                                                    color:
                                                        AppColors.textTertiary,
                                                    size: 18.r,
                                                  ),
                                                  onPressed: () => setState(
                                                    () => _obscurePassword =
                                                        !_obscurePassword,
                                                  ),
                                                ),
                                                validator: (v) => v!.isEmpty
                                                    ? 'Weka neno la siri'
                                                    : null,
                                                onChanged: (_) => context
                                                    .read<AuthProvider>()
                                                    .clearError(),
                                              ),
                                              SizedBox(height: compact ? 4 : 8),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: TextButton(
                                                  onPressed: () => context
                                                      .push('/forgot-password'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        AppColors.primaryMid,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child: Text(
                                                    'Umesahau neno la siri?',
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      fontSize:
                                                          compact ? 12 : 12.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: AppSpacing.sm.h),
                                              SizedBox(
                                                width: double.infinity,
                                                child: GradientButton(
                                                  text: 'Ingia',
                                                  height: compact ? 50 : 56,
                                                  isLoading:
                                                      authProvider.isLoading,
                                                  onTap: _handleLogin,
                                                ),
                                              ),
                                              SizedBox(
                                                  height: compact ? 16 : 18),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Divider(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.10),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 10.w),
                                                    child: Text(
                                                      'Njia nyingine',
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontSize: compact
                                                            ? 11
                                                            : AppTextStyles
                                                                .bodySmall
                                                                .fontSize,
                                                        color: AppColors
                                                            .textTertiary,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Divider(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.10),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                  height: compact ? 14 : 16),
                                              FutureBuilder<_BiometricState>(
                                                future: _getBiometricState(),
                                                builder: (context, snapshot) {
                                                  final state = snapshot.data ??
                                                      const _BiometricState();
                                                  final hasFaceId =
                                                      state.hasFaceId;
                                                  final hasFingerprint =
                                                      state.hasFingerprint;

                                                  return Row(
                                                    children: [
                                                      Expanded(
                                                        child: _MethodButton(
                                                          compact: compact,
                                                          label: 'Google',
                                                          onTap: authProvider
                                                                  .isLoading
                                                              ? () {}
                                                              : _handleGoogleSignIn,
                                                          icon: Container(
                                                            width: compact
                                                                ? 22
                                                                : 24,
                                                            height: compact
                                                                ? 22
                                                                : 24,
                                                            decoration:
                                                                const BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                'G',
                                                                style: GoogleFonts
                                                                    .montserrat(
                                                                  fontSize:
                                                                      12.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color:
                                                                      const Color(
                                                                    0xFF4285F4,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 10.w),
                                                      Expanded(
                                                        child: _MethodButton(
                                                          compact: compact,
                                                          label: 'Apple',
                                                          onTap: authProvider
                                                                  .isLoading
                                                              ? () {}
                                                              : _handleAppleSignIn,
                                                          icon: Icon(
                                                            Icons.apple,
                                                            color: Colors.white,
                                                            size: compact
                                                                ? 22
                                                                : 24,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 10.w),
                                                      Expanded(
                                                        child: _MethodButton(
                                                          compact: compact,
                                                          label: hasFaceId
                                                              ? 'Face ID'
                                                              : hasFingerprint
                                                                  ? 'Touch ID'
                                                                  : 'Biometric',
                                                          enabled: hasFaceId ||
                                                              hasFingerprint,
                                                          onTap: () =>
                                                              _handleBiometricTap(
                                                                  state),
                                                          icon: Icon(
                                                            hasFaceId
                                                                ? Icons
                                                                    .face_retouching_natural_rounded
                                                                : Icons
                                                                    .fingerprint_rounded,
                                                            color: (hasFaceId ||
                                                                    hasFingerprint)
                                                                ? (hasFaceId
                                                                    ? const Color(
                                                                        0xFFDCE4FF,
                                                                      )
                                                                    : AppColors
                                                                        .primaryMid)
                                                                : AppColors
                                                                    .textTertiary,
                                                            size: compact
                                                                ? 22
                                                                : 24,
                                                          ),
                                                          accentColor: hasFaceId
                                                              ? const Color(
                                                                  0xFF627AF4)
                                                              : AppColors
                                                                  .primary,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
                        child: const Center(
                          child: _SignupFooter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BiometricState {
  final bool hasFaceId;
  final bool hasFingerprint;
  final bool enabled;
  final bool hasSession;

  const _BiometricState({
    this.hasFaceId = false,
    this.hasFingerprint = false,
    this.enabled = false,
    this.hasSession = false,
  });
}

class _SignupFooter extends StatelessWidget {
  const _SignupFooter();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 760;

    return GestureDetector(
      onTap: () => context.push('/signup'),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 24,
          vertical: compact ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Huna akaunti?',
              style: GoogleFonts.montserrat(
                fontSize: compact ? 13 : 14,
                color: Colors.white.withValues(alpha: 0.74),
              ),
            ),
            SizedBox(width: 10.w),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 16,
                vertical: compact ? 5 : 6,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFE07A2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(50.r),
              ),
              child: Text(
                'Jisajili Sasa',
                style: GoogleFonts.montserrat(
                  fontSize: compact ? 12.5 : 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2D1207), Color(0xFF200903)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.11),
            ),
          ),
        ),
        Positioned(
          top: 180,
          left: -45,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryMid.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -55,
          left: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
        ),
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool compact;
  final Color? accentColor;

  const _MethodButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.compact,
    this.enabled = true,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = enabled
        ? (accentColor ?? Colors.white).withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.06);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8.w,
          vertical: compact ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.035)
              : Colors.white.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            SizedBox(height: compact ? 8 : 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
