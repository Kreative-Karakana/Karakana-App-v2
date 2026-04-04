import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/buttons/gradient_button.dart';
import '../../../widgets/common/app_logo.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weka msimbo wote wa tarakimu 6')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyEmail(_email, code);
    if (success && mounted) context.go('/home');
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.resendOTP(_email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Msimbo mpya umetumwa'
                : (auth.errorMessage ??
                    'Hatukuweza kutuma msimbo mpya. Tafadhali jaribu tena.'),
          ),
        ),
      );
      setState(() => _isResending = false);
    }
  }

  Widget _buildOtpBox(int index, bool compact) {
    return SizedBox(
      width: compact ? 42 : 46,
      height: compact ? 52 : 58,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 1,
        style: GoogleFonts.poppins(
          fontSize: compact ? 20 : 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        cursorColor: AppColors.primaryMid,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFF5A3525),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.2),
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
                            onPressed: () => context.go('/signup'),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Thibitisha Barua Pepe',
                              style: GoogleFonts.poppins(
                                fontSize: compact ? 27 : 31,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.02,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Weka msimbo wa tarakimu 6 tuliokutumia kwenye barua pepe hii.',
                              style: GoogleFonts.inter(
                                fontSize: compact ? 12.5 : 13.5,
                                color: AppColors.primaryMid,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _email,
                              style: GoogleFonts.inter(
                                fontSize: compact ? 12 : 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                            SizedBox(height: compact ? 18 : 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                6,
                                (i) => _buildOtpBox(i, compact),
                              ),
                            ),
                            if (authProvider.errorMessage != null) ...[
                              const SizedBox(height: 12),
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
                            SizedBox(height: compact ? 16 : 18),
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
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryMid,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: _handleResend,
                                      child: Text(
                                        'Tuma tena msimbo',
                                        style: GoogleFonts.inter(
                                          fontSize: compact ? 12 : 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryMid,
                                        ),
                                      ),
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
