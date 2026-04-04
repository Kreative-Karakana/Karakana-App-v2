import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/buttons/gradient_button.dart';
import '../../../widgets/common/app_logo.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with AutomaticKeepAliveClientMixin {
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final email = await auth.signup(
      _firstNameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (email != null && mounted) {
      context.go('/verify-email?email=${Uri.encodeComponent(email)}');
    }
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
    double height = 52,
  }) {
    return SizedBox(
      height: height,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white),
        cursorColor: AppColors.primaryMid,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              GoogleFonts.inter(fontSize: 11.5, color: AppColors.textTertiary),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 12.5,
            color: AppColors.textTertiary.withValues(alpha: 0.58),
          ),
          prefixIcon: Icon(icon, color: AppColors.primaryMid, size: 17),
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
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          final fieldGap = compact ? 8.0 : 10.0;
          final cardPadding = compact ? 16.0 : 18.0;

          return Stack(
            children: [
              const _AuthBackground(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: compact ? 14 : 18),
                      const _BrandRow(),
                      SizedBox(height: compact ? 14 : 18),
                      Text(
                        'Fungua Akaunti',
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 27 : 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Anza safari yako ya ujasiriamali kwa mwonekano mpya na safi.',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: AppColors.primaryMid,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 18),
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
                                label: 'Jina la Kwanza',
                                hint: 'Jina lako',
                                icon: Icons.person_outline,
                                controller: _firstNameController,
                                validator: (v) =>
                                    v!.isEmpty ? 'Weka jina lako' : null,
                                onChanged: (_) =>
                                    context.read<AuthProvider>().clearError(),
                              ),
                              SizedBox(height: fieldGap),
                              _buildField(
                                label: 'Barua Pepe',
                                hint: 'jina@mfano.com',
                                icon: Icons.email_outlined,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => v!.isEmpty || !v.contains('@')
                                    ? 'Barua pepe si sahihi'
                                    : null,
                                onChanged: (_) =>
                                    context.read<AuthProvider>().clearError(),
                              ),
                              SizedBox(height: fieldGap),
                              _buildField(
                                label: 'Neno la Siri',
                                hint: 'Herufi 8 au zaidi',
                                icon: Icons.lock_outline,
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textTertiary,
                                    size: 17,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                validator: (v) => v!.length < 8
                                    ? 'Neno la siri lazima liwe na herufi 8+'
                                    : null,
                                onChanged: (_) =>
                                    context.read<AuthProvider>().clearError(),
                              ),
                              SizedBox(height: fieldGap),
                              _buildField(
                                label: 'Thibitisha Neno la Siri',
                                hint: 'Rudia neno la siri',
                                icon: Icons.lock_outline,
                                controller: _confirmController,
                                obscureText: _obscureConfirm,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textTertiary,
                                    size: 17,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                                validator: (v) => v != _passwordController.text
                                    ? 'Maneno ya siri hayafanani'
                                    : null,
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
                                  text: 'Jisajili',
                                  height: compact ? 52 : 54,
                                  isLoading: authProvider.isLoading,
                                  onTap: _handleSignup,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      const _AuthDivider(),
                      SizedBox(height: compact ? 10 : 12),
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
                      SizedBox(height: compact ? 12 : 14),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Una akaunti? ',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.74),
                                ),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: () => context.go('/login'),
                                  child: Text(
                                    'Ingia',
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
                      SizedBox(height: compact ? 8 : 12),
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
        height: 52,
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
