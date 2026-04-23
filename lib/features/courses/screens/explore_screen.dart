import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/cards/course_card_list.dart';
import '../../../widgets/cards/shimmer_card.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController =
      TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryName;
  Timer? _debounceTimer;
  String _sortBy = 'default';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseProvider>();
      provider.loadCourses();
      provider.loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value);
      context.read<CourseProvider>().searchCourses(value);
    });
  }

  void _selectCategory(String? name) {
    setState(() => _selectedCategoryName = name);
    context.read<CourseProvider>().filterByCategory(name);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<CourseProvider>();

    final displayCourses = _sortedCourses(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Gradient header ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Decorative circles
                Positioned(
                  top: -50,
                  right: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  top: 30,
                  right: 50,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 18,
                    20,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tafuta',
                        style: GoogleFonts.montserrat(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gundua kozi yako inayofuata',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search bar inside header
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tafuta kozi yoyote...',
                          hintStyle: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      size: 18,
                                      color: AppColors.textTertiary),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Filters ────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                // Category chips
                if (provider.categories.isNotEmpty)
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.categories.length + 1,
                      itemBuilder: (_, i) {
                        final isAll = i == 0;
                        final catName = isAll
                            ? null
                            : provider.categories[i - 1].name;
                        final isSelected = _selectedCategoryName ==
                            catName;
                        return GestureDetector(
                          onTap: () => _selectCategory(catName),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              isAll
                                  ? 'Zote'
                                  : provider
                                      .categories[i - 1].name,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),

                // Count + sort row
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${displayCourses.length} Kozi Zimepatikana',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) =>
                          setState(() => _sortBy = val),
                      icon: const Icon(Icons.sort,
                          color: AppColors.primary, size: 20),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'default',
                            child: Text('Default')),
                        const PopupMenuItem(
                            value: 'rating',
                            child: Text('Ukadiriaji Juu')),
                        const PopupMenuItem(
                            value: 'price_asc',
                            child: Text('Bei: Chini → Juu')),
                        const PopupMenuItem(
                            value: 'price_desc',
                            child: Text('Bei: Juu → Chini')),
                        const PopupMenuItem(
                            value: 'title_az',
                            child: Text('Jina A → Z')),
                      ],
                    ),
                  ],
                ),
                const Divider(
                  color: AppColors.divider,
                  height: 1,
                  thickness: 1,
                ),
              ],
            ),
          ),

          // ── Results list ───────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? ListView.builder(
                    itemCount: 6,
                    padding: const EdgeInsets.all(20),
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: ShimmerCard(
                          width: double.infinity, height: 96),
                    ),
                  )
                : displayCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: AppColors.border,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Kozi haikupatikana',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Jaribu maneno mengine ya utafutaji',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildResultsList(context, provider, displayCourses),
          ),
        ],
      ),
    );
  }

  bool get _isIdle => _searchQuery.isEmpty && _selectedCategoryName == null;

  Widget _buildResultsList(
    BuildContext context,
    CourseProvider provider,
    List displayCourses,
  ) {
    final popular = provider.popularCourses;
    final showCarousel = _isIdle && popular.isNotEmpty;
    final itemCount = displayCourses.length + (showCarousel ? 1 : 0);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, showCarousel ? 0 : 20, 20, MediaQuery.of(context).padding.bottom + 16),
      itemCount: itemCount,
      itemBuilder: (_, i) {
        if (showCarousel && i == 0) {
          return _ExploreCarousel(
            courses: popular,
            onTap: (course) => context.push('/course/${course.id}'),
          );
        }
        final course = displayCourses[showCarousel ? i - 1 : i] as CourseModel;
        return CourseListCard(
          course: course,
          onTap: () => context.push('/course/${course.id}'),
        );
      },
    );
  }

  List _sortedCourses(CourseProvider provider) {
    final list = List.of(provider.courses);
    switch (_sortBy) {
      case 'rating':
        list.sort(
            (a, b) => b.averageRating.compareTo(a.averageRating));
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
      case 'title_az':
        list.sort((a, b) => a.title.compareTo(b.title));
    }
    return list;
  }
}

// ── Popular courses carousel for the explore / tafuta page ─────────────────

class _ExploreCarousel extends StatefulWidget {
  final List<CourseModel> courses;
  final void Function(CourseModel) onTap;

  const _ExploreCarousel({required this.courses, required this.onTap});

  @override
  State<_ExploreCarousel> createState() => _ExploreCarouselState();
}

class _ExploreCarouselState extends State<_ExploreCarousel> {
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

  List<CourseModel> get _items => widget.courses.take(5).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maarufu Sasa',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Kozi zinazovuma',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.push('/courses/list',
                    extra: {'type': 'popular', 'title': 'Maarufu Sasa'}),
                child: Text(
                  'Tazama Zote →',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => _FeaturedCard(
              course: _items[i],
              onTap: () => widget.onTap(_items[i]),
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
                color: _currentIndex == i
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Kozi Zote',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
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
    final tag = course.categories.isNotEmpty
        ? course.categories.first
        : course.formattedLevel;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (course.coverPhoto != null)
                CachedNetworkImage(
                  imageUrl: course.coverPhoto!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _colorBg(course.id),
                )
              else
                _colorBg(course.id),
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
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            course.formattedPrice,
                            style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8)
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.star_rounded,
                            size: 12, color: Colors.amber.shade300),
                        const SizedBox(width: 3),
                        Text(
                          course.averageRating > 0
                              ? course.averageRating.toStringAsFixed(1)
                              : 'Mpya',
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85)),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.75)),
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
    const colorPairs = [
      [Color(0xFF1A3A5C), Color(0xFF2E6DA4)],
      [Color(0xFF1F3D1A), Color(0xFF3A7A30)],
      [Color(0xFF3D1800), Color(0xFFE87722)],
      [Color(0xFF2A0A3A), Color(0xFF7B3FA0)],
    ];
    final pair = colorPairs[seed % colorPairs.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: pair,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.6),
            shape: BoxShape.circle),
        child: const Icon(Icons.person_rounded, size: 12, color: Colors.white),
      );
}
