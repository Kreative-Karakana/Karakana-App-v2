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
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    icon: Icons.school_rounded,
    title: 'Learn Entrepreneurship',
    body:
        'Access world-class entrepreneurship courses taught by experienced trainers',
  ),
  _OnboardingSlide(
    icon: Icons.play_circle_rounded,
    title: 'Learn At Your Own Pace',
    body: 'Watch lessons anytime, anywhere, on your own schedule',
  ),
  _OnboardingSlide(
    icon: Icons.trending_up_rounded,
    title: 'Grow Your Business',
    body: 'Apply real skills and tools to build and grow your business',
  ),
];

// ─────────────────────────────────────────────
// Onboarding screen
// ─────────────────────────────────────────────

/// Shown once to first-time users to introduce the Karakana platform.
///
/// After completing or skipping onboarding, [AuthProvider.completeOnboarding]
/// is called so this screen is never displayed again.
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

  // ── Navigation helpers ─────────────────────

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  /// Marks onboarding as complete then sends the user to the login screen.
  Future<void> _finish() async {
    await context.read<AuthProvider>().completeOnboarding();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isLastSlide = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // ── Slides ─────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) =>
                      _SlideView(slide: _slides[index]),
                ),
              ),

              // ── Page indicator dots ─────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPage
                          ? AppColors.primary
                          : AppColors.lightOrange,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Skip button (hidden on last slide) ──
              if (!isLastSlide)
                TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: TextStyle(color: AppColors.grey, fontSize: 14),
                  ),
                )
              else
                // Keep consistent spacing when Skip is hidden.
                const SizedBox(height: 40),

              const SizedBox(height: 8),

              // ── Primary action button ───────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLastSlide ? _finish : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLastSlide ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Individual slide widget
// ─────────────────────────────────────────────

/// Renders a single onboarding slide with icon, title, and body text.
class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Icon circle ─────────────────────────
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(slide.icon, color: AppColors.primary, size: 48),
        ),

        const SizedBox(height: 40),

        // ── Title ───────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Body ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            slide.body,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey, fontSize: 15, height: 1.5),
          ),
        ),
      ],
    );
  }
}
