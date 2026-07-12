import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/quiz_model.dart';

/// Raised when the backend rejects a quiz action with a structured
/// `{code, detail}` body (attempt start/answers/submit) or a certificate
/// request's `{error, reason_code}` body — carries the stable machine
/// code so callers can branch (e.g. show a cooldown countdown) without
/// string-matching a localized message.
class QuizActionException implements Exception {
  final String code;
  final String message;

  QuizActionException(this.code, this.message);

  @override
  String toString() => message;
}

abstract class QuizCatalogService {
  // Trainer
  Future<QuizSummary> getCourseQuiz(int courseId);
  Future<QuizVersionSummary> createQuizDraft(
      int courseId, QuizDraftPayload payload);
  Future<QuizVersionSummary> updateQuizDraft(
      int courseId, QuizDraftPayload payload);
  Future<void> deleteQuizDraft(int courseId);
  Future<QuizVersionSummary> submitQuizForReview(int courseId);

  // Learner
  Future<QuizAvailability> getQuizAvailability(int courseId);
  Future<QuizAttemptDetail> startOrResumeAttempt(int courseId);
  Future<QuizAttemptDetail> saveAttemptAnswers(
      int attemptId, Map<int, int> answers);
  Future<QuizAttemptResult> submitAttempt(int attemptId);
  Future<List<QuizAttemptSummary>> getAttemptHistory(int courseId);
  Future<QuizAttemptResult> getAttemptResult(int attemptId);

  // Certificate
  Future<CertificateEligibility> getCertificateEligibility(int courseId);
  Future<CertificateModel> requestCertificate(int courseId);
}

class QuizService implements QuizCatalogService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  final _dio = ApiClient().dio;

  /// Rethrows a structured `{code, detail}`/`{error, reason_code}` body as
  /// a [QuizActionException]; falls back to [ApiClient.parseError] for
  /// anything else, matching every other service in this app.
  Never _rethrow(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final code = data['code'] ?? data['reason_code'];
        if (code != null) {
          final detail = (data['detail'] ?? data['error'])?.toString() ??
              ApiClient().parseError(e);
          throw QuizActionException(code.toString(), detail);
        }
      }
    }
    throw ApiClient().parseError(e);
  }

  @override
  Future<QuizSummary> getCourseQuiz(int courseId) async {
    try {
      final response = await _dio.get('/api/v1/courses/$courseId/quiz/');
      return QuizSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<QuizVersionSummary> createQuizDraft(
      int courseId, QuizDraftPayload payload) async {
    try {
      final response = await _dio.post(
        '/api/v1/courses/$courseId/quiz/',
        data: payload.toJson(),
      );
      return QuizVersionSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<QuizVersionSummary> updateQuizDraft(
      int courseId, QuizDraftPayload payload) async {
    try {
      final response = await _dio.patch(
        '/api/v1/courses/$courseId/quiz/',
        data: payload.toJson(),
      );
      return QuizVersionSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<void> deleteQuizDraft(int courseId) async {
    try {
      await _dio.delete('/api/v1/courses/$courseId/quiz/');
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<QuizVersionSummary> submitQuizForReview(int courseId) async {
    try {
      final response =
          await _dio.post('/api/v1/courses/$courseId/quiz/submit-review/');
      return QuizVersionSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<QuizAvailability> getQuizAvailability(int courseId) async {
    try {
      final response =
          await _dio.get('/api/v1/courses/$courseId/quiz/available/');
      return QuizAvailability.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<QuizAttemptDetail> startOrResumeAttempt(int courseId) async {
    try {
      final response =
          await _dio.post('/api/v1/courses/$courseId/quiz/attempts/');
      return QuizAttemptDetail.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<QuizAttemptDetail> saveAttemptAnswers(
      int attemptId, Map<int, int> answers) async {
    try {
      final response = await _dio.patch(
        '/api/v1/quiz-attempts/$attemptId/answers/',
        data: {
          'answers': answers.entries
              .map((e) => {'question': e.key, 'option': e.value})
              .toList(),
        },
      );
      return QuizAttemptDetail.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<QuizAttemptResult> submitAttempt(int attemptId) async {
    try {
      final response =
          await _dio.post('/api/v1/quiz-attempts/$attemptId/submit/');
      return QuizAttemptResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<List<QuizAttemptSummary>> getAttemptHistory(int courseId) async {
    try {
      final response =
          await _dio.get('/api/v1/courses/$courseId/quiz/attempts/');
      final data = response.data;
      final list = data is List ? data : const [];
      return list
          .whereType<Map>()
          .map((j) => QuizAttemptSummary.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<QuizAttemptResult> getAttemptResult(int attemptId) async {
    try {
      final response =
          await _dio.get('/api/v1/quiz-attempts/$attemptId/result/');
      return QuizAttemptResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<CertificateEligibility> getCertificateEligibility(int courseId) async {
    try {
      final response =
          await _dio.get('/api/v1/courses/$courseId/certificate-eligibility/');
      return CertificateEligibility.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<CertificateModel> requestCertificate(int courseId) async {
    try {
      final response = await _dio.post(
        '/api/v1/certificates/',
        data: {'course_id': courseId},
      );
      return CertificateModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _rethrow(e);
    }
  }
}
