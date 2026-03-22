import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────
// Slide data model
// ─────────────────────────────────────────────

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.image,
    required this.title,
    required this.body,
  });

  final String image;
  final String title;
  final String body;
}

const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    image: 'assets/images/Onboard_one_BG.png',
    title: 'Learn Entrepreneurship',
    body:
        'Access world-class entrepreneurship courses taught by experienced Tanzanian trainers',
  ),
  _OnboardingSlide(
    image: 'assets/images/Onboard_two_BG.png',
    title: 'Learn At Your Own Pace',
    body:
        'Watch video lessons anytime, anywhere. Track your progress and grow at your own speed',
  ),
  _OnboardingSlide(
    image: 'assets/images/Onboard_three_BG.png',
    title: 'Grow Your Business',
    body:
        'Apply real business skills and tools to build, launch, and grow your business in Tanzania',
  ),
];

// ─────────────────────────────────────────────
// Onboarding screen
// ─────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    await context.read<AuthProvider>().completeOnboarding();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Full screen PageView (bottom z-order) ──
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) => _SlidePage(slide: _slides[i]),
          ),

          // ── Layer 2: Bottom content (top z-order, always on top) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomContent(
              currentPage: _currentPage,
              totalPages: _slides.length,
              slide: _slides[_currentPage],
              isLastSlide: _currentPage == _slides.length - 1,
              onNext: _nextPage,
              onFinish: _finish,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Individual slide page
// ─────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset(slide.image, fit: BoxFit.cover),

        // Gradient overlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Color(0xFF3B1A08).withValues(alpha: 0.7),
                Color(0xFF3B1A08).withValues(alpha: 0.98),
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Bottom content
// ─────────────────────────────────────────────

class _BottomContent extends StatelessWidget {
  const _BottomContent({
    required this.currentPage,
    required this.totalPages,
    required this.slide,
    required this.isLastSlide,
    required this.onNext,
    required this.onFinish,
  });

  final int currentPage;
  final int totalPages;
  final _OnboardingSlide slide;
  final bool isLastSlide;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    // Material with transparent color ensures the widget is fully
    // hit-testable, preventing the PageView beneath from stealing taps.
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo with drop shadow for visibility
            DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/Kreative_Karakana_-_Official_Logo_(White).png',
                width: 140,
                opacity: const AlwaysStoppedAnimation(0.9),
              ),
            ),

            const SizedBox(height: 24),

            // Slide title
            Text(
              slide.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Slide body
            Text(
              slide.body,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                height: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Page indicator dots
            Row(
              children: List.generate(totalPages, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 6),
                  width: i == currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == currentPage
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Buttons
            if (!isLastSlide)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onFinish,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 15,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Next →',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Get Started →',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
