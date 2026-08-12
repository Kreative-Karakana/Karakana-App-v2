import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/courses/models/course_model.dart';
import 'package:karakana_app/features/courses/providers/course_provider.dart';
import 'package:karakana_app/features/courses/services/course_service.dart';

void main() {
  group('PaginatedCourses', () {
    test('parses DRF paginated response metadata', () {
      final page = PaginatedCourses.fromJson({
        'count': 2,
        'next': 'https://example.test/api/v1/courses/?page=2',
        'previous': null,
        'results': [
          _courseJson(1, 'Course 1'),
          _courseJson(2, 'Course 2'),
        ],
      });

      expect(page.items.map((course) => course.id), [1, 2]);
      expect(page.count, 2);
      expect(page.hasNext, isTrue);
      expect(page.previous, isNull);
    });
  });

  group('CourseProvider pagination', () {
    test('loads the initial page and preserves pagination metadata', () async {
      final service = _FakeCourseService({
        const _PageRequest(page: 1):
            _page([_course(1), _course(2)], hasNext: true),
      });
      final provider = CourseProvider(service: service);

      await provider.loadCourses();

      expect(provider.courses.map((course) => course.id), [1, 2]);
      expect(provider.courseCount, 3);
      expect(provider.hasMoreCourses, isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('loads the next page and prevents duplicate courses', () async {
      final service = _FakeCourseService({
        const _PageRequest(page: 1):
            _page([_course(1), _course(2)], hasNext: true),
        const _PageRequest(page: 2): _page([_course(2), _course(3)]),
      });
      final provider = CourseProvider(service: service);

      await provider.loadCourses();
      await provider.loadMoreCourses();

      expect(provider.courses.map((course) => course.id), [1, 2, 3]);
      expect(provider.hasMoreCourses, isFalse);
    });

    test('refresh resets pagination to the first page', () async {
      final service = _FakeCourseService({
        const _PageRequest(page: 1): _page([_course(1)], hasNext: true),
        const _PageRequest(page: 2): _page([_course(2)]),
      });
      final provider = CourseProvider(service: service);

      await provider.loadCourses();
      await provider.loadMoreCourses();
      await provider.loadCourses();

      expect(provider.courses.map((course) => course.id), [1]);
      expect(service.requests.map((request) => request.page), [1, 2, 1]);
    });

    test('search resets pagination and keeps query for next page', () async {
      final service = _FakeCourseService({
        const _PageRequest(page: 1): _page([_course(1)], hasNext: true),
        const _PageRequest(page: 1, search: 'business'):
            _page([_course(10)], hasNext: true),
        const _PageRequest(page: 2, search: 'business'): _page([_course(11)]),
      });
      final provider = CourseProvider(service: service);

      await provider.loadCourses();
      await provider.searchCourses(' business ');
      await provider.loadMoreCourses();

      expect(provider.courses.map((course) => course.id), [10, 11]);
      expect(service.requests.last.search, 'business');
      expect(service.requests.last.page, 2);
    });

    test('category filter resets pagination and uses backend filter', () async {
      final service = _FakeCourseService({
        const _PageRequest(page: 1): _page([_course(1)], hasNext: true),
        const _PageRequest(page: 1, categoryName: 'Fedha'):
            _page([_course(20)], hasNext: true),
        const _PageRequest(page: 2, categoryName: 'Fedha'):
            _page([_course(21)]),
      });
      final provider = CourseProvider(service: service);

      await provider.loadCourses();
      await provider.filterByCategory('Fedha');
      await provider.loadMoreCourses();

      expect(provider.courses.map((course) => course.id), [20, 21]);
      expect(service.requests.last.categoryName, 'Fedha');
      expect(service.requests.last.page, 2);
    });

    test('load-more failure preserves loaded items and can retry', () async {
      final service = _FakeCourseService({
        const _PageRequest(page: 1): _page([_course(1)], hasNext: true),
        const _PageRequest(page: 2): _page([_course(2)]),
      })
        ..failOnceFor(const _PageRequest(page: 2));
      final provider = CourseProvider(service: service);

      await provider.loadCourses();
      await provider.loadMoreCourses();

      expect(provider.courses.map((course) => course.id), [1]);
      expect(provider.loadMoreErrorMessage, isNotNull);
      expect(provider.hasMoreCourses, isTrue);

      await provider.loadMoreCourses();

      expect(provider.courses.map((course) => course.id), [1, 2]);
      expect(provider.loadMoreErrorMessage, isNull);
    });
  });
}

PaginatedCourses _page(List<CourseModel> items, {bool hasNext = false}) {
  return PaginatedCourses(
    items: items,
    count: hasNext ? items.length + 1 : items.length,
    next: hasNext ? 'https://example.test/api/v1/courses/?page=2' : null,
    previous: null,
  );
}

CourseModel _course(int id) =>
    CourseModel.fromJson(_courseJson(id, 'Course $id'));

Map<String, dynamic> _courseJson(int id, String title) => {
      'id': id,
      'title': title,
      'excerpt': '',
      'description': '',
      'price': '0',
      'status': 'published',
      'level': 'BGN',
      'trainer': {'id': 1, 'first_name': 'Kara', 'last_name': 'Kana'},
      'student_count': 0,
      'average_rating': '0',
      'review_count': 0,
      'is_enrolled': false,
      'is_in_wishlist': false,
      'categories': const [],
      'faqs': const [],
    };

class _FakeCourseService implements CourseCatalogService {
  @override
  Future<Set<String>> getAppleRestoreProductIds() async => {};

  _FakeCourseService(this.pages);

  final Map<_PageRequest, PaginatedCourses> pages;
  final List<_PageRequest> requests = [];
  final Set<_PageRequest> _failOnce = {};

  void failOnceFor(_PageRequest request) => _failOnce.add(request);

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
    final request = _PageRequest(
      page: page,
      search: search == null || search.isEmpty ? null : search,
      categoryName:
          categoryName == null || categoryName.isEmpty ? null : categoryName,
    );
    requests.add(request);
    if (_failOnce.remove(request)) {
      throw Exception('Network failed');
    }
    final response = pages[request];
    if (response == null) {
      throw StateError('Unexpected request: $request');
    }
    return response;
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
  Future<List<BannerModel>> getBanners() => throw UnimplementedError();

  @override
  Future<List<CategoryModel>> getCategories() => throw UnimplementedError();

  @override
  Future<CourseModel> getCourseDetail(int id) => throw UnimplementedError();

  @override
  Future<List<ReviewModel>> getCourseReviews(int courseId) =>
      throw UnimplementedError();

  @override
  Future<List<SectionModel>> getCourseSections(int courseId) =>
      throw UnimplementedError();

  @override
  Future<bool> enrollFreeCourse(int courseId) => throw UnimplementedError();

  @override
  Future<bool> toggleLessonProgress(int lessonId) => throw UnimplementedError();

  @override
  Future<bool> toggleWishlist(int courseId) => throw UnimplementedError();
}

class _PageRequest {
  final int page;
  final String? search;
  final String? categoryName;

  const _PageRequest({required this.page, this.search, this.categoryName});

  @override
  bool operator ==(Object other) {
    return other is _PageRequest &&
        other.page == page &&
        other.search == search &&
        other.categoryName == categoryName;
  }

  @override
  int get hashCode => Object.hash(page, search, categoryName);

  @override
  String toString() {
    return '_PageRequest(page: $page, search: $search, category: $categoryName)';
  }
}
