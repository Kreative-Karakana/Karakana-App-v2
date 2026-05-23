import 'package:flutter/material.dart';
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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPassword(_emailController.text.trim());
    if (success && mounted) {
      setState(() => _emailSent = true);
    } else if (mounted) {
      showTopPopup(
        context,
        auth.errorMessage ??
            'Imeshindikana kutuma kiungo. Tafadhali jaribu tena.',
      );
    }
  }

  Widget _buildEmailField(bool compact) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.montserrat(
          fontSize: compact ? 13 : 14, color: Colors.white),
      cursorColor: AppColors.primaryMid,
      onChanged: (_) => context.read<AuthProvider>().clearError(),
      validator: (v) =>
          v!.isEmpty || !v.contains('@') ? 'Barua pepe si sahihi' : null,
      decoration: InputDecoration(
        labelText: 'Barua Pepe',
        labelStyle: GoogleFonts.montserrat(
          fontSize: compact ? 11.5 : 12,
          color: AppColors.textTertiary,
        ),
        hintText: 'jina@mfano.com',
        hintStyle: GoogleFonts.montserrat(
          fontSize: compact ? 12.5 : 13,
          color: AppColors.textTertiary.withValues(alpha: 0.55),
        ),
        prefixIcon:
            const Icon(Icons.email_outlined, color: AppColors.primaryMid),
        filled: true,
        fillColor: const Color(0xFF5A3525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLg),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLg),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLg),
          borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: compact ? 14 : 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      AppSpacing.md,
                      Responsive.h(context, compact ? 0.015 : 0.025),
                      AppSpacing.md,
                      Responsive.h(context, compact ? 0.01 : 0.018),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: constraints.maxWidth - (AppSpacing.md * 2),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight:
                                  constraints.maxHeight - (compact ? 24 : 40),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                            const SizedBox(height: 28),
                            Center(
                              child: Container(
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
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Karakana',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 420),
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
                              child: !_emailSent
                                  ? Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Umesahau Neno la Siri?',
                                            style: GoogleFonts.montserrat(
                                              fontSize: compact
                                                  ? 22
                                                  : AppTextStyles.h1.fontSize,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              height: 1.02,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Weka barua pepe yako ili upokee kiungo cha kurejesha akaunti yako.',
                                            style: GoogleFonts.montserrat(
                                              fontSize: compact ? 12.5 : 13.5,
                                              color: Colors.white
                                                  .withValues(alpha: 0.72),
                                              height: 1.35,
                                            ),
                                          ),
                                          SizedBox(height: compact ? 18 : 22),
                                          Container(
                                            padding: EdgeInsets.all(
                                                compact ? 14 : 16),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.04),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.08),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Badili neno la siri',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: compact
                                                        ? 16
                                                        : AppTextStyles
                                                            .h3.fontSize,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: compact ? 12 : 14),
                                                _buildEmailField(compact),
                                                SizedBox(
                                                    height: compact ? 14 : 18),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: GradientButton(
                                                    text: 'Tuma Kiungo',
                                                    height: compact ? 50 : 56,
                                                    isLoading:
                                                        authProvider.isLoading,
                                                    onTap: _handleSend,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton.icon(
                                              onPressed: () =>
                                                  context.go('/login'),
                                              icon: const Icon(
                                                Icons
                                                    .arrow_back_ios_new_rounded,
                                                size: 16,
                                                color: AppColors.primaryMid,
                                              ),
                                              label: Text(
                                                'Rudi kuingia',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: compact ? 12 : 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryMid,
                                                ),
                                              ),
                                              style: TextButton.styleFrom(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Barua Pepe Imetumwa',
                                          style: GoogleFonts.montserrat(
                                            fontSize: compact ? 27 : 31,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.02,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Angalia kisanduku chako cha barua pepe na ufuate maelekezo ya kubadili neno la siri.',
                                          style: GoogleFonts.montserrat(
                                            fontSize: compact ? 12.5 : 13.5,
                                            color: AppColors.primaryMid,
                                            height: 1.35,
                                          ),
                                        ),
                                        SizedBox(height: compact ? 18 : 22),
                                        Container(
                                          width: double.infinity,
                                          padding:
                                              EdgeInsets.all(compact ? 16 : 18),
                                          decoration: BoxDecoration(
                                            color: AppColors.success
                                                .withValues(alpha: 0.14),
                                            borderRadius:
                                                BorderRadius.circular(22),
                                            border: Border.all(
                                              color: AppColors.success
                                                  .withValues(alpha: 0.24),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.mark_email_read_rounded,
                                                color: AppColors.success,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Kiungo cha kurejesha kimepelekwa kwenye barua pepe yako.',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: compact ? 12 : 13,
                                                    color: Colors.white,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: compact ? 16 : 18),
                                        SizedBox(
                                          width: double.infinity,
                                          child: GradientButton(
                                            text: 'Rudi Kuingia',
                                            height: compact ? 50 : 56,
                                            onTap: () => context.go('/login'),
                                          ),
                                        ),
                                      ],
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
            ],
          );
        },
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
