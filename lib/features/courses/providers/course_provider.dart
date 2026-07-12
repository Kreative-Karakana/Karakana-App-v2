import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../models/quiz_model.dart';
import '../services/course_service.dart';
import '../services/quiz_service.dart';

class CourseProvider extends ChangeNotifier {
  final CourseCatalogService _service;
  final QuizCatalogService _quizService;

  CourseProvider({CourseCatalogService? service, QuizCatalogService? quizService})
      : _service = service ?? CourseService(),
        _quizService = quizService ?? QuizService();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingDetail = false;
  String? _errorMessage;
  String? _loadMoreErrorMessage;
  String? _sectionsErrorMessage;
  String? _reviewsErrorMessage;

  List<CourseModel> _allCourses = [];
  List<CourseModel> _courses = [];
  List<CourseModel> _recommendedCourses = [];
  List<CourseModel> _popularCourses = [];
  List<CourseModel> _freeCourses = [];
  List<CourseModel> _weeklyChoiceCourses = [];
  List<CategoryModel> _categories = [];
  List<BannerModel> _banners = [];
  CourseModel? _selectedCourse;
  List<SectionModel> _sections = [];
  List<ReviewModel> _reviews = [];
  CertificateEligibility? _certificateEligibility;
  QuizAvailability? _quizAvailability;
  String? _selectedCategoryName;
  String _searchQuery = '';
  int _currentCoursePage = 0;
  int _courseCount = 0;
  bool _hasMoreCourses = false;
  static const int _coursePageSize = 20;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get errorMessage => _errorMessage;
  String? get loadMoreErrorMessage => _loadMoreErrorMessage;
  String? get sectionsErrorMessage => _sectionsErrorMessage;
  String? get reviewsErrorMessage => _reviewsErrorMessage;
  List<CourseModel> get allCourses => _allCourses;
  List<CourseModel> get courses => _courses;
  List<CourseModel> get recommendedCourses => _recommendedCourses;
  List<CourseModel> get popularCourses => _popularCourses;
  List<CourseModel> get freeCourses => _freeCourses;
  List<CourseModel> get weeklyChoiceCourses => _weeklyChoiceCourses;
  List<CategoryModel> get categories => _categories;
  List<BannerModel> get banners => _banners;
  CourseModel? get selectedCourse => _selectedCourse;
  List<SectionModel> get sections => _sections;
  List<ReviewModel> get reviews => _reviews;
  CertificateEligibility? get certificateEligibility => _certificateEligibility;
  QuizAvailability? get quizAvailability => _quizAvailability;
  String? get selectedCategoryName => _selectedCategoryName;
  String get searchQuery => _searchQuery;
  int get courseCount => _courseCount;
  bool get hasMoreCourses => _hasMoreCourses;

  List<CourseModel> get enrolledCourses =>
      _allCourses.where((c) => c.isEnrolled).toList();

  List<CourseModel> get wishlistedCourses =>
      _allCourses.where((c) => c.isWishlisted).toList();

  // ── Home ───────────────────────────────────────────────────────

  Future<void> loadHomeData() async {
    await Future.wait([
      loadBanners(),
      loadRecommended(),
      loadPopular(),
      loadFree(),
      loadWeeklyChoice(),
      loadCategories(),
    ]);
  }

  Future<void> loadBanners() async {
    try {
      _banners = await _service.getBanners();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadRecommended() async {
    try {
      _recommendedCourses =
          _shuffled(await _service.getCourses(recommended: true));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[CourseProvider] loadRecommended: $e');
    }
  }

  Future<void> loadPopular() async {
    try {
      _popularCourses = _shuffled(await _service.getCourses(popular: true));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[CourseProvider] loadPopular: $e');
    }
  }

  Future<void> loadFree() async {
    try {
      _freeCourses = _shuffled(await _service.getCourses(free: true));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[CourseProvider] loadFree: $e');
    }
  }

  Future<void> loadWeeklyChoice() async {
    try {
      _weeklyChoiceCourses =
          _shuffled(await _service.getCourses(weeklyChoice: true));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[CourseProvider] loadWeeklyChoice: $e');
    }
  }

  // ── Explore ────────────────────────────────────────────────────

  Future<void> loadCourses({String? search, String? categoryName}) async {
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _loadMoreErrorMessage = null;
    _currentCoursePage = 0;
    _courseCount = 0;
    _hasMoreCourses = false;
    notifyListeners();

    try {
      _searchQuery = (search ?? _searchQuery).trim();
      _selectedCategoryName = categoryName ?? _selectedCategoryName;
      final page = await _service.getCoursesPage(
        search: _searchQuery,
        categoryName: _selectedCategoryName,
        page: 1,
        pageSize: _coursePageSize,
      );
      _currentCoursePage = 1;
      _courseCount = page.count;
      _hasMoreCourses = page.hasNext;
      _courses = _dedupeCourses(page.items);
      if (_searchQuery.isEmpty && _selectedCategoryName == null) {
        _allCourses = List.from(_courses);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _courses = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreCourses() async {
    if (_isLoading || _isLoadingMore || !_hasMoreCourses) return;

    _isLoadingMore = true;
    _loadMoreErrorMessage = null;
    notifyListeners();

    try {
      final page = await _service.getCoursesPage(
        search: _searchQuery,
        categoryName: _selectedCategoryName,
        page: _currentCoursePage + 1,
        pageSize: _coursePageSize,
      );
      _currentCoursePage += 1;
      _courseCount = page.count;
      _hasMoreCourses = page.hasNext;
      _courses = _dedupeCourses([..._courses, ...page.items]);
      if (_searchQuery.isEmpty && _selectedCategoryName == null) {
        _allCourses = List.from(_courses);
      }
    } catch (e) {
      _loadMoreErrorMessage = e.toString();
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _service.getCategories();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[CourseProvider] loadCategories: $e');
    }
  }

  // ── Course detail ──────────────────────────────────────────────

  Future<void> loadCourseDetail(int id) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    _sectionsErrorMessage = null;
    _reviewsErrorMessage = null;
    _selectedCourse = null;
    _sections = [];
    _reviews = [];
    _certificateEligibility = null;
    _quizAvailability = null;
    notifyListeners();

    try {
      _selectedCourse = await _service.getCourseDetail(id);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingDetail = false;
      notifyListeners();
      return;
    }

    try {
      _sections = await _service.getCourseSections(id);
    } catch (e) {
      _sectionsErrorMessage = e.toString();
      if (kDebugMode) {
        debugPrint('[CourseProvider] loadCourseDetail sections: $e');
      }
      _sections = [];
    }

    try {
      _reviews = await _service.getCourseReviews(id);
    } catch (e) {
      _reviewsErrorMessage = e.toString();
      if (kDebugMode) {
        debugPrint('[CourseProvider] loadCourseDetail reviews: $e');
      }
      _reviews = [];
    }

    _isLoadingDetail = false;
    notifyListeners();

    // Certificate eligibility/quiz availability are backend-authoritative
    // reads used to gate the certificate button and show a final-quiz
    // card — loaded after the main detail so a slow/failing quiz backend
    // never blocks the classroom screen itself from rendering.
    unawaited(loadCertificateEligibility(id));
    unawaited(loadQuizAvailability(id));
  }

  Future<void> loadCertificateEligibility(int courseId) async {
    try {
      _certificateEligibility =
          await _quizService.getCertificateEligibility(courseId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CourseProvider] loadCertificateEligibility: $e');
      }
    }
  }

  Future<void> loadQuizAvailability(int courseId) async {
    try {
      _quizAvailability = await _quizService.getQuizAvailability(courseId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CourseProvider] loadQuizAvailability: $e');
      }
    }
  }

  // ── Search & filter ────────────────────────────────────────────

  Future<void> searchCourses(String query) async {
    final normalized = query.trim();
    _searchQuery = normalized;
    await loadCourses(search: normalized, categoryName: _selectedCategoryName);
  }

  Future<void> filterByCategory(String? categoryName) async {
    _selectedCategoryName = categoryName;
    await loadCourses(search: _searchQuery, categoryName: categoryName);
  }

  // ── Enroll / wishlist ──────────────────────────────────────────

  Future<bool> enrollFreeCourse(int courseId) async {
    try {
      final success = await _service.enrollFreeCourse(courseId);
      if (success) {
        _updateInAllLists(courseId, (c) => c.isEnrolled = true);
        if (_selectedCourse?.id == courseId) {
          _selectedCourse!.isEnrolled = true;
        }
        notifyListeners();
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleWishlist(int courseId) async {
    try {
      final isWishlisted = await _service.toggleWishlist(courseId);
      _updateInAllLists(courseId, (c) => c.isWishlisted = isWishlisted);
      if (_selectedCourse?.id == courseId) {
        _selectedCourse!.isWishlisted = isWishlisted;
      }
      notifyListeners();
      return isWishlisted;
    } catch (_) {
      return false;
    }
  }

  Future<bool?> toggleWishlistSafe(int courseId) async {
    try {
      final isWishlisted = await _service.toggleWishlist(courseId);
      _updateInAllLists(courseId, (c) => c.isWishlisted = isWishlisted);
      if (_selectedCourse?.id == courseId) {
        _selectedCourse!.isWishlisted = isWishlisted;
      }
      notifyListeners();
      return isWishlisted;
    } catch (_) {
      return null;
    }
  }

  Future<bool> toggleLessonProgress(int lessonId) async {
    try {
      final isRead = await _service.toggleLessonProgress(lessonId);
      for (final section in _sections) {
        for (final lesson in section.lessons) {
          if (lesson.id == lessonId) {
            lesson.isRead = isRead;
            notifyListeners();
            return isRead;
          }
        }
      }
      notifyListeners();
      return isRead;
    } catch (e) {
      if (kDebugMode) debugPrint('[CourseProvider] toggleLessonProgress: $e');
      return false;
    }
  }

  void _updateInAllLists(int courseId, void Function(CourseModel) update) {
    for (final list in [
      _allCourses,
      _courses,
      _recommendedCourses,
      _popularCourses,
      _freeCourses,
      _weeklyChoiceCourses,
    ]) {
      final idx = list.indexWhere((c) => c.id == courseId);
      if (idx != -1) update(list[idx]);
    }
  }

  void clearError() {
    _errorMessage = null;
    _loadMoreErrorMessage = null;
    notifyListeners();
  }

  List<CourseModel> _dedupeCourses(List<CourseModel> courses) {
    final seen = <int>{};
    return [
      for (final course in courses)
        if (seen.add(course.id)) course,
    ];
  }

  List<CourseModel> _shuffled(List<CourseModel> courses) {
    final shuffled = List<CourseModel>.from(courses);
    shuffled.shuffle();
    return shuffled;
  }
}
