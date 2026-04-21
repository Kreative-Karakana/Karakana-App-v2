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

  // Amber used across the whole screen
  static const _amber = Color(0xFFF5A100);

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
      final imageHeight = h * 0.58;

      return Column(
        children: [
          // ── Amber image area ──────────────────────────────────────────────
          SizedBox(
            height: imageHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Solid amber background
                Container(color: _amber),

                // Decorative rings — top-right
                Positioned(
                  top: -imageHeight * 0.28,
                  right: -imageHeight * 0.28,
                  child: _decorativeRings(size: imageHeight * 0.85),
                ),

                // Decorative rings — bottom-left (smaller)
                Positioned(
                  bottom: -imageHeight * 0.2,
                  left: -imageHeight * 0.2,
                  child: _decorativeRings(
                    size: imageHeight * 0.6,
                    opacity: 0.08,
                  ),
                ),

                // Person image — bottom-aligned so it sits naturally on the edge
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

                // Gradient overlay — softens the hard cut into the white text area
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.45, 0.75],
                        colors: [Colors.transparent, Colors.white],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── White text area ───────────────────────────────────────────────
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    slide.title,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    slide.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Spacer so the bottom controls (overlaid) don't cover text
                  const SizedBox(height: 160),
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
            color: isActive ? _amber : _amber.withValues(alpha: 0.3),
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
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
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
                            horizontal: 12, vertical: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Ruka',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
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
                      // Dots
                      _buildDots(),
                      const SizedBox(height: 24),

                      // Button — circular arrow OR full-width CTA on last slide
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: isLast
                            // ── Last page: Anza Sasa ──────────────────────────
                            ? SizedBox(
                                key: const ValueKey('last'),
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _completeOnboardingAndGo('/signup'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _amber,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: Text(
                                    'Anza Sasa',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              )
                            // ── Pages 0 & 1: circular arrow button ────────────
                            : Center(
                                key: const ValueKey('next'),
                                child: GestureDetector(
                                  onTap: _nextPage,
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: _amber,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              _amber.withValues(alpha: 0.38),
                                          blurRadius: 18,
                                          offset: const Offset(0, 7),
                                        ),
                                      ],
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
