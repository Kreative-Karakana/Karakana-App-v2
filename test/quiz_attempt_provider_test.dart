import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/courses/models/quiz_model.dart';
import 'package:karakana_app/features/courses/providers/quiz_attempt_provider.dart';
import 'package:karakana_app/features/courses/services/quiz_service.dart';

void main() {
  group('QuizAttemptProvider availability', () {
    test('loads availability and clears loading flag', () async {
      final service = _FakeQuizService()
        ..availabilityToReturn = _availability(quizAvailable: true);
      final provider = QuizAttemptProvider(service: service);

      await provider.loadAvailability(1);

      expect(provider.availability?.quizAvailable, isTrue);
      expect(provider.isLoadingAvailability, isFalse);
      expect(provider.availabilityError, isNull);
    });

    test('records an error message on failure', () async {
      final service = _FakeQuizService()
        ..availabilityError = Exception('network down');
      final provider = QuizAttemptProvider(service: service);

      await provider.loadAvailability(1);

      expect(provider.availability, isNull);
      expect(provider.availabilityError, isNotNull);
    });
  });

  group('QuizAttemptProvider start/resume', () {
    test('starts a new attempt and clears prior local answers/result',
        () async {
      final service = _FakeQuizService()
        ..startResumeToReturn = _attemptDetail(id: 5, questionIds: [1, 2]);
      final provider = QuizAttemptProvider(service: service);

      await provider.startOrResume(1);

      expect(provider.attempt?.id, 5);
      expect(provider.answers, isEmpty);
      expect(provider.result, isNull);
      expect(provider.isStarting, isFalse);
    });

    test('surfaces a QuizActionException code (e.g. LESSONS_INCOMPLETE)',
        () async {
      final service = _FakeQuizService()
        ..startError =
            QuizActionException('LESSONS_INCOMPLETE', 'Kamilisha masomo.');
      final provider = QuizAttemptProvider(service: service);

      await provider.startOrResume(1);

      expect(provider.attempt, isNull);
      expect(provider.startErrorCode, 'LESSONS_INCOMPLETE');
      expect(provider.startErrorMessage, 'Kamilisha masomo.');
    });

    test('surfaces cooldown errors distinctly from other failures', () async {
      final service = _FakeQuizService()
        ..startError = QuizActionException('COOLDOWN_ACTIVE', 'Subiri kidogo.');
      final provider = QuizAttemptProvider(service: service);

      await provider.startOrResume(1);

      expect(provider.startErrorCode, 'COOLDOWN_ACTIVE');
    });
  });

  group('QuizAttemptProvider answering', () {
    test('selecting an option autosaves the full cumulative answer set',
        () async {
      final service = _FakeQuizService()
        ..startResumeToReturn = _attemptDetail(id: 5, questionIds: [1, 2]);
      final provider = QuizAttemptProvider(service: service);
      await provider.startOrResume(1);

      await provider.selectOption(1, 100);
      await provider.selectOption(2, 200);

      expect(provider.answers, {1: 100, 2: 200});
      expect(service.savedAnswersCalls.last, {1: 100, 2: 200});
      expect(provider.isSaving, isFalse);
      expect(provider.saveError, isNull);
    });

    test('allQuestionsAnswered is only true once every question has an answer',
        () async {
      final service = _FakeQuizService()
        ..startResumeToReturn = _attemptDetail(id: 5, questionIds: [1, 2]);
      final provider = QuizAttemptProvider(service: service);
      await provider.startOrResume(1);

      expect(provider.allQuestionsAnswered, isFalse);
      await provider.selectOption(1, 100);
      expect(provider.allQuestionsAnswered, isFalse);
      await provider.selectOption(2, 200);
      expect(provider.allQuestionsAnswered, isTrue);
    });

    test('keeps the optimistic local selection even if autosave fails',
        () async {
      final service = _FakeQuizService()
        ..startResumeToReturn = _attemptDetail(id: 5, questionIds: [1])
        ..saveAnswersError = Exception('offline');
      final provider = QuizAttemptProvider(service: service);
      await provider.startOrResume(1);

      await provider.selectOption(1, 100);

      expect(provider.answers[1], 100);
      expect(provider.saveError, isNotNull);
    });
  });

  group('QuizAttemptProvider submit', () {
    test('submits and stores the masked result on success', () async {
      final service = _FakeQuizService()
        ..startResumeToReturn = _attemptDetail(id: 5, questionIds: [1])
        ..submitToReturn = _result(id: 5, passed: true);
      final provider = QuizAttemptProvider(service: service);
      await provider.startOrResume(1);

      final ok = await provider.submit();

      expect(ok, isTrue);
      expect(provider.result?.passed, isTrue);
      expect(provider.isSubmitting, isFalse);
    });

    test('returns false and records an error on failure', () async {
      final service = _FakeQuizService()
        ..startResumeToReturn = _attemptDetail(id: 5, questionIds: [1])
        ..submitError = QuizActionException('QUIZ_EMPTY', 'Hakuna maswali.');
      final provider = QuizAttemptProvider(service: service);
      await provider.startOrResume(1);

      final ok = await provider.submit();

      expect(ok, isFalse);
      expect(provider.result, isNull);
      expect(provider.submitError, 'Hakuna maswali.');
    });
  });
}

QuizAvailability _availability({required bool quizAvailable}) {
  return QuizAvailability(
    quizAvailable: quizAvailable,
    passingScore: 70,
    failedRetryCooldownMinutes: 15,
    requiredForCertificate: false,
    lessonsComplete: true,
    attemptCount: 0,
    isPassed: false,
  );
}

QuizAttemptDetail _attemptDetail(
    {required int id, required List<int> questionIds}) {
  return QuizAttemptDetail(
    id: id,
    quizVersion: 1,
    attemptNumber: 1,
    status: 'in_progress',
    passingPercentageSnapshot: 70,
    questions: questionIds
        .map((qid) => QuizQuestionModel(
              id: qid,
              content: 'Question $qid',
              index: qid,
              options: [
                QuizOptionModel(id: qid * 100, text: 'A'),
                QuizOptionModel(id: qid * 100 + 1, text: 'B'),
              ],
            ))
        .toList(),
  );
}

QuizAttemptResult _result({required int id, required bool passed}) {
  return QuizAttemptResult(
    id: id,
    attemptNumber: 1,
    status: 'submitted',
    score: passed ? 100 : 0,
    passed: passed,
    passingPercentageSnapshot: 70,
    answers: const [],
  );
}

class _FakeQuizService implements QuizCatalogService {
  QuizAvailability? availabilityToReturn;
  Object? availabilityError;

  QuizAttemptDetail? startResumeToReturn;
  Object? startError;

  QuizAttemptDetail? saveAnswersToReturn;
  Object? saveAnswersError;
  final List<Map<int, int>> savedAnswersCalls = [];

  QuizAttemptResult? submitToReturn;
  Object? submitError;

  List<QuizAttemptSummary> historyToReturn = [];

  @override
  Future<QuizAvailability> getQuizAvailability(int courseId) async {
    if (availabilityError != null) throw availabilityError!;
    return availabilityToReturn!;
  }

  @override
  Future<QuizAttemptDetail> startOrResumeAttempt(int courseId) async {
    if (startError != null) throw startError!;
    return startResumeToReturn!;
  }

  @override
  Future<QuizAttemptDetail> saveAttemptAnswers(
      int attemptId, Map<int, int> answers) async {
    savedAnswersCalls.add(Map.of(answers));
    if (saveAnswersError != null) throw saveAnswersError!;
    return saveAnswersToReturn ?? startResumeToReturn!;
  }

  @override
  Future<QuizAttemptResult> submitAttempt(int attemptId) async {
    if (submitError != null) throw submitError!;
    return submitToReturn!;
  }

  @override
  Future<List<QuizAttemptSummary>> getAttemptHistory(int courseId) async =>
      historyToReturn;

  @override
  Future<QuizAttemptResult> getAttemptResult(int attemptId) =>
      throw UnimplementedError();

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
  Future<CertificateEligibility> getCertificateEligibility(int courseId) =>
      throw UnimplementedError();

  @override
  Future<CertificateModel> requestCertificate(int courseId) =>
      throw UnimplementedError();
}
