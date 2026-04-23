import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/buttons/gradient_button.dart';
import '../../../widgets/common/app_logo.dart';
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
    final success = await context
        .read<AuthProvider>()
        .forgotPassword(_emailController.text.trim());
    if (success && mounted) {
      setState(() => _emailSent = true);
    }
  }

  Widget _buildEmailField(bool compact) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.montserrat(fontSize: compact ? 13 : 14, color: Colors.white),
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
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 760;

          return Stack(
            children: [
              const _AuthBackground(),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    compact ? 14 : 24,
                    22,
                    compact ? 10 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go('/login'),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const _BrandRow(),
                      const Spacer(),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Badili Neno la Siri',
                                      style: GoogleFonts.montserrat(
                                        fontSize: compact ? 27 : 31,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.02,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Weka barua pepe yako na tutakutumia kiungo cha kurejesha akaunti yako.',
                                      style: GoogleFonts.montserrat(
                                        fontSize: compact ? 12.5 : 13.5,
                                        color: AppColors.primaryMid,
                                        height: 1.35,
                                      ),
                                    ),
                                    SizedBox(height: compact ? 18 : 22),
                                    _buildEmailField(compact),
                                    if (authProvider.errorMessage != null) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.errorLight
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.red.shade300
                                                .withValues(alpha: 0.22),
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
                                    ],
                                    SizedBox(height: compact ? 14 : 18),
                                    SizedBox(
                                      width: double.infinity,
                                      child: GradientButton(
                                        text: 'Tuma Kiungo',
                                        height: compact ? 50 : 56,
                                        isLoading: authProvider.isLoading,
                                        onTap: _handleSend,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    padding: EdgeInsets.all(compact ? 16 : 18),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: AppColors.success.withValues(
                                          alpha: 0.24,
                                        ),
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
                      const Spacer(),
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
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(size: 60, showBackground: false),
          const SizedBox(width: 12),
          Text(
            'Karakana',
            style: GoogleFonts.montserrat(
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
