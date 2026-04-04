import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/buttons/gradient_button.dart';
import '../../auth/providers/auth_provider.dart';

class _SlideData {
  final String title;
  final String subtitle;
  final String imagePath;
  final List<Color> gradientColors;

  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.gradientColors,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<_SlideData> _slides = const [
    _SlideData(
      title: 'Jifunza Ujasiriamali',
      subtitle:
          'Pata mafunzo ya ubora wa ulimwengu kutoka kwa wafunzaji wazuri wa Tanzania.',
      imagePath: 'assets/onboarding/slide_1.png',
      gradientColors: [AppColors.primaryDark, AppColors.primary],
    ),
    _SlideData(
      title: 'Jifunza Kwa Wakati Wako',
      subtitle:
          'Masomo ya video, fuatilia maendeleo yako, na upate maarifa wakati wowote.',
      imagePath: 'assets/onboarding/slide_2.png',
      gradientColors: [Color(0xFF2D1B00), AppColors.primary],
    ),
    _SlideData(
      title: 'Kua Biashara Yako',
      subtitle:
          'Tumia ujuzi halisi kukuza biashara yako Tanzania na zaidi.',
      imagePath: 'assets/onboarding/slide_3.png',
      gradientColors: [AppColors.primaryDark, Color(0xFF8B3A12)],
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboardingAndGo(String route) async {
    await context.read<AuthProvider>().completeOnboarding();
    if (!mounted) return;
    context.go(route);
  }

  Future<void> _finish() async {
    await _completeOnboardingAndGo('/login');
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildSlide(_SlideData slide) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return Column(
          children: [
            // Illustration area — top 55%
            SizedBox(
              height: h * 0.55,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: slide.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(48),
                        bottomRight: Radius.circular(48),
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -10,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  // Image
                  Center(
                    child: Image.asset(
                      slide.imagePath,
                      height: h * 0.38,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.school_rounded,
                        size: 120,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Text area
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  Text(
                    slide.title,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textTertiary,
                      height: 1.55,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // PageView
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: _slides.map(_buildSlide).toList(),
          ),

          // Skip button
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 8),
                child: AnimatedOpacity(
                  opacity: _currentPage < 2 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _currentPage < 2 ? _finish : null,
                    child: Text(
                      'Ruka',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Button
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentPage < 2
                          ? SizedBox(
                              key: const ValueKey('next'),
                              width: double.infinity,
                              child: GradientButton(
                                text: 'Endelea',
                                onTap: _nextPage,
                              ),
                            )
                          : Column(
                              key: const ValueKey('start'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: GradientButton(
                                    text: 'Anza Sasa',
                                    onTap: () =>
                                        _completeOnboardingAndGo('/signup'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _finish,
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Una akaunti? ',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Ingia',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
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
        ],
      ),
    );
  }
}
