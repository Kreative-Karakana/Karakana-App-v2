import '../../../core/network/api_client.dart';
import '../models/course_model.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  final _dio = ApiClient().dio;

  Future<List<CourseModel>> getCourses({
    String? search,
    String? categoryName,
    bool? recommended,
    bool? popular,
    bool? free,
    bool? weeklyChoice,
    bool? enrolled,
  }) async {
    try {
      final params = <String, dynamic>{'page_size': 20};
      if (search != null && search.isNotEmpty) params['q'] = search;
      if (categoryName != null) params['categories__name'] = categoryName;
      if (recommended == true) params['recommend'] = true;
      if (popular == true) params['popular'] = true;
      if (free == true) params['free'] = true;
      if (weeklyChoice == true) params['weekly_choice'] = true;
      if (enrolled == true) params['enrolled'] = true;

      final response =
          await _dio.get('/api/v1/courses/', queryParameters: params);
      final data = response.data;
      final results = data is Map ? (data['results'] ?? []) : data;
      return (results as List)
          .map((j) => CourseModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  Future<CourseModel> getCourseDetail(int id) async {
    try {
      final response = await _dio.get('/api/v1/courses/$id/');
      return CourseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get('/api/v1/categories/');
      final data = response.data;
      final list = data is Map ? (data['results'] ?? data) : data;
      return (list as List)
          .map((j) => CategoryModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  Future<List<SectionModel>> getCourseSections(int courseId) async {
    try {
      final response = await _dio.get('/api/v1/courses/$courseId/sections/');
      final data = response.data;
      final list =
          data is Map ? (data['results'] ?? data['sections'] ?? []) : data;
      return (list as List)
          .map((j) => SectionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  Future<bool> toggleLessonProgress(int lessonId) async {
    try {
      final response = await _dio.post('/api/v1/lessons/$lessonId/progress/');
      return response.data['is_completed'] ?? response.data['is_read'] ?? false;
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  Future<bool> enrollFreeCourse(int courseId) async {
    try {
      await _dio.post('/api/v1/courses/enroll/', data: {'course_id': courseId});
      return true;
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  Future<bool> toggleWishlist(int courseId) async {
    try {
      final response = await _dio.post(
        '/api/v1/wishlist/',
        data: {'course_id': courseId},
      );
      return response.data['is_wishlisted'] ?? false;
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  Future<List<ReviewModel>> getCourseReviews(int courseId) async {
    try {
      final response = await _dio.get('/api/v1/courses/$courseId/reviews/');
      final data = response.data;
      final list = data is Map ? (data['results'] ?? []) : data;
      return (list as List)
          .map((j) => ReviewModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await _dio.get('/api/v1/communications/banners/');
      final data = response.data;
      final list = data is Map ? (data['results'] ?? []) : data;
      return (list as List)
          .map((j) => BannerModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
