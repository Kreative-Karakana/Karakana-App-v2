import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/course_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../courses/models/course_model.dart';
import '../../courses/providers/course_provider.dart';

/// Main home screen showing banners, recommended, popular, and free courses.
///
/// One of the 4 primary tabs in the bottom navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;

  @override
  void initState() {
    super.initState();
    // Load data after the first frame so the Provider is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadHomeData();
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context),
      body: Consumer<CourseProvider>(
        builder: (context, courses, _) {
          if (courses.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (courses.errorMessage != null) {
            return _ErrorView(
              message: courses.errorMessage!,
              onRetry: () => courses.loadHomeData(),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: courses.loadHomeData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting ──────────────────────────
                    _GreetingSection(),

                    // ── Banners ────────────────────────────
                    if (courses.banners.isNotEmpty) ...[
                      _BannerSection(
                        banners: courses.banners,
                        controller: _bannerController,
                        currentPage: _currentBannerPage,
                        onPageChanged: (i) =>
                            setState(() => _currentBannerPage = i),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Recommended courses ────────────────
                    if (courses.recommendedCourses.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Recommended For You',
                        onSeeAll: () => context.push('/explore'),
                      ),
                      const SizedBox(height: 12),
                      _HorizontalCourseList(
                        courses: courses.recommendedCourses,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Popular courses ────────────────────
                    if (courses.popularCourses.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Popular Courses',
                        onSeeAll: () => context.push('/explore'),
                      ),
                      const SizedBox(height: 12),
                      _HorizontalCourseList(courses: courses.popularCourses),
                      const SizedBox(height: 24),
                    ],

                    // ── Free courses ───────────────────────
                    if (courses.freeCourses.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Free Courses',
                        onSeeAll: () => context.push('/explore?filter=free'),
                      ),
                      const SizedBox(height: 12),
                      _VerticalCourseList(courses: courses.freeCourses),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'K',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kreative Karakana',
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            'Empowering Entrepreneurs',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: AppColors.dark),
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Greeting section
// ─────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  const _GreetingSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning 👋',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                auth.userFullName,
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Banner section
// ─────────────────────────────────────────────

class _BannerSection extends StatelessWidget {
  const _BannerSection({
    required this.banners,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<BannerModel> banners;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: controller,
            itemCount: banners.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, i) => _BannerCard(banner: banners[i]),
          ),
        ),
        const SizedBox(height: 10),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == currentPage ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == currentPage ? AppColors.primary : AppColors.grey,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final BannerModel banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.primary,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image or fallback color
          if (banner.image != null && banner.image!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: banner.image!,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),

          // Dark gradient overlay for legibility
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withAlpha(180)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Title text
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Text(
              banner.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('See all'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Horizontal course list (cards 220px wide)
// ─────────────────────────────────────────────

class _HorizontalCourseList extends StatelessWidget {
  const _HorizontalCourseList({required this.courses});

  final List<CourseModel> courses;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: courses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final course = courses[i];
          return SizedBox(
            width: 220,
            child: CourseCard(
              course: course,
              onTap: () => context.push('/courses/${course.id}'),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Vertical course list (full-width cards)
// ─────────────────────────────────────────────

class _VerticalCourseList extends StatelessWidget {
  const _VerticalCourseList({required this.courses});

  final List<CourseModel> courses;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: courses
          .map(
            (course) => CourseCard(
              course: course,
              onTap: () => context.push('/courses/${course.id}'),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
