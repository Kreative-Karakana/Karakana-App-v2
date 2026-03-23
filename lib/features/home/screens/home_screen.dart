import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/course_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../courses/models/course_model.dart';
import '../../courses/providers/course_provider.dart';

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
      body: Consumer2<AuthProvider, CourseProvider>(
        builder: (context, auth, courses, _) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: courses.loadHomeData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Gradient header ──────────────────────
                SliverToBoxAdapter(
                  child: _Header(
                    auth: auth,
                    onNotifications: () => context.push('/notifications'),
                    onSearch: () => context.push('/explore'),
                  ),
                ),

                // ── Loading shimmer ──────────────────────
                if (courses.isLoading) ...[
                  SliverToBoxAdapter(child: _LoadingPlaceholder()),
                ],

                // ── Error (only when all lists empty) ───
                if (!courses.isLoading &&
                    courses.errorMessage != null &&
                    courses.recommendedCourses.isEmpty &&
                    courses.popularCourses.isEmpty &&
                    courses.freeCourses.isEmpty) ...[
                  SliverFillRemaining(
                    child: _ErrorView(
                      message: courses.errorMessage!,
                      onRetry: courses.loadHomeData,
                    ),
                  ),
                ],

                if (!courses.isLoading) ...[
                  // ── Banners ──────────────────────────
                  if (courses.banners.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _BannerSection(
                        banners: courses.banners,
                        controller: _bannerController,
                        currentPage: _currentBannerPage,
                        onPageChanged: (i) =>
                            setState(() => _currentBannerPage = i),
                      ),
                    ),

                  // ── Stats row ────────────────────────
                  SliverToBoxAdapter(
                    child: _StatsRow(courseCount: courses.courses.length),
                  ),

                  // ── Recommended ──────────────────────
                  if (courses.recommendedCourses.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'For You',
                        onSeeAll: () => context.push('/explore'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _HorizontalCourseList(
                        courses: courses.recommendedCourses,
                      ),
                    ),
                  ],

                  // ── Popular ──────────────────────────
                  if (courses.popularCourses.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Trending Now',
                        onSeeAll: () => context.push('/explore'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _HorizontalCourseList(
                        courses: courses.popularCourses,
                      ),
                    ),
                  ],

                  // ── Free courses ─────────────────────
                  if (courses.freeCourses.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Free Courses',
                        onSeeAll: () => context.push('/explore'),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.builder(
                        itemCount: courses.freeCourses.length,
                        itemBuilder: (context, i) {
                          final course = courses.freeCourses[i];
                          return CourseCard(
                            course: course,
                            onTap: () => context.push('/courses/${course.id}'),
                          );
                        },
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Gradient header
// ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.auth,
    required this.onNotifications,
    required this.onSearch,
  });

  final AuthProvider auth;
  final VoidCallback onNotifications;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final avatar = auth.userAvatar;
    final hasAvatar = avatar != null && avatar.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B1A08), Color(0xFF6B2D0A)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name row ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning 👋',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.userFullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onNotifications,
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    backgroundImage:
                        hasAvatar ? CachedNetworkImageProvider(avatar) : null,
                    child: hasAvatar
                        ? null
                        : const Text(
                            'K',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Search bar ────────────────────────────
          GestureDetector(
            onTap: onSearch,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search courses...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stats row
// ─────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.courseCount});

  final int courseCount;

  @override
  Widget build(BuildContext context) {
    final count = courseCount > 0 ? '$courseCount+' : '50+';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.school_rounded,
            iconColor: AppColors.primary,
            value: count,
            label: 'Courses',
          ),
          _StatCard(
            icon: Icons.people_rounded,
            iconColor: AppColors.primary,
            value: '500+',
            label: 'Learners',
          ),
          _StatCard(
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
            value: '4.8',
            label: 'Rating',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
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
        Container(
          height: 180,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: PageView.builder(
            controller: controller,
            itemCount: banners.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, i) => _BannerCard(banner: banners[i]),
          ),
        ),
        const SizedBox(height: 8),
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
                color: i == currentPage
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final BannerModel banner;

  @override
  Widget build(BuildContext context) {
    final hasImage = banner.image != null && banner.image!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            CachedNetworkImage(
              imageUrl: banner.image!,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => _BannerFallback(),
            )
          else
            _BannerFallback(),

          // Gradient overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Text(
              banner.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
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

class _BannerFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.dark, AppColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'See all →',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Horizontal course list
// ─────────────────────────────────────────────

class _HorizontalCourseList extends StatelessWidget {
  const _HorizontalCourseList({required this.courses});

  final List<CourseModel> courses;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: courses.length,
        itemBuilder: (_, i) {
          final course = courses[i];
          return Padding(
            padding: EdgeInsets.only(right: i < courses.length - 1 ? 12 : 0),
            child: SizedBox(
              width: 180,
              child: CourseCard(
                course: course,
                onTap: () => context.push('/courses/${course.id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Loading placeholder
// ─────────────────────────────────────────────

class _LoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner placeholder
        Container(
          height: 180,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        // Stats placeholder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: List.generate(
              3,
              (_) => Expanded(
                child: Container(
                  height: 72,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Section placeholder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 22,
            width: 140,
            decoration: BoxDecoration(
              color: AppColors.lightOrange,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (_, __) => Container(
              width: 180,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
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
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
