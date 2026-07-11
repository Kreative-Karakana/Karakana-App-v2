import '../../../core/network/api_client.dart';
import '../models/course_model.dart';

class PaginatedCourses {
  final List<CourseModel> items;
  final int count;
  final String? next;
  final String? previous;

  const PaginatedCourses({
    required this.items,
    required this.count,
    required this.next,
    required this.previous,
  });

  bool get hasNext => next != null && next!.isNotEmpty;

  factory PaginatedCourses.fromJson(dynamic data) {
    if (data is Map) {
      final results = data['results'];
      final items = results is List ? results : const [];
      return PaginatedCourses(
        items: items
            .map((j) => CourseModel.fromJson(j as Map<String, dynamic>))
            .toList(),
        count: data['count'] is int ? data['count'] as int : items.length,
        next: data['next']?.toString(),
        previous: data['previous']?.toString(),
      );
    }

    final items = data is List ? data : const [];
    return PaginatedCourses(
      items: items
          .map((j) => CourseModel.fromJson(j as Map<String, dynamic>))
          .toList(),
      count: items.length,
      next: null,
      previous: null,
    );
  }
}

abstract class CourseCatalogService {
  Future<PaginatedCourses> getCoursesPage({
    String? search,
    String? categoryName,
    bool? recommended,
    bool? popular,
    bool? free,
    bool? weeklyChoice,
    bool? enrolled,
    int page = 1,
    int pageSize = 20,
  });

  Future<List<CourseModel>> getCourses({
    String? search,
    String? categoryName,
    bool? recommended,
    bool? popular,
    bool? free,
    bool? weeklyChoice,
    bool? enrolled,
    int pageSize = 20,
  });

  Future<CourseModel> getCourseDetail(int id);
  Future<List<CategoryModel>> getCategories();
  Future<List<SectionModel>> getCourseSections(int courseId);
  Future<bool> toggleLessonProgress(int lessonId);
  Future<bool> enrollFreeCourse(int courseId);
  Future<bool> toggleWishlist(int courseId);
  Future<List<ReviewModel>> getCourseReviews(int courseId);
  Future<List<BannerModel>> getBanners();
}

class CourseService implements CourseCatalogService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  final _dio = ApiClient().dio;

  @override
  Future<PaginatedCourses> getCoursesPage({
    String? search,
    String? categoryName,
    bool? recommended,
    bool? popular,
    bool? free,
    bool? weeklyChoice,
    bool? enrolled,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'page_size': pageSize};
      if (search != null && search.isNotEmpty) params['q'] = search;
      if (categoryName != null && categoryName.isNotEmpty) {
        params['categories__name'] = categoryName;
      }
      if (recommended == true) params['recommend'] = true;
      if (popular == true) params['popular'] = true;
      if (free == true) params['free'] = true;
      if (weeklyChoice == true) params['weekly_choice'] = true;
      if (enrolled == true) params['enrolled'] = true;

      final response =
          await _dio.get('/api/v1/courses/', queryParameters: params);
      return PaginatedCourses.fromJson(response.data);
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  @override
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
    final page = await getCoursesPage(
      search: search,
      categoryName: categoryName,
      recommended: recommended,
      popular: popular,
      free: free,
      weeklyChoice: weeklyChoice,
      enrolled: enrolled,
      pageSize: pageSize,
    );
    return page.items;
  }

  @override
  Future<CourseModel> getCourseDetail(int id) async {
    try {
      final response = await _dio.get('/api/v1/courses/$id/');
      return CourseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  @override
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

  @override
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

  @override
  Future<bool> toggleLessonProgress(int lessonId) async {
    try {
      final response = await _dio.post('/api/v1/lessons/$lessonId/progress/');
      return response.data['is_completed'] ?? response.data['is_read'] ?? false;
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  @override
  Future<bool> enrollFreeCourse(int courseId) async {
    try {
      await _dio.post('/api/v1/courses/enroll/', data: {'course_id': courseId});
      return true;
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  @override
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

  @override
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

  @override
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
