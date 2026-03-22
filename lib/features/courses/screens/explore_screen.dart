import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/course_card.dart';
import '../providers/course_provider.dart';

/// Explore tab — search, filter by category, and browse all courses.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryName;

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
    super.dispose();
  }

  void _clearSearch(CourseProvider provider) {
    _searchController.clear();
    provider.searchCourses('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Explore',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Consumer<CourseProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search bar ─────────────────────────
              _SearchBar(
                controller: _searchController,
                onChanged: (v) => provider.searchCourses(v),
                onClear: () => _clearSearch(provider),
              ),

              // ── Category chips ──────────────────────
              if (provider.categories.isNotEmpty)
                Consumer<CourseProvider>(
                  builder: (context, courseProvider, _) {
                    return SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // All chip
                          GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategoryName = null);
                              context
                                  .read<CourseProvider>()
                                  .filterByCategory(null);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedCategoryName == null
                                    ? AppColors.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _selectedCategoryName == null
                                      ? AppColors.primary
                                      : AppColors.lightOrange,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'All',
                                style: TextStyle(
                                  color: _selectedCategoryName == null
                                      ? Colors.white
                                      : AppColors.dark,
                                  fontSize: 13,
                                  fontWeight: _selectedCategoryName == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          // Category chips
                          ...courseProvider.categories.map((category) {
                            final isSelected =
                                _selectedCategoryName == category.name;
                            return GestureDetector(
                              onTap: () {
                                setState(
                                  () =>
                                      _selectedCategoryName = category.name,
                                );
                                context
                                    .read<CourseProvider>()
                                    .filterByCategory(category.name);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.lightOrange,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.dark,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),

              // ── Results count ───────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  '${provider.courses.length} courses found',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Course list ─────────────────────────
              Expanded(child: _CourseListBody(provider: provider)),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: AppColors.dark, fontSize: 14),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.lightGrey,
          hintText: 'Search courses...',
          hintStyle: TextStyle(
            color: AppColors.grey,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.grey),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (_, _) {
              return controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.grey, size: 18),
                      onPressed: onClear,
                    )
                  : const SizedBox.shrink();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────
// Course list body
// ─────────────────────────────────────────────

class _CourseListBody extends StatelessWidget {
  const _CourseListBody({required this.provider});

  final CourseProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.errorMessage != null) {
      return _ErrorView(
        message: provider.errorMessage!,
        onRetry: () => provider.loadCourses(),
      );
    }

    if (provider.courses.isEmpty) {
      return const _EmptyView();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 16),
      itemCount: provider.courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final course = provider.courses[i];
        return CourseCard(
          course: course,
          onTap: () => context.push('/courses/${course.id}'),
          onWishlistTap: () => provider.toggleWishlist(course.id),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search or category',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 14,
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
// Error state
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

