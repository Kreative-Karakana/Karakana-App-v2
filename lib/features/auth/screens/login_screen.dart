import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/buttons/gradient_button.dart';
import '../../../widgets/common/app_logo.dart';
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
  late final Future<List<BiometricType>> _biometricTypesFuture =
      _getAvailableBiometrics();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<List<BiometricType>> _getAvailableBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final enrolled = await _localAuth.canCheckBiometrics;
      if (!supported || !enrolled) return const [];
      return _localAuth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  bool _hasFaceId(List<BiometricType> biometrics) {
    return biometrics.contains(BiometricType.face);
  }

  bool _hasFingerprint(List<BiometricType> biometrics) {
    return biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong) ||
        biometrics.contains(BiometricType.weak);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) context.go('/home');
  }

  void _handleGoogleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In coming soon')),
    );
  }

  void _handleAppleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign-In coming soon')),
    );
  }

  void _handleBiometricUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Biometric haijawezeshwa kwenye kifaa hiki bado.'),
      ),
    );
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
      style: GoogleFonts.inter(fontSize: compact ? 13 : 14, color: Colors.white),
      cursorColor: AppColors.primaryMid,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: compact ? 11.5 : 12,
          color: AppColors.textTertiary,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: compact ? 12.5 : 13,
          color: AppColors.textTertiary.withValues(alpha: 0.55),
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryMid, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF5A3525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
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
                    physics: keyboardOpen
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (compact ? 24 : 40),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: keyboardOpen ? 6 : (compact ? 26 : 40),
                          bottom: keyboardOpen ? 18 : (compact ? 30 : 44),
                        ),
                        child: const Center(
                          child: _BrandRow(),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            padding: EdgeInsets.all(compact ? 18 : 22),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 28,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Karibu Tena',
                                    style: GoogleFonts.poppins(
                                      fontSize: compact ? 27 : 31,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.02,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ingia kwa akaunti yako na uendelee na masomo yako bila usumbufu.',
                                    style: GoogleFonts.inter(
                                      fontSize: compact ? 12.5 : 13.5,
                                      color: AppColors.primaryMid,
                                      height: 1.35,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 18 : 22),
                                  _buildField(
                                    label: 'Barua Pepe',
                                    hint: 'jina@mfano.com',
                                    icon: Icons.email_outlined,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    compact: compact,
                                    validator: (v) =>
                                        v!.isEmpty || !v.contains('@')
                                            ? 'Barua pepe si sahihi'
                                            : null,
                                    onChanged: (_) => context
                                        .read<AuthProvider>()
                                        .clearError(),
                                  ),
                                  SizedBox(height: compact ? 10 : 12),
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
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppColors.textTertiary,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Weka neno la siri' : null,
                                    onChanged: (_) => context
                                        .read<AuthProvider>()
                                        .clearError(),
                                  ),
                                  SizedBox(height: compact ? 4 : 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () =>
                                          context.push('/forgot-password'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primaryMid,
                                        visualDensity: VisualDensity.compact,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Umesahau neno la siri?',
                                        style: GoogleFonts.inter(
                                          fontSize: compact ? 12 : 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (authProvider.errorMessage != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorLight
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.red.shade300
                                              .withValues(alpha: 0.22),
                                        ),
                                      ),
                                      child: Text(
                                        authProvider.errorMessage!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          color: Colors.red.shade200,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  SizedBox(
                                    width: double.infinity,
                                    child: GradientButton(
                                      text: 'Ingia',
                                      height: compact ? 50 : 56,
                                      isLoading: authProvider.isLoading,
                                      onTap: _handleLogin,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 16 : 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Colors.white.withValues(
                                            alpha: 0.10,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          'Njia nyingine',
                                          style: GoogleFonts.inter(
                                            fontSize: compact ? 11 : 12,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Colors.white.withValues(
                                            alpha: 0.10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: compact ? 14 : 16),
                                  FutureBuilder<List<BiometricType>>(
                                    future: _biometricTypesFuture,
                                    builder: (context, snapshot) {
                                      final biometrics =
                                          snapshot.data ?? const [];
                                      final hasFaceId =
                                          _hasFaceId(biometrics);
                                      final hasFingerprint =
                                          _hasFingerprint(biometrics);
                                      final canUseBiometric =
                                          hasFaceId || hasFingerprint;

                                      return Row(
                                        children: [
                                          Expanded(
                                            child: _MethodButton(
                                              compact: compact,
                                              label: 'Google',
                                              onTap: _handleGoogleSignIn,
                                              icon: Container(
                                                width: compact ? 22 : 24,
                                                height: compact ? 22 : 24,
                                                decoration:
                                                    const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'G',
                                                    style:
                                                        GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                        0xFF4285F4,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _MethodButton(
                                              compact: compact,
                                              label: 'Apple',
                                              onTap: _handleAppleSignIn,
                                              icon: Icon(
                                                Icons.apple,
                                                color: Colors.white,
                                                size: compact ? 22 : 24,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _MethodButton(
                                              compact: compact,
                                              label: hasFaceId
                                                  ? 'Face ID'
                                                  : hasFingerprint
                                                      ? 'Touch ID'
                                                      : 'Biometric',
                                              enabled: canUseBiometric,
                                              onTap: canUseBiometric
                                                  ? () => context.go(
                                                      '/biometric',
                                                    )
                                                  : _handleBiometricUnavailable,
                                              icon: Icon(
                                                hasFaceId
                                                    ? Icons
                                                        .face_retouching_natural_rounded
                                                    : Icons
                                                        .fingerprint_rounded,
                                                color: canUseBiometric
                                                    ? (hasFaceId
                                                        ? const Color(
                                                            0xFFDCE4FF,
                                                          )
                                                        : AppColors.primaryMid)
                                                    : AppColors.textTertiary,
                                                size: compact ? 22 : 24,
                                              ),
                                              accentColor: hasFaceId
                                                  ? const Color(0xFF627AF4)
                                                  : AppColors.primary,
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
                      if (!keyboardOpen) ...[
                        SizedBox(height: compact ? 24 : 32),
                        const Center(
                          child: _SignupFooter(),
                        ),
                      ],
                        ],
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(size: 60, showBackground: false),
          const SizedBox(width: 12),
          Text(
            'Karakana',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupFooter extends StatelessWidget {
  const _SignupFooter();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 760;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Huna akaunti? ',
            style: GoogleFonts.inter(
              fontSize: compact ? 13 : 14,
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => context.push('/signup'),
              child: Text(
                'Jisajili Sasa',
                style: GoogleFonts.inter(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryMid,
                ),
              ),
            ),
          ),
        ],
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
          horizontal: 8,
          vertical: compact ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.035)
              : Colors.white.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(20),
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
              style: GoogleFonts.inter(
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
