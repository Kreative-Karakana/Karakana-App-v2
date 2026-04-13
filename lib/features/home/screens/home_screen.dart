
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

  IconData _getTimeIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.light_mode_outlined;
    if (hour < 17) return Icons.wb_sunny_outlined;
    if (hour < 21) return Icons.wb_twilight_outlined;
    return Icons.bedtime_outlined;
  }

  String _getTagline() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Siku nzuri ya kujifunza na kukua';
    if (hour < 17) return 'Endelea na safari yako ya maarifa';
    if (hour < 21) return 'Angalia mafanikio ya masomo ya leo';
    return 'Pitia masomo — kesho inaanza sasa';
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
                  expandedHeight: 220,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  centerTitle: false,
                  titleSpacing: 16,
                  backgroundColor: AppColors.primaryDark,
                  surfaceTintColor: Colors.transparent,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
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
                                  fontSize: 15,
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
                          fontSize: 22,
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
                          colors: [Color(0xFF2A1106), Color(0xFF5C2208), Color(0xFFB5540A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Top-right large decorative circle
                          Positioned(
                            top: -60,
                            right: -40,
                            child: Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.04),
                              ),
                            ),
                          ),
                          // Mid-right accent circle
                          Positioned(
                            top: 40,
                            right: 60,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                          // Bottom-left decorative circle
                          Positioned(
                            bottom: -30,
                            left: -30,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.03),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 58, 20, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── Time-aware greeting ──
                                Row(
                                  children: [
                                    Icon(
                                      _getTimeIcon(),
                                      color: Colors.white.withValues(alpha: 0.5),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getGreeting(),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.55),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // ── Name ──
                                Text(
                                  _getFirstName(auth),
                                  style: GoogleFonts.poppins(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.1,
                                    shadows: [
                                      Shadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // ── Tagline ──
                                Text(
                                  _getTagline(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.42),
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // ── Search bar ──
                                GestureDetector(
                                  onTap: () => context.push('/explore'),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 14),
                                        Icon(
                                          Icons.search_rounded,
                                          color: Colors.white.withValues(alpha: 0.65),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Tafuta kozi, mada, mwalimu...',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.white.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.35),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 15),
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
                if (!courses.isLoading && courses.popularCourses.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _FeaturedCarousel(courses: courses.popularCourses),
                  ),
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
                          childAspectRatio: 0.78,
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
      height: 260,
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
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(right: 12),
          child: ShimmerCard(width: 208, height: 260),
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

class _FeaturedCarousel extends StatefulWidget {
  final List<CourseModel> courses;
  const _FeaturedCarousel({required this.courses});

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
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

  List<CourseModel> get _items => widget.courses.take(4).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => _FeaturedCard(
              course: _items[i],
              onTap: () => context.push('/course/${_items[i].id}'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _items.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentIndex == i ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentIndex == i ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _FeaturedCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tag = course.categories.isNotEmpty ? course.categories.first : course.formattedLevel;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background image or colour ──
              if (course.coverPhoto != null)
                CachedNetworkImage(
                  imageUrl: course.coverPhoto!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _colorBg(course.id),
                )
              else
                _colorBg(course.id),

              // ── Gradient overlay: top fade + heavy bottom ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.25, 0.65, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // ── Content ──
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tag + price row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            course.formattedPrice,
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    // Title
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Trainer + rating row
                    Row(
                      children: [
                        if (course.trainerAvatar != null) ...[
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: course.trainerAvatar!,
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _avatarFallback(),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ] else ...[
                          _avatarFallback(),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            course.trainerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.star_rounded, size: 12, color: Colors.amber.shade300),
                        const SizedBox(width: 3),
                        Text(
                          course.averageRating > 0 ? course.averageRating.toStringAsFixed(1) : 'Mpya',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white.withValues(alpha: 0.75)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorBg(int seed) {
    final colors = [
      [const Color(0xFF1A3A5C), const Color(0xFF2E6DA4)],
      [const Color(0xFF1F3D1A), const Color(0xFF3A7A30)],
      [const Color(0xFF3B1A08), const Color(0xFFC4620A)],
      [const Color(0xFF2A0A3A), const Color(0xFF7B3FA0)],
    ];
    final pair = colors[seed % colors.length];
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: pair, begin: Alignment.topLeft, end: Alignment.bottomRight)),
    );
  }

  Widget _avatarFallback() => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.6), shape: BoxShape.circle),
        child: const Icon(Icons.person_rounded, size: 12, color: Colors.white),
      );
}
