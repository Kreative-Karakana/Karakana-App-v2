import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/course_model.dart';

/// Handles all API calls related to courses, categories, banners,
/// wishlists, enrolments, and reviews for the Karakana platform.
///
/// Uses the shared [ApiClient.instance] singleton internally.
class CourseService {
  CourseService._internal();

  static final CourseService _instance = CourseService._internal();

  /// The single shared instance of [CourseService].
  static CourseService get instance => _instance;

  final _dio = ApiClient.instance.dio;

  // ─────────────────────────────────────────────
  // Courses
  // ─────────────────────────────────────────────

  /// Returns a list of published courses with optional filters.
  ///
  /// [search] performs a text search, [categoryId] filters by category,
  /// and the boolean flags map to backend query parameters that select
  /// curated subsets: [recommended], [popular], [free], [weeklyChoice],
  /// and [enrolled]. A [pageSize] of 20 is always sent.
  Future<List<CourseModel>> getCourses({
    String? search,
    String? categoryName,
    bool? recommended,
    bool? popular,
    bool? free,
    bool? weeklyChoice,
    bool? enrolled,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page_size': pageSize};

      if (search != null && search.isNotEmpty) queryParams['q'] = search;
      if (categoryName != null) queryParams['categories__name'] = categoryName;
      if (recommended == true) queryParams['recommend'] = true;
      if (popular == true) queryParams['popular'] = true;
      if (free == true) queryParams['free'] = true;
      if (weeklyChoice == true) queryParams['weekly_choice'] = true;
      if (enrolled == true) queryParams['enrolled'] = true;

      final response = await _dio.get(
        ApiEndpoints.courses,
        queryParameters: queryParams,
      );

      return _parseList(response.data)
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns the full detail for a single course identified by [courseId].
  Future<CourseModel> getCourseDetail(int courseId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.courses}$courseId/');
      return CourseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw 'Failed to load course details. Please try again.';
    }
  }

  // ─────────────────────────────────────────────
  // Categories
  // ─────────────────────────────────────────────

  /// Returns all available course categories.
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get(ApiEndpoints.categories);
      return _parseList(response.data)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // Sections & Lessons
  // ─────────────────────────────────────────────

  /// Returns the ordered list of sections for [courseId].
  /// GET /api/v1/courses/{courseId}/sections/
  Future<List<SectionModel>> getCourseSections(int courseId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.sections}$courseId/sections/',
      );
      final results = response.data['results'] as List<dynamic>? ?? [];
      return results
          .map((e) => SectionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Failed to load course content. Please try again.';
    }
  }

  /// Returns the ordered list of lessons for [sectionId].
  /// GET /api/v1/sections/{sectionId}/lessons/
  Future<List<LessonModel>> getSectionLessons(int sectionId) async {
    try {
      final response = await _dio.get('/api/v1/sections/$sectionId/lessons/');
      final results = response.data['results'] as List<dynamic>? ?? [];
      return results
          .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Failed to load lessons. Please try again.';
    }
  }

  /// Returns the full detail for a single lesson identified by [lessonId].
  /// GET /api/v1/lessons/{lessonId}/
  Future<LessonModel> getLessonDetail(int lessonId) async {
    try {
      final response = await _dio.get('/api/v1/lessons/$lessonId/');
      return LessonModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw 'Failed to load lesson. Please try again.';
    }
  }

  /// Toggles the read/watched state of [lessonId] for the current user.
  /// POST /api/v1/lessons/{lessonId}/progress/
  ///
  /// Returns `true` if the lesson is now marked as read.
  Future<bool> toggleLessonProgress(int lessonId) async {
    try {
      final response = await _dio.post('/api/v1/lessons/$lessonId/progress/');
      return response.data['is_read'] as bool? ?? false;
    } catch (e) {
      throw 'Failed to update lesson progress. Please try again.';
    }
  }

  // ─────────────────────────────────────────────
  // Enrolment
  // ─────────────────────────────────────────────

  /// Enrols the current user in a free course identified by [courseId].
  ///
  /// Returns `true` on success. Throws a descriptive string on failure.
  Future<bool> enrollFreeCourse(int courseId) async {
    try {
      await _dio.post(ApiEndpoints.enrollFree, data: {'course': courseId});
      return true;
    } catch (e) {
      throw 'Failed to enrol in the course. Please try again.';
    }
  }

  // ─────────────────────────────────────────────
  // Wishlist
  // ─────────────────────────────────────────────

  /// Toggles the wishlist state of [courseId] for the current user.
  ///
  /// Returns `true` if the course is now wishlisted.
  Future<bool> toggleWishlist(int courseId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.wishlist,
        data: {'course': courseId},
      );
      return response.data['is_wishlisted'] as bool? ?? false;
    } catch (e) {
      throw 'Failed to update wishlist. Please try again.';
    }
  }

  // ─────────────────────────────────────────────
  // Reviews
  // ─────────────────────────────────────────────

  /// Returns all reviews for [courseId].
  /// GET /api/v1/courses/{courseId}/reviews/
  Future<List<ReviewModel>> getCourseReviews(int courseId) async {
    try {
      final response = await _dio.get('/api/v1/courses/$courseId/reviews/');
      final results = response.data['results'] as List<dynamic>? ?? [];
      return results
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Failed to load reviews. Please try again.';
    }
  }

  /// Submits a new review for [courseId] with the given [rating] (1–5)
  /// and [content] text.
  /// POST /api/v1/courses/{courseId}/reviews/
  ///
  /// Returns the created [ReviewModel].
  Future<ReviewModel> createReview(
    int courseId,
    int rating,
    String content,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/courses/$courseId/reviews/',
        data: {'rating': rating, 'content': content},
      );
      return ReviewModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw 'Failed to submit review. Please try again.';
    }
  }

  // ─────────────────────────────────────────────
  // Banners
  // ─────────────────────────────────────────────

  /// Returns all active promotional banners for the home / discovery screens.
  ///
  /// Never throws — any network or parsing error is caught and logged, and
  /// an empty list is returned so the home screen renders without banners.
  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await _dio.get(ApiEndpoints.banners);
      final data = response.data;

      if (data == null) return [];

      final List<dynamic> rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic> &&
          data.containsKey('results')) {
        rawList = data['results'] as List<dynamic>? ?? [];
      } else {
        return [];
      }

      // Parse each item individually so a single bad record does not drop
      // the entire banner list.
      final banners = <BannerModel>[];
      for (final item in rawList) {
        try {
          banners.add(BannerModel.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          debugPrint('[CourseService] Skipping invalid banner item: $e');
        }
      }
      return banners;
    } catch (e) {
      debugPrint('[CourseService] getBanners failed: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  /// Safely extracts a [List<dynamic>] from a response body that may be
  /// either a direct list or a paginated map containing a `results` key.
  ///
  /// Returns an empty list for any unrecognised shape.
  List<dynamic> _parseList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      return data['results'] as List<dynamic>? ?? [];
    }
    return [];
  }
}
