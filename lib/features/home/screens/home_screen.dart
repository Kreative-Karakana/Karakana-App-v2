
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
      (_) => context.read<CourseProvider>().loadHomeData(),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Habari za Asubuhi';
    if (hour < 17) return 'Habari za Mchana';
    if (hour < 21) return 'Habari za Jioni';
    return 'Habari za Usiku';
  }

  String _getFirstName(AuthProvider auth) {
    final fullName = auth.userFullName.trim();
    if (fullName.isNotEmpty) return fullName.split(' ').first;
    final email = auth.userEmail;
    if (email.isNotEmpty) return email.split('@').first;
    return 'Rafiki';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<CourseProvider, AuthProvider>(
        builder: (context, courses, auth, _) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<CourseProvider>().loadHomeData(),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 235,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.primaryDark,
                  surfaceTintColor: Colors.transparent,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Image.asset(
                            'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                'K',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Karakana',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => context.push('/notifications'),
                        padding: const EdgeInsets.all(7),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: ClipOval(
                          child: auth.userAvatar != null
                              ? CachedNetworkImage(
                                  imageUrl: auth.userAvatar!,
                                  fit: BoxFit.cover,
                                  width: 36,
                                  height: 36,
                                )
                              : Container(
                                  color: AppColors.primary,
                                  child: Center(
                                    child: Text(
                                      _getFirstName(auth).isNotEmpty
                                          ? _getFirstName(auth)[0].toUpperCase()
                                          : 'K',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
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
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            top: -40,
                            right: -20,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
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
                                color: AppColors.primaryMid.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 65, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  // ── Greeting ──
                                  Text(
                                    '${_getGreeting()},',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.primaryMid,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  Text(
                                    _getFirstName(auth),
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // ── Row 3: Search bar ──
                                  GestureDetector(
                                    onTap: () => context.push('/explore'),
                                    child: Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 14),
                                          Icon(
                                            Icons.search,
                                            color: Colors.white.withValues(alpha: 0.7),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Tafuta kozi...',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Colors.white.withValues(alpha: 0.6),
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
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        _StatCard(
                          icon: Icons.school_outlined,
                          value: '20+',
                          label: 'Kozi',
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 10),
                        _StatCard(
                          icon: Icons.people_outlined,
                          value: '500+',
                          label: 'Wanafunzi',
                          color: AppColors.primaryDark,
                        ),
                        SizedBox(width: 10),
                        _StatCard(
                          icon: Icons.star_outline,
                          value: '4.8',
                          label: 'Ukadiriaji',
                          color: AppColors.primaryMid,
                        ),
                      ],
                    ),
                  ),
                ),
                if (courses.banners.isNotEmpty)
                  SliverToBoxAdapter(child: _BannerCarousel(banners: courses.banners)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: GestureDetector(
                      onTap: () => context.push('/zana'),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B2F5F), Color(0xFF29498E), Color(0xFF3558A9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A2E5A).withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.construction_outlined, color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'ZANA',
                                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                                        child: Text(
                                          'MPYA',
                                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'POS, biashara, bima, na huduma zinazokuja hivi karibuni kwa mjasiriamali wa Tanzania.',
                                    style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: Colors.white.withValues(alpha: 0.82)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (courses.isLoading) ...[
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 24), child: _shimmer())),
                  SliverToBoxAdapter(child: _shimmer()),
                ] else ...[
                  SliverToBoxAdapter(child: _SectionHeader(title: 'Kwako', subtitle: 'Mapendekezo ya leo', onTapAll: () => context.push('/explore'))),
                  SliverToBoxAdapter(child: _courseStrip(courses.recommendedCourses, 'Hakuna kozi zilizopendekezwa kwa sasa')),
                  SliverToBoxAdapter(child: _SectionHeader(title: 'Maarufu Sasa', subtitle: 'Kozi zinazovuma', onTapAll: () => context.push('/explore'))),
                  SliverToBoxAdapter(child: _courseStrip(courses.popularCourses, 'Hakuna kozi maarufu kwa sasa')),
                  SliverToBoxAdapter(child: _SectionHeader(title: 'Kozi Bure', subtitle: 'Anza bila gharama', onTapAll: () => context.push('/explore'))),
                  if (courses.freeCourses.isEmpty)
                    SliverToBoxAdapter(child: _empty('Hakuna kozi bure kwa sasa'))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => CourseCardHorizontal(
                            course: courses.freeCourses[i],
                            onTap: () => context.push('/course/${courses.freeCourses[i].id}'),
                            onWishlistTap: () => context.read<CourseProvider>().toggleWishlist(courses.freeCourses[i].id),
                          ),
                          childCount: courses.freeCourses.length > 4 ? 4 : courses.freeCourses.length,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 14, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fundisha Ulichonacho',
                                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Geuza uzoefu wako wa biashara kuwa kozi na ufikie wanafunzi wengi zaidi kupitia Karakana.',
                                    style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: AppColors.textTertiary),
                                  ),
                                  const SizedBox(height: 14),
                                  FilledButton(
                                    onPressed: () => context.push('/trainer/apply'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: Text('Jiunge Kama Mwalimu', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(22)),
                              child: Icon(Icons.school_rounded, size: 42, color: AppColors.primary.withValues(alpha: 0.75)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _courseStrip(List<CourseModel> items, String empty) {
    if (items.isEmpty) return _empty(empty);
    return SizedBox(
      height: 236,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: SizedBox(
            width: 208,
            child: CourseCardHorizontal(
              course: items[i],
              onTap: () => context.push('/course/${items[i].id}'),
              onWishlistTap: () => context.read<CourseProvider>().toggleWishlist(items[i].id),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
      ),
    );
  }

  Widget _shimmer() {
    return SizedBox(
      height: 236,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(right: 12),
          child: ShimmerCard(width: 208, height: 236),
        ),
      ),
    );
  }
}


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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
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
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTapAll;

  const _SectionHeader({required this.title, this.subtitle, this.onTapAll});

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
            GestureDetector(
              onTap: onTapAll,
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
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              final banner = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      banner.image != null
                          ? CachedNetworkImage(imageUrl: banner.image!, fit: BoxFit.cover, errorWidget: (_, __, ___) => _fallback())
                          : _fallback(),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.58)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
                              child: Text('Kipengele cha wiki', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              banner.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 22, height: 1.08, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentIndex == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(color: _currentIndex == i ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF3B1A08), Color(0xFFC4620A)]),
        ),
      );
}
