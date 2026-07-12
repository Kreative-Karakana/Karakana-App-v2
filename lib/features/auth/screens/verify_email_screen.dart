import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/secure_storage.dart';
import '../../../widgets/buttons/gradient_button.dart';
import '../../../widgets/common/terms_dialog.dart';
import '../../../widgets/common/top_popup.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  String _email = '';
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isResending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email = GoRouterState.of(context).uri.queryParameters['email'] ?? '';
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
      _checkAutoVerify();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _checkAutoVerify() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      _handleVerify();
    }
  }

  Future<void> _handleVerify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      showTopPopup(context, 'Weka msimbo wote wa tarakimu 6');
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyEmail(_email, code);
    if (success && mounted) {
      final termsAccepted = await SecureStorage().isTermsAccepted();
      if (!termsAccepted && mounted) {
        await showTermsDialog(context);
      }
      if (mounted) context.go(auth.homeRoute);
    } else if (mounted) {
      showTopPopup(
        context,
        auth.errorMessage ?? 'Imeshindikana kuthibitisha msimbo. Jaribu tena.',
      );
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.resendOTP(_email);
    if (mounted) {
      showTopPopup(
        context,
        success
            ? 'Msimbo mpya umetumwa'
            : (auth.errorMessage ??
                'Hatukuweza kutuma msimbo mpya. Tafadhali jaribu tena.'),
        isError: !success,
      );
      setState(() => _isResending = false);
    }
  }

  Widget _buildOtpBox(int index, bool compact) {
    return SizedBox(
      width: compact ? 44 : 48,
      height: compact ? 56 : 62,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 1,
        style: GoogleFonts.montserrat(
          fontSize: compact ? 22 : 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        cursorColor: AppColors.primaryMid,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: AppColors.primaryMid, width: 2.0),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (val) => _onOtpChanged(index, val),
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
                            const SizedBox(height: AppSpacing.md),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Thibitisha\nBarua Pepe',
                                    style: GoogleFonts.montserrat(
                                      fontSize: compact ? 26 : 30,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 10 : 12),
                                  Text(
                                    'Weka msimbo wa tarakimu 6 tuliokutumia kwenye:',
                                    style: GoogleFonts.montserrat(
                                      fontSize: compact
                                          ? 12.5
                                          : AppTextStyles.bodySmall.fontSize,
                                      color:
                                          Colors.white.withValues(alpha: 0.55),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.mail_outline_rounded,
                                        size: 14,
                                        color: AppColors.primaryMid,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _email,
                                          style: GoogleFonts.montserrat(
                                            fontSize: compact ? 12.5 : 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryMid,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: compact ? 20 : 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      6,
                                      (i) => _buildOtpBox(i, compact),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 18 : 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: GradientButton(
                                      text: 'Thibitisha',
                                      height: compact ? 50 : 56,
                                      isLoading: authProvider.isLoading,
                                      onTap: _handleVerify,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 14 : 16),
                                  Center(
                                    child: _isResending
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: KarakanaWaveLoader(
                                              color: AppColors.primaryMid,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : GestureDetector(
                                            onTap: _handleResend,
                                            child: Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: compact ? 20 : 24,
                                                vertical: compact ? 12 : 14,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.05),
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.10),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Hukupokea msimbo?',
                                                      maxLines: 2,
                                                      softWrap: true,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontSize:
                                                            compact ? 13 : 14,
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.74),
                                                        height: 1.2,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Flexible(
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal:
                                                              compact ? 12 : 14,
                                                          vertical:
                                                              compact ? 5 : 6,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              AppColors.primary,
                                                              const Color(
                                                                  0xFFE07A2F)
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(50),
                                                        ),
                                                        child: Text(
                                                          'Tuma tena',
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            fontSize: compact
                                                                ? 12
                                                                : 13,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Colors.white,
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
                                  const SizedBox(height: AppSpacing.sm),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () => context.go('/signup'),
                                      icon: Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 16,
                                        color: AppColors.primaryMid,
                                      ),
                                      label: Text(
                                        'Rudi kujisajili',
                                        style: GoogleFonts.montserrat(
                                          fontSize: compact ? 12 : 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryMid,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
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
