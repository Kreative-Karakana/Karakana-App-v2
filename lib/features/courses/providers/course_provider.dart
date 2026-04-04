import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

class CourseProvider extends ChangeNotifier {
  final _service = CourseService();

  bool _isLoading = false;
  bool _isLoadingDetail = false;
  String? _errorMessage;
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
  String? _selectedCategoryName;
  String _searchQuery = '';

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get errorMessage => _errorMessage;
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
  String? get selectedCategoryName => _selectedCategoryName;
  String get searchQuery => _searchQuery;

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
          await _service.getCourses(recommended: true);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[CourseProvider] loadRecommended: $e');
    }
  }

  Future<void> loadPopular() async {
    try {
      _popularCourses = await _service.getCourses(popular: true);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[CourseProvider] loadPopular: $e');
    }
  }

  Future<void> loadFree() async {
    try {
      _freeCourses = await _service.getCourses(free: true);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[CourseProvider] loadFree: $e');
    }
  }

  Future<void> loadWeeklyChoice() async {
    try {
      _weeklyChoiceCourses =
          await _service.getCourses(weeklyChoice: true);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[CourseProvider] loadWeeklyChoice: $e');
    }
  }

  // ── Explore ────────────────────────────────────────────────────

  Future<void> loadCourses({String? search, String? categoryName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getCourses(search: search);
      _allCourses = result;
      _courses = List.from(result);
      if (categoryName != null) {
        _courses = _allCourses
            .where((c) => c.categories
                .any((cat) => cat.toLowerCase() == categoryName.toLowerCase()))
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
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
  }

  // ── Search & filter ────────────────────────────────────────────

  Future<void> searchCourses(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _courses = List.from(_allCourses);
      notifyListeners();
    } else {
      await loadCourses(search: query);
    }
  }

  void filterByCategory(String? categoryName) {
    _selectedCategoryName = categoryName;
    if (categoryName == null) {
      _courses = List.from(_allCourses);
    } else {
      _courses = _allCourses
          .where((c) => c.categories.any(
              (cat) => cat.toLowerCase() == categoryName.toLowerCase()))
          .toList();
    }
    notifyListeners();
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
      _updateInAllLists(
          courseId, (c) => c.isWishlisted = isWishlisted);
      if (_selectedCourse?.id == courseId) {
        _selectedCourse!.isWishlisted = isWishlisted;
      }
      notifyListeners();
      return isWishlisted;
    } catch (_) {
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
    notifyListeners();
  }
}
