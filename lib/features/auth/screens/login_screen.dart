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
    double height = 60,
  }) {
    return SizedBox(
      height: height,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        cursorColor: AppColors.primaryMid,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textTertiary.withValues(alpha: 0.58),
          ),
          prefixIcon: Icon(icon, color: AppColors.primaryMid, size: 18),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFF5A3525),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppColors.primaryMid,
              width: 1.2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.error, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.error, width: 1.2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 760;
          final topGap = compact ? 20.0 : 28.0;
          final sectionGap = compact ? 22.0 : 28.0;
          final cardPadding = compact ? 18.0 : 22.0;
          final fieldHeight = compact ? 56.0 : 60.0;

          return Stack(
            children: [
              const _AuthBackground(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: topGap),
                      const _BrandRow(),
                      SizedBox(height: compact ? 18 : 26),
                      Text(
                        'Karibu Tena',
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 28 : 31,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingia kwenye akaunti yako na uendelee kujifunza.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.primaryMid,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      Container(
                        padding: EdgeInsets.all(cardPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.055),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 24,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildField(
                                label: 'Barua Pepe',
                                hint: 'jina@mfano.com',
                                icon: Icons.email_outlined,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                height: fieldHeight,
                                validator: (v) => v!.isEmpty || !v.contains('@')
                                    ? 'Barua pepe si sahihi'
                                    : null,
                                onChanged: (_) =>
                                    context.read<AuthProvider>().clearError(),
                              ),
                              const SizedBox(height: 12),
                              _buildField(
                                label: 'Neno la Siri',
                                hint: 'Weka neno la siri',
                                icon: Icons.lock_outline,
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                height: fieldHeight,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textTertiary,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? 'Weka neno la siri' : null,
                                onChanged: (_) =>
                                    context.read<AuthProvider>().clearError(),
                              ),
                              const SizedBox(height: 8),
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
                                      fontSize: 12.5,
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
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: GradientButton(
                                  text: 'Ingia',
                                  height: compact ? 54 : 56,
                                  isLoading: authProvider.isLoading,
                                  onTap: _handleLogin,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      FutureBuilder<List<BiometricType>>(
                        future: _biometricTypesFuture,
                        builder: (context, snapshot) {
                          final biometrics = snapshot.data ?? const [];
                          final hasFaceId = _hasFaceId(biometrics);
                          final hasFingerprint = _hasFingerprint(biometrics);
                          final canUseBiometric =
                              hasFaceId || hasFingerprint;

                          final icon = hasFaceId
                              ? Icons.face_retouching_natural_rounded
                              : Icons.fingerprint_rounded;
                          final title = hasFaceId
                              ? 'Tumia Face ID'
                              : hasFingerprint
                                  ? 'Tumia Fingerprint'
                                  : 'Biometric haijawezeshwa';
                          final subtitle = hasFaceId
                              ? 'Ingia kwa utambuzi wa uso kwa haraka na salama.'
                              : hasFingerprint
                                  ? 'Gusa kihisi cha kidole kuingia moja kwa moja.'
                                  : 'Washa Face ID au fingerprint kwenye kifaa hiki ili uitumie hapa.';

                          return _BiometricPanel(
                            icon: icon,
                            title: title,
                            subtitle: subtitle,
                            enabled: canUseBiometric,
                            onTap: canUseBiometric
                                ? () => context.go('/biometric')
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Biometric haijawezeshwa kwenye kifaa hiki bado.',
                                        ),
                                      ),
                                    );
                                  },
                          );
                        },
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      const _AuthDivider(),
                      SizedBox(height: compact ? 12 : 14),
                      _SocialButton(
                        label: 'Endelea na Google',
                        iconWidget: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              'G',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4285F4),
                              ),
                            ),
                          ),
                        ),
                        onTap: _handleGoogleSignIn,
                      ),
                      const SizedBox(height: 10),
                      _SocialButton(
                        label: 'Endelea na Apple',
                        iconWidget: const Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 20,
                        ),
                        isDark: true,
                        onTap: _handleAppleSignIn,
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Huna akaunti? ',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryMid,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 14),
                    ],
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
    return Row(
      children: [
        const AppLogo(size: 48, showBackground: false),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Karakana',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Fundisha  Jifunze  Kua',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ],
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
              colors: [Color(0xFF301106), Color(0xFF210B03)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -30,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: -50,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryMid.withValues(alpha: 0.07),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -30,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.09),
            ),
          ),
        ),
      ],
    );
  }
}

class _BiometricPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _BiometricPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFace = icon == Icons.face_retouching_natural_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? isFace
                    ? [
                        const Color(0xFF1E2234).withValues(alpha: 0.96),
                        const Color(0xFF2E3651).withValues(alpha: 0.96),
                      ]
                    : [
                        const Color(0xFF3F2417).withValues(alpha: 0.97),
                        const Color(0xFF22120B).withValues(alpha: 0.97),
                      ]
                : [
                    Colors.white.withValues(alpha: 0.045),
                    Colors.white.withValues(alpha: 0.035),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: enabled
                ? isFace
                    ? const Color(0xFF9EB2FF).withValues(alpha: 0.24)
                    : AppColors.primaryMid.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.06),
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: (isFace
                            ? const Color(0xFF5F79FF)
                            : AppColors.primary)
                        .withValues(alpha: 0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: enabled
                    ? LinearGradient(
                        colors: isFace
                            ? [
                                const Color(0xFF7C93FF).withValues(alpha: 0.28),
                                const Color(0xFF4C5D94).withValues(alpha: 0.2),
                              ]
                            : [
                                AppColors.primary.withValues(alpha: 0.24),
                                AppColors.primaryMid.withValues(alpha: 0.12),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: enabled
                    ? null
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (enabled && isFace)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFAEC0FF).withValues(alpha: 0.7),
                          width: 1.4,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  Icon(
                    icon,
                    color: enabled
                        ? isFace
                            ? const Color(0xFFDDE5FF)
                            : AppColors.primaryMid
                        : AppColors.textTertiary,
                    size: isFace ? 24 : 28,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: enabled && isFace
                          ? const Color(0xFFF2F5FF)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.35,
                      color: enabled
                          ? isFace
                              ? const Color(0xFFC7D2FF)
                              : AppColors.textTertiary
                          : AppColors.textTertiary.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: enabled
                    ? (isFace
                            ? const Color(0xFF90A6FF)
                            : AppColors.primaryMid)
                        .withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: enabled
                    ? isFace
                        ? const Color(0xFFDCE4FF)
                        : AppColors.primaryMid
                    : AppColors.textTertiary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'au',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final VoidCallback onTap;
  final bool isDark;

  const _SocialButton({
    required this.label,
    required this.iconWidget,
    required this.onTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161616) : const Color(0xFF4A2A1D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
