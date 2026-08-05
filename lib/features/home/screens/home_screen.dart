import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../widgets/cards/course_card_horizontal.dart';
import '../../../widgets/cards/shimmer_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../courses/models/course_model.dart';
import '../../courses/providers/course_provider.dart';
import '../../fursa/models/fursa_item.dart';
import '../../fursa/providers/fursa_provider.dart';
import '../../fursa/widgets/fursa_thumbnail.dart';
import '../../notifications/providers/notification_provider.dart';
import '../widgets/ambassador_code_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _banners = [];
  Timer? _notificationsPollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadHomeData();
      context.read<FursaProvider>().loadItems();
      context
          .read<NotificationProvider>()
          .loadNotifications(isTrainer: context.read<AuthProvider>().isTrainer);
      checkAndShowAmbassadorCode(context);
      // Temporarily hidden per request: "Fomu ya Taarifa" auto-popup on login.
      // Re-enable later by restoring this call.
      // checkAndPromptMastercard(context);
      _loadBanners();
      _notificationsPollingTimer?.cancel();
      _notificationsPollingTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) {
          if (mounted) {
            context.read<NotificationProvider>().loadNotifications(
                  isTrainer: context.read<AuthProvider>().isTrainer,
                );
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _notificationsPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final res = await ApiClient().dio.get('/api/v1/communications/banners/');
      final data = res.data;
      final rawList = data is Map
          ? (data['results'] as List? ?? const [])
          : (data as List? ?? const []);
      if (!mounted) return;
      setState(() {
        _banners = rawList
            .whereType<Map>()
            .map((b) => Map<String, dynamic>.from(b))
            .toList();
      });
    } catch (_) {}
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer4<CourseProvider, AuthProvider, NotificationProvider,
          FursaProvider>(
        builder: (context, courses, auth, notifications, fursa, _) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => Future.wait([
              context.read<CourseProvider>().loadHomeData(),
              context.read<FursaProvider>().loadItems(),
            ]),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHomeAppBar(auth, notifications),
                if (_banners.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _BannerCarousel(banners: _banners),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: GestureDetector(
                      onTap: () => context.go('/home?tab=2'),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1A0A00),
                              Color(0xFF3D1800),
                              Color(0xFF7B3A10)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3D1800)
                                  .withValues(alpha: 0.18),
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
                              child: const Icon(Icons.construction_outlined,
                                  color: Colors.white, size: 30),
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
                                        style: GoogleFonts.montserrat(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius:
                                                BorderRadius.circular(999)),
                                        child: Text(
                                          'MPYA',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AppStrings.zanaCardDescription,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        height: 1.45,
                                        color: Colors.white
                                            .withValues(alpha: 0.82)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (courses.isLoading) ...[
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: _shimmer())),
                  SliverToBoxAdapter(child: _shimmer()),
                ] else ...[
                  SliverToBoxAdapter(
                      child: _SectionHeader(
                          title: 'Kwako',
                          subtitle: 'Mapendekezo ya leo',
                          onTapAll: () => context.push('/courses/list', extra: {
                                'type': 'recommended',
                                'title': 'Kwako'
                              }))),
                  SliverToBoxAdapter(
                      child: _courseStrip(courses.recommendedCourses,
                          'Hakuna kozi zilizopendekezwa kwa sasa')),
                  SliverToBoxAdapter(
                      child: _SectionHeader(
                          title: 'Maarufu Sasa',
                          subtitle: 'Kozi zinazovuma',
                          onTapAll: () => context.push('/courses/list', extra: {
                                'type': 'popular',
                                'title': 'Maarufu Sasa'
                              }))),
                  SliverToBoxAdapter(
                      child: _courseStrip(courses.popularCourses,
                          'Hakuna kozi maarufu kwa sasa')),
                  SliverToBoxAdapter(
                      child: _SectionHeader(
                          title: 'Fursa',
                          subtitle: 'Angalia nafasi mpya leo',
                          onTapAll: () => context.go('/home?tab=3'))),
                  if (fursa.isLoading)
                    SliverToBoxAdapter(child: _fursaShimmer())
                  else if (fursa.items.isEmpty)
                    SliverToBoxAdapter(
                      child: _empty(
                        'Hakuna fursa mpya kwa sasa. Tafadhali rudi baadaye.',
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: _fursaStrip(_homeFursaItems(fursa.items)),
                    ),
                  if (!auth.isTrainer)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          AppSpacing.lg,
                          20,
                          AppSpacing.sm,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1A0A00),
                                Color(0xFF3D1800),
                                Color(0xFF7B3A10)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3D1800)
                                    .withValues(alpha: 0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
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
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Geuza uzoefu wako wa biashara kuwa kozi na ufikie wanafunzi wengi zaidi kupitia Karakana.',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        height: 1.45,
                                        color: Colors.white
                                            .withValues(alpha: 0.82),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    FilledButton(
                                      onPressed: () =>
                                          context.push('/trainer/apply'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                      ),
                                      child: Text('Jiunge Kama Mkufunzi',
                                          style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  size: 42,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).padding.bottom + AppSpacing.md,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeAppBar(
    AuthProvider auth,
    NotificationProvider notifications,
  ) {
    return SliverAppBar(
      toolbarHeight: 56,
      expandedHeight: 258,
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      backgroundColor: const Color(0xFF201008),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleSpacing: 0,
      centerTitle: false,
      title: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHomeLogo(size: 34, fallbackFontSize: 13),
            const SizedBox(width: 10),
            Text(
              'Karakana',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Builder(
          builder: (context) {
            final themeProvider = context.watch<ThemeProvider>();
            return _HomeHeaderIconButton(
              icon: themeProvider.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              onTap: () => context.read<ThemeProvider>().toggleTheme(),
            );
          },
        ),
        const SizedBox(width: AppSpacing.xs),
        _HomeNotificationAction(
          unreadCount: notifications.unreadCount,
          onTap: () async {
            await context.read<NotificationProvider>().loadNotifications(
                  isTrainer: context.read<AuthProvider>().isTrainer,
                );
            if (!mounted) return;
            context.push('/notifications');
          },
        ),
        const SizedBox(width: AppSpacing.xs),
        _HomeAvatarAction(
          avatarUrl: auth.userAvatar,
          initial: _getFirstName(auth).isNotEmpty
              ? _getFirstName(auth)[0].toUpperCase()
              : 'K',
          onTap: () => context.go('/home?tab=4'),
        ),
        const SizedBox(width: AppSpacing.md),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF201008),
              Color(0xFF4B2412),
              Color(0xFF9A4E1D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final statusBarHeight = MediaQuery.paddingOf(context).top;
            final heroOpacity =
                ((height - 100.0) / (190.0 - 100.0)).clamp(0.0, 1.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -36,
                  left: -18,
                  child: _buildHomeHeroGlow(
                    130,
                    Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Positioned(
                  right: -36,
                  bottom: -44,
                  child: _buildHomeHeroGlow(
                    170,
                    const Color(0xFFFFD1A1).withValues(alpha: 0.06),
                  ),
                ),
                Positioned(
                  right: 22,
                  top: 76,
                  child: Opacity(
                    opacity: 0.04,
                    child: Image.asset(
                      'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                      width: 110,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (heroOpacity > 0)
                  ClipRect(
                    child: Opacity(
                      opacity: heroOpacity,
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        maxHeight: double.infinity,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            statusBarHeight + 56 + AppSpacing.sm,
                            AppSpacing.lg,
                            0,
                          ),
                          child: _HomeHeroContent(
                            greeting: _getGreeting(),
                            timeIcon: _getTimeIcon(),
                            firstName: _getFirstName(auth),
                            tagline: _getTagline(),
                            onSearchTap: () => context.push('/explore'),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHomeLogo({
    required double size,
    required double fallbackFontSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              'K',
              style: GoogleFonts.montserrat(
                fontSize: fallbackFontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeHeroGlow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 42,
            spreadRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _courseStrip(List<CourseModel> items, String empty) {
    if (items.isEmpty) return _empty(empty);
    return SizedBox(
      height: 208,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenPadding,
        itemCount: items.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: SizedBox(
            width: 208,
            child: CourseCardHorizontal(
              course: items[i],
              onTap: () => context.push('/course/${items[i].id}'),
              onWishlistTap: () =>
                  context.read<CourseProvider>().toggleWishlist(items[i].id),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fursaStrip(List<FursaItem> items) {
    return SizedBox(
      height: 112,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenPadding,
        itemCount: items.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: SizedBox(
            width: 230,
            child: _HomeFursaCard(
              item: items[i],
              onTap: () => context.go('/home?tab=3'),
            ),
          ),
        ),
      ),
    );
  }

  List<FursaItem> _homeFursaItems(List<FursaItem> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      final aDate = a.parsedDeadline;
      final bDate = b.parsedDeadline;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return sorted.take(3).toList();
  }

  Widget _empty(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white12 : AppColors.border),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                fontSize: 13, color: AppColors.textTertiary)),
      ),
    );
  }

  Widget _fursaShimmer() {
    return SizedBox(
      height: 112,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenPadding,
        itemCount: 2,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(right: 12),
          child: ShimmerCard(width: 230, height: 112),
        ),
      ),
    );
  }

  Widget _shimmer() {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenPadding,
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.h4.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      const Color(0xFF1A0A00),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTextStyles.bodySmall.copyWith(
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
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeFursaCard extends StatelessWidget {
  final FursaItem item;
  final VoidCallback onTap;

  const _HomeFursaCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = item.deadlineText.isNotEmpty
        ? 'Deadline: ${item.deadlineText}'
        : item.category;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFFFE5CC),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: FursaThumbnail(
                    imageUrl: item.imageUrl,
                    semanticLabel: item.title,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label.isNotEmpty)
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFFE87722),
                          ),
                        ),
                      if (label.isNotEmpty) const SizedBox(height: 4),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeroContent extends StatelessWidget {
  const _HomeHeroContent({
    required this.greeting,
    required this.timeIcon,
    required this.firstName,
    required this.tagline,
    required this.onSearchTap,
  });

  final String greeting;
  final IconData timeIcon;
  final String firstName;
  final String tagline;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              timeIcon,
              color: Colors.white.withValues(alpha: 0.5),
              size: 13,
            ),
            const SizedBox(width: 6),
            Text(
              greeting,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.55),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          firstName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          tagline,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.42),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: onSearchTap,
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
                    'Tafuta kozi, mada, Mkufunzi...',
                    style: GoogleFonts.montserrat(
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
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeaderIconButton extends StatelessWidget {
  const _HomeHeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
      ),
    );
  }
}

class _HomeNotificationAction extends StatelessWidget {
  const _HomeNotificationAction({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _HomeHeaderIconButton(
          icon: Icons.notifications_outlined,
          onTap: onTap,
        ),
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeAvatarAction extends StatelessWidget {
  const _HomeAvatarAction({
    required this.avatarUrl,
    required this.initial,
    required this.onTap,
  });

  final String? avatarUrl;
  final String initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: avatarUrl != null
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: AppColors.primary,
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
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
    _controller = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              final banner = banners[i];
              final imageUrl = banner['image'] as String? ??
                  banner['image_url'] as String? ??
                  banner['photo'] as String?;
              final link =
                  banner['link'] as String? ?? banner['url'] as String?;
              final title = banner['title'] as String?;

              return GestureDetector(
                onTap: link != null
                    ? () {
                        final uri = Uri.tryParse(link);
                        if (uri != null) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) => Container(
                              color: Theme.of(context).cardColor,
                            ),
                            errorWidget: (_, __, ___) =>
                                _bannerPlaceholder(context, title),
                          )
                        : _bannerPlaceholder(context, title),
                  ),
                ),
              );
            },
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentIndex == i ? 18 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _currentIndex == i
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _bannerPlaceholder(BuildContext context, String? title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
      child: Center(
        child: title != null
            ? Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D1800),
                ),
                textAlign: TextAlign.center,
              )
            : const Icon(Icons.image_outlined,
                color: Color(0xFFE8D5C8), size: 40),
      ),
    );
  }
}
