import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../widgets/buttons/gradient_button.dart';
import '../../../widgets/common/top_popup.dart';
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
    } else if (mounted) {
      showTopPopup(
        context,
        auth.errorMessage ?? 'Imeshindikana kujisajili. Tafadhali jaribu tena.',
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();
    if (success && mounted) {
      context.go(auth.homeRoute);
    } else if (mounted) {
      showTopPopup(
        context,
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
    } else if (mounted) {
      showTopPopup(
        context,
        auth.errorMessage ??
            'Imeshindikana kuingia kwa Apple. Tafadhali jaribu tena.',
      );
    }
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
          vertical: compact ? 12.h : 14.h,
        ),
        constraints: BoxConstraints(minHeight: compact ? 50.h : 54.h),
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
          final shortHeight = constraints.maxHeight < 860;
          final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

          return Stack(
            children: [
              const _AuthBackground(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, safeConstraints) {
                    final keyboardInset =
                        MediaQuery.viewInsetsOf(context).bottom;
                    final verticalPadding =
                        Responsive.h(context, compact ? 0.012 : 0.02);

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        verticalPadding,
                        AppSpacing.md,
                        verticalPadding + keyboardInset,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: keyboardOpen
                              ? 0
                              : safeConstraints.maxHeight -
                                  (verticalPadding * 2),
                        ),
                        child: Align(
                          alignment: keyboardOpen
                              ? Alignment.topCenter
                              : Alignment.center,
                          child: SizedBox(
                            width:
                                safeConstraints.maxWidth - (AppSpacing.md * 2),
                            child: _SignupContent(
                              compact: compact,
                              keyboardOpen: keyboardOpen,
                              shortHeight: shortHeight,
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
                    );
                  },
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
  final bool shortHeight;
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
    required this.shortHeight,
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
    final dense = compact || shortHeight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final veryShort = constraints.maxHeight < 620;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _BrandRow(compact: true),
            SizedBox(
                height: keyboardOpen
                    ? (dense ? 4 : 6)
                    : (veryShort ? 4 : (dense ? 8 : 12))),
            Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: EdgeInsets.all(dense || veryShort ? 18.r : 22.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(30.r),
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
                        fontSize: veryShort
                            ? 18
                            : (dense ? 20 : AppTextStyles.h2.fontSize),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.02,
                      ),
                    ),
                    SizedBox(height: dense || veryShort ? 8.h : 10.h),
                    Text(
                      'Jenga akaunti yako na uanze safari yako ya kujifunza na kukuza biashara.',
                      style: GoogleFonts.montserrat(
                        fontSize: veryShort ? 11 : (dense ? 11.5 : 13.5),
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: dense || veryShort ? 16.h : 18.h),
                    buildField(
                      label: 'Jina la Kwanza',
                      hint: 'Jina lako',
                      icon: Icons.person_outline,
                      controller: firstNameController,
                      compact: dense || veryShort,
                      validator: (v) => v!.isEmpty ? 'Weka jina lako' : null,
                      onChanged: (_) =>
                          context.read<AuthProvider>().clearError(),
                    ),
                    SizedBox(height: dense || veryShort ? 10.h : 12.h),
                    buildField(
                      label: 'Barua Pepe',
                      hint: 'jina@mfano.com',
                      icon: Icons.email_outlined,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      compact: dense || veryShort,
                      validator: (v) => v!.isEmpty || !v.contains('@')
                          ? 'Barua pepe si sahihi'
                          : null,
                      onChanged: (_) =>
                          context.read<AuthProvider>().clearError(),
                    ),
                    SizedBox(height: dense || veryShort ? 10.h : 12.h),
                    buildField(
                      label: 'Neno la Siri',
                      hint: 'Herufi 8 au zaidi',
                      icon: Icons.lock_outline,
                      controller: passwordController,
                      obscureText: obscurePassword,
                      compact: dense || veryShort,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textTertiary,
                          size: 18.r,
                        ),
                        onPressed: onTogglePassword,
                      ),
                      validator: (v) => v!.length < 8
                          ? 'Neno la siri lazima liwe na herufi 8+'
                          : null,
                      onChanged: (_) =>
                          context.read<AuthProvider>().clearError(),
                    ),
                    SizedBox(height: dense || veryShort ? 10.h : 12.h),
                    buildField(
                      label: 'Thibitisha Neno la Siri',
                      hint: 'Rudia neno la siri',
                      icon: Icons.lock_outline,
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      compact: dense || veryShort,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textTertiary,
                          size: 18.r,
                        ),
                        onPressed: onToggleConfirm,
                      ),
                      validator: (v) => v != passwordController.text
                          ? 'Maneno ya siri hayafanani'
                          : null,
                    ),
                    SizedBox(height: dense || veryShort ? 18.h : 22.h),
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        text: 'Jisajili',
                        height: dense || veryShort ? 50.h : 54.h,
                        isLoading: authProvider.isLoading,
                        onTap: onHandleSignup,
                      ),
                    ),
                    if (!keyboardOpen) ...[
                      SizedBox(height: dense || veryShort ? 16.h : 18.h),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Text(
                              'Njia nyingine',
                              style: GoogleFonts.montserrat(
                                fontSize: dense || veryShort
                                    ? 11
                                    : AppTextStyles.bodySmall.fontSize,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: dense || veryShort ? 12.h : 14.h),
                      Row(
                        children: [
                          Expanded(
                            child: _MethodButton(
                              compact: dense || veryShort,
                              label: 'Google',
                              onTap: authProvider.isLoading
                                  ? () {}
                                  : onGoogleSignIn,
                              icon: Container(
                                width: dense || veryShort ? 20 : 22,
                                height: dense || veryShort ? 20 : 22,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    'G',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF4285F4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _MethodButton(
                              compact: dense || veryShort,
                              label: 'Apple',
                              onTap: authProvider.isLoading
                                  ? () {}
                                  : onAppleSignIn,
                              icon: Icon(
                                Icons.apple,
                                color: Colors.white,
                                size: dense || veryShort ? 20 : 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: dense || veryShort ? 14.h : 16.h),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          spacing: 6.w,
                          children: [
                            Text(
                              'Una akaunti?',
                              style: GoogleFonts.montserrat(
                                fontSize: dense || veryShort ? 12.5 : 13.5,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: Text(
                                'Ingia',
                                style: GoogleFonts.montserrat(
                                  fontSize: dense || veryShort ? 12.5 : 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryMid,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}

class _BrandRow extends StatelessWidget {
  final bool compact;

  const _BrandRow({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 60 : 88,
            height: compact ? 60 : 88,
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
          SizedBox(height: compact ? 8 : 12),
          Text(
            'Karakana',
            style: GoogleFonts.poppins(
              fontSize: compact ? 22 : 32,
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
          horizontal: 12.w,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: compact ? 8 : 10),
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
