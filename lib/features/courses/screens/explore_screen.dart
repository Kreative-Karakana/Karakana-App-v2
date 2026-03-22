import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/course_card.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';

/// Explore tab — search, filter by category, and browse all courses.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

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
                _CategoryChipList(
                  categories: provider.categories,
                  selectedCategory: _selectedCategory,
                  onSelect: (name) {
                    setState(() => _selectedCategory = name);
                    context.read<CourseProvider>().filterByCategory(name);
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
// Category chip list
// ─────────────────────────────────────────────

class _CategoryChipList extends StatelessWidget {
  const _CategoryChipList({
    required this.categories,
    required this.selectedCategory,
    required this.onSelect,
  });

  final List<CategoryModel> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <_ChipItem>[
      const _ChipItem(name: null, label: 'All'),
      ...categories.map((c) => _ChipItem(name: c.name, label: c.name)),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = items[i];
          final isSelected = item.name == selectedCategory;

          return GestureDetector(
            onTap: () => onSelect(item.name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.lightOrange, width: 1.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.dark,
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Internal data class for a category chip item.
class _ChipItem {
  const _ChipItem({required this.name, required this.label});
  final String? name;
  final String label;
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

