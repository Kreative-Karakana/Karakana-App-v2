import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/buttons/gradient_button.dart';
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

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();
    if (success && mounted) context.go('/home');
  }

  Future<void> _handleAppleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithApple();
    if (success && mounted) context.go('/home');
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
      style: GoogleFonts.montserrat(fontSize: compact ? 13 : 14, color: Colors.white),
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
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: keyboardOpen
                              ? const ClampingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              22,
                              compact ? 16 : 22,
                              22,
                              compact ? 8 : 10,
                            ),
                            child: _SignupContent(
                              compact: compact,
                              keyboardOpen: keyboardOpen,
                              authProvider: authProvider,
                              formKey: _formKey,
                              firstNameController: _firstNameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmController: _confirmController,
                              obscurePassword: _obscurePassword,
                              obscureConfirm: _obscureConfirm,
                              onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onToggleConfirm: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              onHandleSignup: _handleSignup,
                              onGoogleSignIn: _handleGoogleSignIn,
                              onAppleSignIn: _handleAppleSignIn,
                              buildField: _buildField,
                            ),
                          ),
                        ),
                      ),
                      if (!keyboardOpen) ...[
                        Padding(
                          padding: EdgeInsets.fromLTRB(22, compact ? 12 : 16, 22, 0),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'Njia nyingine',
                                  style: GoogleFonts.montserrat(
                                    fontSize: compact ? 11 : 12,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10))),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(22, compact ? 10 : 12, 22, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _MethodButton(
                                  compact: compact,
                                  label: 'Google',
                                  onTap: _handleGoogleSignIn,
                                  icon: Container(
                                    width: compact ? 22 : 24,
                                    height: compact ? 22 : 24,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: Center(
                                      child: Text('G', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF4285F4))),
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
                                  icon: Icon(Icons.apple, color: Colors.white, size: compact ? 22 : 24),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            22,
                            compact ? 12 : 16,
                            22,
                            compact ? 20 : 28,
                          ),
                          child: Center(
                            child: GestureDetector(
                              onTap: () => context.go('/login'),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 20 : 24,
                                  vertical: compact ? 12 : 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Una akaunti?',
                                      style: GoogleFonts.montserrat(
                                        fontSize: compact ? 13 : 14,
                                        color: Colors.white.withValues(alpha: 0.74),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
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
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        'Ingia',
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
                            ),
                          ),
                        ),
                    ],
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

class _SignupContent extends StatelessWidget {
  final bool compact;
  final bool keyboardOpen;
  final AuthProvider authProvider;
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final Future<void> Function() onHandleSignup;
  final Future<void> Function() onGoogleSignIn;
  final Future<void> Function() onAppleSignIn;
  final Widget Function({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    required bool compact,
  }) buildField;

  const _SignupContent({
    required this.compact,
    required this.keyboardOpen,
    required this.authProvider,
    required this.formKey,
    required this.firstNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onHandleSignup,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    required this.buildField,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _BrandRow(),
        SizedBox(height: keyboardOpen ? (compact ? 8 : 10) : (compact ? 12 : 16)),
        Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: EdgeInsets.all(compact ? 16 : 18),
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
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Fungua Akaunti',
                  style: GoogleFonts.montserrat(
                    fontSize: compact ? 22 : 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jenga akaunti yako na uanze safari yako ya kujifunza na kukuza biashara.',
                  style: GoogleFonts.montserrat(
                    fontSize: compact ? 12.5 : 13.5,
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: compact ? 12 : 16),
                buildField(
                  label: 'Jina la Kwanza',
                  hint: 'Jina lako',
                  icon: Icons.person_outline,
                  controller: firstNameController,
                  compact: compact,
                  validator: (v) => v!.isEmpty ? 'Weka jina lako' : null,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                ),
                SizedBox(height: compact ? 10 : 12),
                buildField(
                  label: 'Barua Pepe',
                  hint: 'jina@mfano.com',
                  icon: Icons.email_outlined,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  compact: compact,
                  validator: (v) =>
                      v!.isEmpty || !v.contains('@') ? 'Barua pepe si sahihi' : null,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                ),
                SizedBox(height: compact ? 10 : 12),
                buildField(
                  label: 'Neno la Siri',
                  hint: 'Herufi 8 au zaidi',
                  icon: Icons.lock_outline,
                  controller: passwordController,
                  obscureText: obscurePassword,
                  compact: compact,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                    onPressed: onTogglePassword,
                  ),
                  validator: (v) =>
                      v!.length < 8 ? 'Neno la siri lazima liwe na herufi 8+' : null,
                  onChanged: (_) => context.read<AuthProvider>().clearError(),
                ),
                SizedBox(height: compact ? 10 : 12),
                buildField(
                  label: 'Thibitisha Neno la Siri',
                  hint: 'Rudia neno la siri',
                  icon: Icons.lock_outline,
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  compact: compact,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                    onPressed: onToggleConfirm,
                  ),
                  validator: (v) =>
                      v != passwordController.text ? 'Maneno ya siri hayafanani' : null,
                ),
                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.red.shade300.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      authProvider.errorMessage!,
                      style: GoogleFonts.montserrat(
                        fontSize: 12.5,
                        color: Colors.red.shade200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(height: compact ? 8 : 10),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: 'Jisajili',
                    height: compact ? 48 : 52,
                    isLoading: authProvider.isLoading,
                    onTap: onHandleSignup,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    'K',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Karakana',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
  final bool compact;

  const _MethodButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: compact ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            SizedBox(height: compact ? 8 : 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: compact ? 11.5 : 12.5,
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
