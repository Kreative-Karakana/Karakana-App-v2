import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Slide data
// ---------------------------------------------------------------------------
class _SlideData {
  final String title;
  final String subtitle;
  final String imagePath;

  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}

// ---------------------------------------------------------------------------
// OnboardingScreen
// ---------------------------------------------------------------------------
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
      title: 'Jenga Ujuzi wa Biashara\nna Ubunifu',
      subtitle:
          'Mafunzo ya vitendo kwa mbinu za kisasa yatakayokusaidia kukuza biashara yako kutoka kwa wataalamu waliobobea.',
      imagePath: 'assets/onboarding/slide_1.png',
    ),
    _SlideData(
      title: 'Zana Bora na Miongozo ya\nKukuza Biashara',
      subtitle:
          'Huduma za usajili, nembo na mitandao ya kijamii zinazokuokoa muda na kukuwezesha kuzingatia ukuaji wa biashara yako.',
      imagePath: 'assets/onboarding/slide_2.png',
    ),
    _SlideData(
      title: 'Huduma Muhimu kwa\nKukuza Biashara Yako',
      subtitle:
          'Simamia biashara yako kwa ufanisi wa zana na mipango bora, pamoja na ushauri wa kitaalamu kupitia warsha na mikutano ya moja kwa moja.',
      imagePath: 'assets/onboarding/slide_3.png',
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
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

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ---------------------------------------------------------------------------
  // Concentric decorative circles — mimics the pattern in the screenshots
  // ---------------------------------------------------------------------------
  Widget _decorativeRings({required double size, double opacity = 0.12}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(5, (i) {
          final ratio = 1.0 - i * 0.18;
          return Container(
            width: size * ratio,
            height: size * ratio,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: opacity - i * 0.018),
                width: 1.2,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Individual slide
  // ---------------------------------------------------------------------------
  Widget _buildSlide(_SlideData slide) {
    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight;
      final imageHeight = h * 0.60;

      return Column(
        children: [
          // TOP: Orange image area
          SizedBox(
            height: imageHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Solid orange background
                Container(color: const Color(0xFFE8920A)),

                // Decorative concentric rings
                Positioned(
                  top: -imageHeight * 0.28,
                  right: -imageHeight * 0.28,
                  child: _decorativeRings(size: imageHeight * 0.85),
                ),
                Positioned(
                  bottom: -imageHeight * 0.2,
                  left: -imageHeight * 0.2,
                  child: _decorativeRings(
                    size: imageHeight * 0.6,
                    opacity: 0.08,
                  ),
                ),

                // Person image - no shader mask, show cleanly
                Positioned.fill(
                  child: Image.asset(
                    slide.imagePath,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 140,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM: White text panel
          Expanded(
            child: Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    slide.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0A00),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: const Color(0xFF6B5040),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Page dot indicators
  // ---------------------------------------------------------------------------
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = _currentPage == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFE87722)
                : const Color(0xFFE87722).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLast = _currentPage == 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFE8920A),
        body: Stack(
          children: [
            // ── PageView ──────────────────────────────────────────────────────
            PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: _slides.map(_buildSlide).toList(),
            ),

            // ── "Ruka" skip button — top right, slides 0 & 1 only ────────────
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: AnimatedOpacity(
                  opacity: isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 4),
                    child: TextButton(
                      onPressed: isLast
                          ? null
                          : () => _completeOnboardingAndGo('/login'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Ruka',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A0A00).withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom controls ───────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(32, 12, 32, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDots(),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: isLast
                            ? SizedBox(
                                key: const ValueKey('last'),
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _completeOnboardingAndGo('/signup'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: Text(
                                    'Anza Sasa',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                key: const ValueKey('next'),
                                child: GestureDetector(
                                  onTap: _nextPage,
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 28,
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
          ],
        ),
      ),
    );
  }
}
