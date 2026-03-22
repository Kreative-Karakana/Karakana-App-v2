import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/course_model.dart';
import '../../../widgets/course_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoading = true;
  String? _error;
  List<CourseModel> _courses = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get('/api/v1/wishlist/');
      final data = response.data;

      List<dynamic> raw;
      if (data is List) {
        raw = data;
      } else if (data is Map && data.containsKey('results')) {
        raw = data['results'] as List<dynamic>? ?? [];
      } else {
        raw = [];
      }

      // Each wishlist item has a nested 'course' object.
      // Fall back to treating the item itself as the course if no 'course' key.
      final courses = raw.map((item) {
        final courseJson = (item is Map<String, dynamic> && item.containsKey('course'))
            ? item['course'] as Map<String, dynamic>
            : item as Map<String, dynamic>;
        return CourseModel.fromJson(courseJson);
      }).toList();

      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromWishlist(int courseId) async {
    try {
      final dio = ApiClient.instance.dio;
      await dio.post('/api/v1/wishlist/', data: {'course': courseId});
      // Optimistically remove from list, then refresh to sync server state.
      setState(() {
        _courses.removeWhere((c) => c.id == courseId);
      });
    } catch (_) {
      // Silently ignore — list stays as-is, user can refresh.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'My Wishlist',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.dark),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetch,
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

    if (_courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 80,
                color: AppColors.lightOrange,
              ),
              const SizedBox(height: 16),
              Text(
                'Your wishlist is empty',
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Save courses you want to take later',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Browse Courses',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetch,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '${_courses.length} saved ${_courses.length == 1 ? 'course' : 'courses'}',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final course = _courses[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CourseCard(
                      course: course,
                      onTap: () => context.push('/courses/${course.id}'),
                      onWishlistTap: () => _removeFromWishlist(course.id),
                    ),
                  );
                },
                childCount: _courses.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
