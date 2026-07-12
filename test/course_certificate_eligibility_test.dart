import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/courses/models/course_model.dart';
import 'package:karakana_app/features/courses/models/quiz_model.dart';
import 'package:karakana_app/features/courses/providers/course_provider.dart';
import 'package:karakana_app/features/courses/services/course_service.dart';
import 'package:karakana_app/features/courses/services/quiz_service.dart';

void main() {
  group('CourseProvider certificate eligibility / quiz availability', () {
    test(
        'a course with no required quiz stays eligible on lesson completion alone (regression)',
        () async {
      final courseService = _FakeCourseService();
      final quizService = _FakeQuizService()
        ..eligibility = _eligibility(
          isEligible: true,
          reasonCode: 'ELIGIBLE_LESSONS_ONLY',
        )
        ..availability = _availability(quizAvailable: false);
      final provider = CourseProvider(
        service: courseService,
        quizService: quizService,
      );

      await provider.loadCourseDetail(1);
      // loadCertificateEligibility/loadQuizAvailability fire without being
      // awaited by loadCourseDetail itself — wait a tick for them.
      await Future<void>.delayed(Duration.zero);

      expect(provider.certificateEligibility?.isEligible, isTrue);
      expect(
          provider.certificateEligibility?.reasonCode, 'ELIGIBLE_LESSONS_ONLY');
      expect(provider.quizAvailability?.quizAvailable, isFalse);
    });

    test('a required quiz blocks eligibility until passed', () async {
      final courseService = _FakeCourseService();
      final quizService = _FakeQuizService()
        ..eligibility = _eligibility(
          isEligible: false,
          reasonCode: 'QUIZ_NOT_ATTEMPTED',
        )
        ..availability =
            _availability(quizAvailable: true, requiredForCertificate: true);
      final provider = CourseProvider(
        service: courseService,
        quizService: quizService,
      );

      await provider.loadCourseDetail(1);
      await Future<void>.delayed(Duration.zero);

      expect(provider.certificateEligibility?.isEligible, isFalse);
      expect(provider.quizAvailability?.requiredForCertificate, isTrue);
    });

    test('failure to load eligibility does not block course detail loading',
        () async {
      final courseService = _FakeCourseService();
      final quizService = _FakeQuizService()
        ..eligibilityError = Exception('down');
      final provider = CourseProvider(
        service: courseService,
        quizService: quizService,
      );

      await provider.loadCourseDetail(1);
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedCourse, isNotNull);
      expect(provider.certificateEligibility, isNull);
    });
  });
}

CertificateEligibility _eligibility({
  required bool isEligible,
  required String reasonCode,
}) {
  return CertificateEligibility(
    isEnrolled: true,
    lessonsCompleted: 1,
    lessonsTotal: 1,
    lessonsComplete: true,
    quizRequired: reasonCode != 'ELIGIBLE_LESSONS_ONLY',
    quizAvailable: false,
    isPassed: false,
    isExempt: false,
    isEligible: isEligible,
    reasonCode: reasonCode,
  );
}

QuizAvailability _availability({
  required bool quizAvailable,
  bool requiredForCertificate = false,
}) {
  return QuizAvailability(
    quizAvailable: quizAvailable,
    requiredForCertificate: requiredForCertificate,
    lessonsComplete: true,
    attemptCount: 0,
    isPassed: false,
  );
}

class _FakeCourseService implements CourseCatalogService {
  @override
  Future<CourseModel> getCourseDetail(int id) async {
    return CourseModel.fromJson({
      'id': id,
      'title': 'Course $id',
      'excerpt': '',
      'description': '',
      'price': '0',
      'status': 'published',
      'level': 'BGN',
      'trainer': {'id': 1, 'first_name': 'Kara', 'last_name': 'Kana'},
      'student_count': 0,
      'average_rating': '0',
      'review_count': 0,
      'is_enrolled': true,
      'is_in_wishlist': false,
      'categories': const [],
      'faqs': const [],
    });
  }

  @override
  Future<List<SectionModel>> getCourseSections(int courseId) async => [];

  @override
  Future<List<ReviewModel>> getCourseReviews(int courseId) async => [];

  @override
  Future<List<BannerModel>> getBanners() => throw UnimplementedError();

  @override
  Future<List<CategoryModel>> getCategories() => throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> enrollFreeCourse(int courseId) => throw UnimplementedError();

  @override
  Future<bool> toggleLessonProgress(int lessonId) => throw UnimplementedError();

  @override
  Future<bool> toggleWishlist(int courseId) => throw UnimplementedError();
}

class _FakeQuizService implements QuizCatalogService {
  CertificateEligibility? eligibility;
  Object? eligibilityError;
  QuizAvailability? availability;
  Object? availabilityError;

  @override
  Future<CertificateEligibility> getCertificateEligibility(int courseId) async {
    if (eligibilityError != null) throw eligibilityError!;
    return eligibility!;
  }

  @override
  Future<QuizAvailability> getQuizAvailability(int courseId) async {
    if (availabilityError != null) throw availabilityError!;
    return availability!;
  }

  @override
  Future<QuizSummary> getCourseQuiz(int courseId) => throw UnimplementedError();

  @override
  Future<QuizVersionSummary> createQuizDraft(
          int courseId, QuizDraftPayload payload) =>
      throw UnimplementedError();

  @override
  Future<QuizVersionSummary> updateQuizDraft(
          int courseId, QuizDraftPayload payload) =>
      throw UnimplementedError();

  @override
  Future<void> deleteQuizDraft(int courseId) => throw UnimplementedError();

  @override
  Future<QuizVersionSummary> submitQuizForReview(int courseId) =>
      throw UnimplementedError();

  @override
  Future<QuizAttemptDetail> startOrResumeAttempt(int courseId) =>
      throw UnimplementedError();

  @override
  Future<QuizAttemptDetail> saveAttemptAnswers(
          int attemptId, Map<int, int> answers) =>
      throw UnimplementedError();

  @override
  Future<QuizAttemptResult> submitAttempt(int attemptId) =>
      throw UnimplementedError();

  @override
  Future<List<QuizAttemptSummary>> getAttemptHistory(int courseId) =>
      throw UnimplementedError();

  @override
  Future<QuizAttemptResult> getAttemptResult(int attemptId) =>
      throw UnimplementedError();

  @override
  Future<CertificateModel> requestCertificate(int courseId) =>
      throw UnimplementedError();
}
