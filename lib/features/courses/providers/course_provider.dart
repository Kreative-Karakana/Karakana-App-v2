import 'package:flutter/material.dart';

import '../models/course_model.dart';
import '../services/course_service.dart';

/// Manages all course-related state for the Karakana app.
///
/// Screens that display courses, categories, banners, sections, or reviews
/// should read from this provider via `context.watch<CourseProvider>()` and
/// trigger data loads via the public methods.
class CourseProvider extends ChangeNotifier {
  final _service = CourseService.instance;

  // ─────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────

  /// True while the main course list is being fetched.
  bool _isLoading = false;

  /// True while a single course's detail is being fetched.
  bool _isLoadingDetail = false;

  /// True while a course's sections are being fetched.
  bool _isLoadingSections = false;

  /// Non-null when any API call fails. Cleared by [clearError].
  String? _errorMessage;

  List<CourseModel> _courses = [];

  /// Up to 5 courses surfaced as recommendations (first page slice).
  List<CourseModel> _recommendedCourses = [];

  /// Up to 5 courses surfaced as popular (second page slice).
  List<CourseModel> _popularCourses = [];

  /// Courses whose price is 0 (free).
  List<CourseModel> _freeCourses = [];

  List<CategoryModel> _categories = [];
  List<BannerModel> _banners = [];
  CourseModel? _selectedCourse;
  List<SectionModel> _sections = [];
  List<ReviewModel> _reviews = [];

  String _searchQuery = '';
  String? _selectedCategoryName;

  // ─────────────────────────────────────────────
  // Getters — raw state
  // ─────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isLoadingSections => _isLoadingSections;
  String? get errorMessage => _errorMessage;
  List<CourseModel> get courses => _courses;
  List<CourseModel> get recommendedCourses => _recommendedCourses;
  List<CourseModel> get popularCourses => _popularCourses;
  List<CourseModel> get freeCourses => _freeCourses;
  List<CategoryModel> get categories => _categories;
  List<BannerModel> get banners => _banners;
  CourseModel? get selectedCourse => _selectedCourse;
  List<SectionModel> get sections => _sections;
  List<ReviewModel> get reviews => _reviews;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryName => _selectedCategoryName;

  // ─────────────────────────────────────────────
  // Getters — derived
  // ─────────────────────────────────────────────

  /// All courses the current user is enrolled in.
  List<CourseModel> get enrolledCourses =>
      _courses.where((c) => c.isEnrolled).toList();

  /// All courses the current user has wishlisted.
  List<CourseModel> get wishlistedCourses =>
      _courses.where((c) => c.isWishlisted).toList();

  // ─────────────────────────────────────────────
  // Home data
  // ─────────────────────────────────────────────

  /// Loads banners and the default course list in parallel.
  ///
  /// Banner failures are silently swallowed — courses load independently
  /// and [errorMessage] is only set when course fetching fails.
  Future<void> loadHomeData() async {
    await Future.wait([loadBanners(), loadCourses()]);
  }

  // ─────────────────────────────────────────────
  // Banners
  // ─────────────────────────────────────────────

  /// Fetches all active promotional banners.
  ///
  /// On any failure, banners are set to an empty list and no error is
  /// surfaced — the home screen simply omits the banner section.
  Future<void> loadBanners() async {
    try {
      _banners = await _service.getBanners();
    } catch (_) {
      _banners = [];
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Courses
  // ─────────────────────────────────────────────

  /// Fetches all course sections in parallel using dedicated backend filters.
  ///
  /// [recommended], [popular], and [free] lists each use a specific query
  /// flag so the backend returns the correct curated subset. The main
  /// [_courses] list supports [search] and [categoryId] filtering.
  Future<void> loadCourses({String? search, String? categoryName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getCourses(recommended: true),
        _service.getCourses(popular: true),
        _service.getCourses(free: true),
        _service.getCourses(search: search, categoryName: categoryName),
      ]);

      _recommendedCourses = results[0];
      _popularCourses = results[1];
      _freeCourses = results[2];
      _courses = results[3];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Categories
  // ─────────────────────────────────────────────

  /// Fetches all course categories.
  Future<void> loadCategories() async {
    try {
      _categories = await _service.getCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Course detail
  // ─────────────────────────────────────────────

  /// Fetches full detail for [courseId], then loads its sections and reviews.
  Future<void> loadCourseDetail(int courseId) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedCourse = await _service.getCourseDetail(courseId);
      // Fetch supporting data in parallel once we have the course.
      await Future.wait([
        loadCourseSections(courseId),
        loadCourseReviews(courseId),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Fetches ordered sections (with nested lessons) for [courseId].
  Future<void> loadCourseSections(int courseId) async {
    _isLoadingSections = true;
    notifyListeners();

    try {
      _sections = await _service.getCourseSections(courseId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingSections = false;
      notifyListeners();
    }
  }

  /// Fetches reviews for [courseId].
  Future<void> loadCourseReviews(int courseId) async {
    try {
      _reviews = await _service.getCourseReviews(courseId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Search & filter
  // ─────────────────────────────────────────────

  /// Updates the search query and reloads the course list.
  Future<void> searchCourses(String query) async {
    _searchQuery = query;
    notifyListeners();
    await loadCourses(search: query, categoryName: _selectedCategoryName);
  }

  /// Updates the active category filter and reloads the course list.
  ///
  /// Pass `null` to clear the filter.
  Future<void> filterByCategory(String? categoryName) async {
    _selectedCategoryName = categoryName;
    _isLoading = true;
    notifyListeners();

    try {
      _courses = await _service.getCourses(categoryName: categoryName);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Enrolment
  // ─────────────────────────────────────────────

  /// Enrols the current user in a free course and marks it as enrolled
  /// locally so the UI updates immediately without a full reload.
  ///
  /// Returns `true` on success.
  Future<bool> enrollFreeCourse(int courseId) async {
    try {
      final success = await _service.enrollFreeCourse(courseId);
      if (success) {
        _courses = _courses.map((c) {
          if (c.id == courseId) {
            return CourseModel(
              id: c.id,
              title: c.title,
              excerpt: c.excerpt,
              description: c.description,
              price: c.price,
              status: c.status,
              level: c.level,
              isBlocked: c.isBlocked,
              thumbnail: c.thumbnail,
              trailerPlaybackId: c.trailerPlaybackId,
              categories: c.categories,
              trainerName: c.trainerName,
              trainerAvatar: c.trainerAvatar,
              studentsCount: c.studentsCount,
              averageRating: c.averageRating,
              reviewsCount: c.reviewsCount,
              isEnrolled: true,
              isWishlisted: c.isWishlisted,
            );
          }
          return c;
        }).toList();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Wishlist
  // ─────────────────────────────────────────────

  /// Toggles the wishlist state of [courseId] and updates the local list.
  ///
  /// Returns `true` if the course is now wishlisted.
  Future<bool> toggleWishlist(int courseId) async {
    try {
      final isWishlisted = await _service.toggleWishlist(courseId);
      _courses = _courses.map((c) {
        if (c.id == courseId) {
          return CourseModel(
            id: c.id,
            title: c.title,
            excerpt: c.excerpt,
            description: c.description,
            price: c.price,
            status: c.status,
            level: c.level,
            isBlocked: c.isBlocked,
            thumbnail: c.thumbnail,
            trailerPlaybackId: c.trailerPlaybackId,
            categories: c.categories,
            trainerName: c.trainerName,
            trainerAvatar: c.trainerAvatar,
            studentsCount: c.studentsCount,
            averageRating: c.averageRating,
            reviewsCount: c.reviewsCount,
            isEnrolled: c.isEnrolled,
            isWishlisted: isWishlisted,
          );
        }
        return c;
      }).toList();
      notifyListeners();
      return isWishlisted;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Lesson progress
  // ─────────────────────────────────────────────

  /// Toggles the read/watched state of a lesson at
  /// `_sections[sectionIndex].lessons[lessonIndex]`.
  ///
  /// Returns `true` if the lesson is now marked as read.
  Future<bool> toggleLessonProgress(
    int lessonId,
    int sectionIndex,
    int lessonIndex,
  ) async {
    try {
      final isRead = await _service.toggleLessonProgress(lessonId);

      // Rebuild the target section with the updated lesson.
      if (sectionIndex < _sections.length) {
        final section = _sections[sectionIndex];
        if (lessonIndex < section.lessons.length) {
          final oldLesson = section.lessons[lessonIndex];
          final updatedLesson = LessonModel(
            id: oldLesson.id,
            title: oldLesson.title,
            content: oldLesson.content,
            index: oldLesson.index,
            muxPlaybackId: oldLesson.muxPlaybackId,
            isRead: isRead,
            signedPlaybackUrl: oldLesson.signedPlaybackUrl,
          );

          final updatedLessons = List<LessonModel>.from(section.lessons);
          updatedLessons[lessonIndex] = updatedLesson;

          final updatedSection = SectionModel(
            id: section.id,
            title: section.title,
            index: section.index,
            lessons: updatedLessons,
          );

          _sections = List<SectionModel>.from(_sections);
          _sections[sectionIndex] = updatedSection;
        }
      }

      notifyListeners();
      return isRead;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Reviews
  // ─────────────────────────────────────────────

  /// Submits a review and prepends it to the local [reviews] list.
  ///
  /// Returns `true` on success.
  Future<bool> createReview(int courseId, int rating, String content) async {
    try {
      final review = await _service.createReview(courseId, rating, content);
      _reviews = [review, ..._reviews];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
