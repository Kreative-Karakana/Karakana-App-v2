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
    _SlideData(
      title: 'Jenga Ujuzi wa Biashara\nna Ubunifu',
      subtitle:
          'Mafunzo ya vitendo kwa mbinu za kisasa yatakayokusaidia kukuza biashara yako kutoka kwa wataalamu waliobobea.',
      imagePath: 'assets/onboarding/slide_1.png',
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
  // Individual slide
  // ---------------------------------------------------------------------------
  Widget _buildSlide(int index, _SlideData slide) {
    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight;
      final bottomInset = MediaQuery.of(context).padding.bottom;
      final cardHeight = (h * 0.36).clamp(290.0, 332.0);
      final titleStyle = GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A0A00),
        height: 1.2,
      );
      final bodyStyle = GoogleFonts.montserrat(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF6B5040),
        height: 1.55,
      );
      final buttonStyle = GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );
      final isLastSlide = index == _slides.length - 1;

      return Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE8920A),
              image: DecorationImage(
                image: AssetImage(slide.imagePath),
                fit: BoxFit.fitHeight,
                alignment: Alignment.topCenter,
                onError: (_, __) {},
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: cardHeight - 14,
            child: _buildDots(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              height: cardHeight,
              padding: EdgeInsets.fromLTRB(28, 28, 28, 20 + bottomInset),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slide.title,
                    style: titleStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.subtitle,
                    style: bodyStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  if (isLastSlide)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _completeOnboardingAndGo('/signup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: Text('Anza Sasa', style: buttonStyle),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_sharp,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
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
            PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                for (final entry in _slides.asMap().entries)
                  _buildSlide(entry.key, entry.value),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: AnimatedOpacity(
                  opacity: _currentPage == _slides.length - 1 ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 4),
                    child: TextButton(
                      onPressed: _currentPage == _slides.length - 1
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
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A0A00).withValues(alpha: 0.8),
                        ),
                      ),
                    ),
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
