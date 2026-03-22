import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

/// Email verification screen shown after a successful sign-up.
///
/// The backend sends a 6-digit OTP to the user's email address. This screen
/// collects that code, calls [AuthProvider.verifyEmail], and navigates to
/// [AppRoutes.home] on success. The email is passed as a URI query parameter.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late String _email;

  /// One controller per OTP digit.
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  /// One focus node per OTP digit — used for automatic field-to-field movement.
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  /// Tracks whether a resend request is currently in flight.
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _email =
        GoRouterState.of(context).uri.queryParameters['email'] ?? '';
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // OTP field logic
  // ─────────────────────────────────────────────

  /// Called whenever a digit field's value changes.
  ///
  /// Advances focus to the next field on input, retreats to the previous
  /// field on deletion, and auto-submits once all six digits are present.
  void _onDigitChanged(int index, String value) {
    context.read<AuthProvider>().clearError();

    if (value.isNotEmpty) {
      if (index < 5) {
        // Move forward to the next digit field.
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit filled — dismiss the keyboard.
        _focusNodes[index].unfocus();
      }
      // Auto-submit as soon as all six digits are present.
      if (_controllers.every((c) => c.text.isNotEmpty)) {
        _verify();
      }
    } else if (index > 0) {
      // Digit deleted — move back to the previous field.
      _focusNodes[index - 1].requestFocus();
    }
  }

  // ─────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────

  /// Combines the six digit fields into a single code and calls
  /// [AuthProvider.verifyEmail]. Navigates to home on success.
  Future<void> _verify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyEmail(_email, code);

    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  /// Requests a new OTP from the backend and shows a confirmation snack bar.
  Future<void> _resend() async {
    setState(() => _isResending = true);

    final success =
        await context.read<AuthProvider>().resendOTP(_email);

    if (!mounted) return;

    setState(() => _isResending = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Code resent successfully',
            style: GoogleFonts.inter(color: AppColors.white),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // ── Icon ──────────────────────────────
                  Icon(
                    Icons.mark_email_unread_rounded,
                    size: 72,
                    color: AppColors.primary,
                  ),

                  const SizedBox(height: 24),

                  // ── Heading ───────────────────────────
                  Text(
                    'Verify Your Email',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Subtitle ──────────────────────────
                  Text(
                    'We sent a 6-digit code to',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.grey,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ── Email address ─────────────────────
                  Text(
                    _email,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── OTP input row ─────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (i) => _buildOtpField(i),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Error message ─────────────────────
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      auth.errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Verify button ─────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withAlpha(153),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: auth.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Verify Email',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Resend row ────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code?",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 36,
                        child: TextButton(
                          onPressed:
                              (_isResending || auth.isLoading) ? null : _resend,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: _isResending
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Resend',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  /// Builds a single digit input box at [index].
  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 44,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.dark,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => _onDigitChanged(index, value),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: AppColors.lightOrange,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
