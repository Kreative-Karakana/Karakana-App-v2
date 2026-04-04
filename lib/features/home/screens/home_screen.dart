import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/cards/course_card_horizontal.dart';
import '../../../widgets/cards/shimmer_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../courses/models/course_model.dart';
import '../../courses/providers/course_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<CourseProvider>().loadHomeData());
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Habari Asubuhi ☀️';
    if (hour >= 12 && hour < 17) return 'Habari Mchana 👋';
    if (hour >= 17 && hour < 21) return 'Habari Jioni 🌆';
    return 'Habari Usiku 🌙';
  }

  Widget _buildShimmerSection() {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(right: 12),
          child: ShimmerCard(width: 200, height: 230),
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<CourseProvider, AuthProvider>(
        builder: (context, courses, auth, _) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                context.read<CourseProvider>().loadHomeData(),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Hero AppBar ──────────────────────────────────
                SliverAppBar(
                  expandedHeight: 210,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.primaryDark,
                  iconTheme:
                      const IconThemeData(color: Colors.white),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.headerGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -40,
                            right: -20,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white
                                    .withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            left: -20,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryMid
                                    .withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 16, 20, 16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            _getGreeting(),
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color:
                                                  AppColors.primaryMid,
                                            ),
                                          ),
                                          Text(
                                            auth.userFullName.isNotEmpty
                                                ? '${auth.userFullName}!'
                                                : 'Karibu!',
                                            style: GoogleFonts.poppins(
                                              fontSize: 22,
                                              fontWeight:
                                                  FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons
                                                  .notifications_outlined,
                                              color: Colors.white,
                                              size: 26,
                                            ),
                                            onPressed: () => context
                                                .push('/notifications'),
                                          ),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () => context
                                                .push('/profile'),
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color:
                                                      AppColors.primary,
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipOval(
                                                child:
                                                    auth.userAvatar !=
                                                            null
                                                        ? CachedNetworkImage(
                                                            imageUrl: auth
                                                                .userAvatar!,
                                                            fit: BoxFit
                                                                .cover,
                                                            errorWidget: (_,
                                                                    __,
                                                                    ___) =>
                                                                _avatarFallback(
                                                                    auth.userFullName),
                                                          )
                                                        : _avatarFallback(
                                                            auth.userFullName),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Search tappable bar
                                  GestureDetector(
                                    onTap: () =>
                                        context.push('/explore'),
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(24),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.search,
                                            color: Colors.white
                                                .withValues(alpha: 0.6),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Tafuta kozi...',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Colors.white
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                            errorBuilder: (_, __, ___) => Text(
                              'K',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Karakana',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          context.push('/notifications'),
                    ),
                  ],
                ),

                // ── Stats row ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        _StatCard(
                          icon: Icons.school_outlined,
                          value: '${courses.allCourses.length}+',
                          label: 'Kozi',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        const _StatCard(
                          icon: Icons.people_outlined,
                          value: '500+',
                          label: 'Wanafunzi',
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 12),
                        const _StatCard(
                          icon: Icons.star_outline,
                          value: '4.8',
                          label: 'Ukadiriaji',
                          color: AppColors.primaryMid,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Banner carousel ──────────────────────────────
                if (courses.banners.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _BannerCarousel(banners: courses.banners),
                    ),
                  ),

                // ── Zana promo card ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: GestureDetector(
                      onTap: () => context.push('/zana'),
                      child: Container(
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.zanaGradient,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A2E5A)
                                  .withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.construction_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'ZANA',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'MPYA',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Zana za Biashara kwa Ujasiriamali',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFFB8C8E8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.only(right: 16),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white
                                    .withValues(alpha: 0.6),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Content (shimmer or real) ────────────────────
                if (courses.isLoading) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: _buildShimmerSection(),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildShimmerSection()),
                ] else ...[
                  // Recommended
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Kwako',
                      subtitle: 'Zilizoshauriwa',
                      onTapAll: () => context.push('/explore'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 230,
                      child: courses.recommendedCourses.isEmpty
                          ? _buildEmptySection(
                              'Hakuna kozi zilizopendekezwa')
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              itemCount:
                                  courses.recommendedCourses.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.only(
                                    right: 12),
                                child: SizedBox(
                                  width: 200,
                                  child: CourseCardHorizontal(
                                    course: courses
                                        .recommendedCourses[i],
                                    onTap: () => context.push(
                                        '/course/${courses.recommendedCourses[i].id}'),
                                    onWishlistTap: () => context
                                        .read<CourseProvider>()
                                        .toggleWishlist(courses
                                            .recommendedCourses[i]
                                            .id),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Popular
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Maarufu Sasa',
                      onTapAll: () => context.push('/explore'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 230,
                      child: courses.popularCourses.isEmpty
                          ? _buildEmptySection(
                              'Hakuna kozi maarufu')
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              itemCount:
                                  courses.popularCourses.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.only(
                                    right: 12),
                                child: SizedBox(
                                  width: 200,
                                  child: CourseCardHorizontal(
                                    course:
                                        courses.popularCourses[i],
                                    onTap: () => context.push(
                                        '/course/${courses.popularCourses[i].id}'),
                                    onWishlistTap: () => context
                                        .read<CourseProvider>()
                                        .toggleWishlist(courses
                                            .popularCourses[i].id),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Free — 2-column grid
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Kozi Bure',
                      onTapAll: () => context.push('/explore'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => CourseCardHorizontal(
                          course: courses.freeCourses[i],
                          onTap: () => context.push(
                              '/course/${courses.freeCourses[i].id}'),
                          onWishlistTap: () => context
                              .read<CourseProvider>()
                              .toggleWishlist(
                                  courses.freeCourses[i].id),
                        ),
                        childCount: courses.freeCourses.length > 4
                            ? 4
                            : courses.freeCourses.length,
                      ),
                    ),
                  ),

                  // Become a trainer CTA
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Je, Unajua Ujasiriamali?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Fundisha wengine na upate kipato. Jiunge kama Mwalimu.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textTertiary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: () => context
                                        .push('/trainer/apply'),
                                    style:
                                        OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                10),
                                      ),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8),
                                    ),
                                    child: Text(
                                      'Jiunge Kama Mwalimu',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.school,
                              size: 48,
                              color: AppColors.primary
                                  .withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(
                    child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'K',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTapAll;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.onTapAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          if (onTapAll != null)
            TextButton(
              onPressed: onTapAll,
              child: Text(
                'Tazama Zote →',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;

  const _BannerCarousel({required this.banners});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) =>
                setState(() => _currentIndex = i),
            itemCount: widget.banners.length,
            itemBuilder: (_, i) {
              final b = widget.banners[i];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      b.image != null
                          ? CachedNetworkImage(
                              imageUrl: b.image!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: AppColors.ctaGradient,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: AppColors.ctaGradient,
                                ),
                              ),
                            ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primaryDark
                                    .withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Title
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 40,
                        child: Text(
                          b.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentIndex == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentIndex == i
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
