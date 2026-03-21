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

  /// Returns a list of published courses, optionally filtered by [search]
  /// text, [categoryId], and/or [ordering] field (e.g. '-created_at').
  Future<List<CourseModel>> getCourses({
    String? search,
    int? categoryId,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null) queryParams['category'] = categoryId;
      if (ordering != null && ordering.isNotEmpty) {
        queryParams['ordering'] = ordering;
      }

      final response = await _dio.get(
        ApiEndpoints.courses,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final results = response.data['results'] as List<dynamic>? ?? [];
      return results
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Failed to load courses. Please try again.';
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
      final results = response.data['results'] as List<dynamic>? ?? [];
      return results
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Failed to load categories. Please try again.';
    }
  }

  // ─────────────────────────────────────────────
  // Sections & Lessons
  // ─────────────────────────────────────────────

  /// Returns the ordered list of sections (with nested lessons) for [courseId].
  Future<List<SectionModel>> getCourseSections(int courseId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.sections,
        queryParameters: {'course': courseId},
      );
      final results = response.data['results'] as List<dynamic>? ?? [];
      return results
          .map((e) => SectionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Failed to load course content. Please try again.';
    }
  }

  /// Toggles the read/watched state of [lessonId] for the current user.
  ///
  /// Returns `true` if the lesson is now marked as read.
  Future<bool> toggleLessonProgress(int lessonId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.lessonProgress,
        data: {'lesson': lessonId},
      );
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

  /// Returns all reviews for the course identified by [courseId].
  Future<List<ReviewModel>> getCourseReviews(int courseId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.reviews,
        queryParameters: {'course': courseId},
      );
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
  ///
  /// Returns the created [ReviewModel].
  Future<ReviewModel> createReview(
    int courseId,
    int rating,
    String content,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.reviews,
        data: {'course': courseId, 'rating': rating, 'content': content},
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
  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await _dio.get(ApiEndpoints.banners);
      final results = response.data['results'] as List<dynamic>? ?? [];
      return results
          .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Failed to load banners. Please try again.';
    }
  }
}
