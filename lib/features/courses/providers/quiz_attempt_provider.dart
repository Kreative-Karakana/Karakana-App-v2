import 'package:flutter/foundation.dart';

import '../models/quiz_model.dart';
import '../services/quiz_service.dart';

/// Drives the learner quiz-taking flow: availability -> start/resume ->
/// autosave -> submit -> masked result. Backend decides every outcome
/// (pass/fail, cooldown, masking) — this only holds UI state and relays
/// calls to [QuizCatalogService].
///
/// Note: resuming an in-progress attempt does not re-populate previously
/// selected options in [answers] (the backend's start/resume response
/// returns the question list only, not prior selections) — a resumed
/// attempt's UI starts with nothing visibly selected, but any question
/// left untouched keeps its previously saved answer server-side, since
/// autosave only ever upserts the questions the learner actually
/// re-selects.
class QuizAttemptProvider extends ChangeNotifier {
  final QuizCatalogService _service;

  QuizAttemptProvider({QuizCatalogService? service})
      : _service = service ?? QuizService();

  bool isLoadingAvailability = false;
  QuizAvailability? availability;
  String? availabilityError;

  bool isStarting = false;
  QuizAttemptDetail? attempt;
  String? startErrorCode;
  String? startErrorMessage;

  final Map<int, int> _answers = {};
  Map<int, int> get answers => Map.unmodifiable(_answers);

  bool isSaving = false;
  String? saveError;

  bool isSubmitting = false;
  QuizAttemptResult? result;
  String? submitError;

  List<QuizAttemptSummary> history = [];

  bool get allQuestionsAnswered {
    final current = attempt;
    if (current == null || current.questions.isEmpty) return false;
    return current.questions.every((q) => _answers.containsKey(q.id));
  }

  Future<void> loadAvailability(int courseId) async {
    isLoadingAvailability = true;
    availabilityError = null;
    notifyListeners();
    try {
      availability = await _service.getQuizAvailability(courseId);
    } catch (e) {
      availabilityError = e.toString();
    }
    isLoadingAvailability = false;
    notifyListeners();
  }

  Future<void> loadHistory(int courseId) async {
    try {
      history = await _service.getAttemptHistory(courseId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[QuizAttemptProvider] loadHistory: $e');
    }
  }

  Future<void> startOrResume(int courseId) async {
    isStarting = true;
    startErrorCode = null;
    startErrorMessage = null;
    result = null;
    _answers.clear();
    notifyListeners();

    try {
      attempt = await _service.startOrResumeAttempt(courseId);
    } catch (e) {
      if (e is QuizActionException) {
        startErrorCode = e.code;
        startErrorMessage = e.message;
      } else {
        startErrorMessage = e.toString();
      }
    }
    isStarting = false;
    notifyListeners();
  }

  /// Selects `optionId` for `questionId` and immediately autosaves the
  /// full current answer set — every question count in this flow is
  /// small, so per-selection autosave (rather than a debounced timer)
  /// keeps the state machine simple and directly testable.
  Future<void> selectOption(int questionId, int optionId) async {
    final current = attempt;
    if (current == null) return;
    _answers[questionId] = optionId;
    notifyListeners();

    isSaving = true;
    saveError = null;
    notifyListeners();
    try {
      attempt = await _service.saveAttemptAnswers(current.id, Map.of(_answers));
    } catch (e) {
      saveError = e is QuizActionException ? e.message : e.toString();
    }
    isSaving = false;
    notifyListeners();
  }

  Future<bool> submit() async {
    final current = attempt;
    if (current == null) return false;
    isSubmitting = true;
    submitError = null;
    notifyListeners();
    try {
      result = await _service.submitAttempt(current.id);
      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      submitError = e is QuizActionException ? e.message : e.toString();
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    availability = null;
    availabilityError = null;
    attempt = null;
    startErrorCode = null;
    startErrorMessage = null;
    _answers.clear();
    saveError = null;
    result = null;
    submitError = null;
    history = [];
    notifyListeners();
  }
}
