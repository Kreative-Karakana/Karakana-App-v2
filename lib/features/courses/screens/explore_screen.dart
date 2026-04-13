import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/cards/course_card_list.dart';
import '../../../widgets/cards/shimmer_card.dart';
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
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gundua kozi yako inayofuata',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search bar inside header
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tafuta kozi yoyote...',
                          hintStyle: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Jaribu maneno mengine ya utafutaji',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: displayCourses.length,
                        itemBuilder: (_, i) => CourseListCard(
                          course: displayCourses[i],
                          onTap: () => context.push(
                              '/course/${displayCourses[i].id}'),
                        ),
                      ),
          ),
        ],
      ),
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
