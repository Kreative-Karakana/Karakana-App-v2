/// Models for the backend issue #67 quiz/certificate-eligibility contract.
///
/// Backend is the sole source of truth for pass/fail, cooldown, and
/// certificate eligibility — nothing here recomputes any of that; every
/// model just carries whatever the backend already decided.
double? _parseNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

class QuizOptionModel {
  final int id;
  final String text;
  final bool? isCorrect;

  QuizOptionModel({required this.id, required this.text, this.isCorrect});

  factory QuizOptionModel.fromJson(Map<String, dynamic> json) {
    return QuizOptionModel(
      id: json['id'] ?? 0,
      text: json['text']?.toString() ?? '',
      isCorrect: json['is_correct'] as bool?,
    );
  }
}

class QuizQuestionModel {
  final int id;
  final String content;
  final int index;
  final String? explanation;
  final List<QuizOptionModel> options;

  QuizQuestionModel({
    required this.id,
    required this.content,
    required this.index,
    this.explanation,
    required this.options,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions
            .whereType<Map>()
            .map((o) => QuizOptionModel.fromJson(Map<String, dynamic>.from(o)))
            .toList()
        : <QuizOptionModel>[];
    return QuizQuestionModel(
      id: json['id'] ?? 0,
      content: json['content']?.toString() ?? '',
      index: json['index'] ?? 0,
      explanation: json['explanation']?.toString(),
      options: options,
    );
  }
}

class QuizVersionSummary {
  final int id;
  final int versionNumber;
  final String status;
  final String title;
  final int passingScore;
  final int failedRetryCooldownMinutes;
  final bool requiredForCertificate;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final List<QuizQuestionModel> questions;
  final int questionCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  QuizVersionSummary({
    required this.id,
    required this.versionNumber,
    required this.status,
    required this.title,
    required this.passingScore,
    required this.failedRetryCooldownMinutes,
    required this.requiredForCertificate,
    this.rejectionReason,
    this.reviewedAt,
    required this.questions,
    required this.questionCount,
    this.createdAt,
    this.updatedAt,
  });

  factory QuizVersionSummary.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map(
                (q) => QuizQuestionModel.fromJson(Map<String, dynamic>.from(q)))
            .toList()
        : <QuizQuestionModel>[];
    return QuizVersionSummary(
      id: json['id'] ?? 0,
      versionNumber: json['version_number'] ?? 0,
      status: json['status']?.toString() ?? 'draft',
      title: json['title']?.toString() ?? '',
      passingScore: json['passing_score'] ?? 70,
      failedRetryCooldownMinutes: json['failed_retry_cooldown_minutes'] ?? 15,
      requiredForCertificate: json['required_for_certificate'] ?? false,
      rejectionReason: json['rejection_reason']?.toString(),
      reviewedAt: _parseDate(json['reviewed_at']),
      questions: questions,
      questionCount: json['question_count'] ?? questions.length,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

/// GET /courses/{id}/quiz/ response — trainer-facing summary of every
/// version that matters to them (there is at most one of each kind).
class QuizSummary {
  final int? quizId;
  final int courseId;
  final QuizVersionSummary? activeVersion;
  final QuizVersionSummary? draftVersion;
  final QuizVersionSummary? pendingReviewVersion;
  final QuizVersionSummary? rejectedVersion;

  QuizSummary({
    this.quizId,
    required this.courseId,
    this.activeVersion,
    this.draftVersion,
    this.pendingReviewVersion,
    this.rejectedVersion,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) {
    QuizVersionSummary? parse(String key) {
      final raw = json[key];
      return raw is Map
          ? QuizVersionSummary.fromJson(Map<String, dynamic>.from(raw))
          : null;
    }

    return QuizSummary(
      quizId: json['quiz_id'] as int?,
      courseId: json['course_id'] ?? 0,
      activeVersion: parse('active_version'),
      draftVersion: parse('draft_version'),
      pendingReviewVersion: parse('pending_review_version'),
      rejectedVersion: parse('rejected_version'),
    );
  }
}

/// GET /courses/{id}/quiz/available/ response.
class QuizAvailability {
  final bool quizAvailable;
  final int? passingScore;
  final int? failedRetryCooldownMinutes;
  final bool requiredForCertificate;
  final bool lessonsComplete;
  final int attemptCount;
  final double? bestScore;
  final bool isPassed;
  final int? inProgressAttemptId;
  final DateTime? cooldownExpiresAt;

  QuizAvailability({
    required this.quizAvailable,
    this.passingScore,
    this.failedRetryCooldownMinutes,
    required this.requiredForCertificate,
    required this.lessonsComplete,
    required this.attemptCount,
    this.bestScore,
    required this.isPassed,
    this.inProgressAttemptId,
    this.cooldownExpiresAt,
  });

  factory QuizAvailability.fromJson(Map<String, dynamic> json) {
    return QuizAvailability(
      quizAvailable: json['quiz_available'] ?? false,
      passingScore: json['passing_score'] as int?,
      failedRetryCooldownMinutes: json['failed_retry_cooldown_minutes'] as int?,
      requiredForCertificate: json['required_for_certificate'] ?? false,
      lessonsComplete: json['lessons_complete'] ?? false,
      attemptCount: json['attempt_count'] ?? 0,
      bestScore: _parseNum(json['best_score']),
      isPassed: json['is_passed'] ?? false,
      inProgressAttemptId: json['in_progress_attempt_id'] as int?,
      cooldownExpiresAt: _parseDate(json['cooldown_expires_at']),
    );
  }
}

class QuizAttemptSummary {
  final int id;
  final int quizVersion;
  final int attemptNumber;
  final String status;
  final int passingPercentageSnapshot;
  final double? score;
  final bool? passed;
  final DateTime? startedAt;
  final DateTime? submittedAt;

  QuizAttemptSummary({
    required this.id,
    required this.quizVersion,
    required this.attemptNumber,
    required this.status,
    required this.passingPercentageSnapshot,
    this.score,
    this.passed,
    this.startedAt,
    this.submittedAt,
  });

  bool get isInProgress => status == 'in_progress';
  bool get isSubmitted => status == 'submitted';

  factory QuizAttemptSummary.fromJson(Map<String, dynamic> json) {
    return QuizAttemptSummary(
      id: json['id'] ?? 0,
      quizVersion: json['quiz_version'] ?? 0,
      attemptNumber: json['attempt_number'] ?? 0,
      status: json['status']?.toString() ?? 'in_progress',
      passingPercentageSnapshot: json['passing_percentage_snapshot'] ?? 70,
      score: _parseNum(json['score']),
      passed: json['passed'] as bool?,
      startedAt: _parseDate(json['started_at']),
      submittedAt: _parseDate(json['submitted_at']),
    );
  }
}

/// Start/resume response — a summary plus the (masked, pre-submission)
/// questions to answer.
class QuizAttemptDetail extends QuizAttemptSummary {
  final List<QuizQuestionModel> questions;

  QuizAttemptDetail({
    required super.id,
    required super.quizVersion,
    required super.attemptNumber,
    required super.status,
    required super.passingPercentageSnapshot,
    super.score,
    super.passed,
    super.startedAt,
    super.submittedAt,
    required this.questions,
  });

  factory QuizAttemptDetail.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map(
                (q) => QuizQuestionModel.fromJson(Map<String, dynamic>.from(q)))
            .toList()
        : <QuizQuestionModel>[];
    return QuizAttemptDetail(
      id: json['id'] ?? 0,
      quizVersion: json['quiz_version'] ?? 0,
      attemptNumber: json['attempt_number'] ?? 0,
      status: json['status']?.toString() ?? 'in_progress',
      passingPercentageSnapshot: json['passing_percentage_snapshot'] ?? 70,
      score: _parseNum(json['score']),
      passed: json['passed'] as bool?,
      startedAt: _parseDate(json['started_at']),
      submittedAt: _parseDate(json['submitted_at']),
      questions: questions,
    );
  }
}

/// One entry in a masked result — `options`/`correctOptionId`/`explanation`
/// are only ever present when the attempt passed, mirroring exactly what
/// the backend chooses to serialize (see QuizAttemptResultSerializer).
class QuizAnswerResult {
  final int questionId;
  final String content;
  final int? selectedOptionId;
  final bool isCorrect;
  final List<QuizOptionModel>? options;
  final int? correctOptionId;
  final String? explanation;

  QuizAnswerResult({
    required this.questionId,
    required this.content,
    this.selectedOptionId,
    required this.isCorrect,
    this.options,
    this.correctOptionId,
    this.explanation,
  });

  factory QuizAnswerResult.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions
            .whereType<Map>()
            .map((o) => QuizOptionModel.fromJson(Map<String, dynamic>.from(o)))
            .toList()
        : null;
    return QuizAnswerResult(
      questionId: json['question_id'] ?? 0,
      content: json['content']?.toString() ?? '',
      selectedOptionId: json['selected_option_id'] as int?,
      isCorrect: json['is_correct'] ?? false,
      options: options,
      correctOptionId: json['correct_option_id'] as int?,
      explanation: json['explanation']?.toString(),
    );
  }
}

class QuizAttemptResult {
  final int id;
  final int attemptNumber;
  final String status;
  final double? score;
  final bool passed;
  final int passingPercentageSnapshot;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final List<QuizAnswerResult> answers;
  final DateTime? retryAvailableAt;

  QuizAttemptResult({
    required this.id,
    required this.attemptNumber,
    required this.status,
    this.score,
    required this.passed,
    required this.passingPercentageSnapshot,
    this.startedAt,
    this.submittedAt,
    required this.answers,
    this.retryAvailableAt,
  });

  factory QuizAttemptResult.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'];
    final answers = rawAnswers is List
        ? rawAnswers
            .whereType<Map>()
            .map((a) => QuizAnswerResult.fromJson(Map<String, dynamic>.from(a)))
            .toList()
        : <QuizAnswerResult>[];
    return QuizAttemptResult(
      id: json['id'] ?? 0,
      attemptNumber: json['attempt_number'] ?? 0,
      status: json['status']?.toString() ?? 'submitted',
      score: _parseNum(json['score']),
      passed: json['passed'] ?? false,
      passingPercentageSnapshot: json['passing_percentage_snapshot'] ?? 70,
      startedAt: _parseDate(json['started_at']),
      submittedAt: _parseDate(json['submitted_at']),
      answers: answers,
      retryAvailableAt: _parseDate(json['retry_available_at']),
    );
  }
}

/// GET /courses/{id}/certificate-eligibility/ response — authoritative;
/// Flutter never derives eligibility itself, only displays this.
class CertificateEligibility {
  final bool isEnrolled;
  final int lessonsCompleted;
  final int lessonsTotal;
  final bool lessonsComplete;
  final bool quizRequired;
  final bool quizAvailable;
  final double? bestScore;
  final int? passingThreshold;
  final bool isPassed;
  final DateTime? cooldownExpiresAt;
  final bool isExempt;
  final bool isEligible;
  final String reasonCode;

  CertificateEligibility({
    required this.isEnrolled,
    required this.lessonsCompleted,
    required this.lessonsTotal,
    required this.lessonsComplete,
    required this.quizRequired,
    required this.quizAvailable,
    this.bestScore,
    this.passingThreshold,
    required this.isPassed,
    this.cooldownExpiresAt,
    required this.isExempt,
    required this.isEligible,
    required this.reasonCode,
  });

  factory CertificateEligibility.fromJson(Map<String, dynamic> json) {
    return CertificateEligibility(
      isEnrolled: json['is_enrolled'] ?? false,
      lessonsCompleted: json['lessons_completed'] ?? 0,
      lessonsTotal: json['lessons_total'] ?? 0,
      lessonsComplete: json['lessons_complete'] ?? false,
      quizRequired: json['quiz_required'] ?? false,
      quizAvailable: json['quiz_available'] ?? false,
      bestScore: _parseNum(json['best_score']),
      passingThreshold: json['passing_threshold'] as int?,
      isPassed: json['is_passed'] ?? false,
      cooldownExpiresAt: _parseDate(json['cooldown_expires_at']),
      isExempt: json['is_exempt'] ?? false,
      isEligible: json['is_eligible'] ?? false,
      reasonCode: json['reason_code']?.toString() ?? '',
    );
  }
}

class CertificateModel {
  final int id;
  final String certificateNumber;
  final bool isApproved;
  final DateTime? issuedAt;
  final String studentName;
  final String courseTitle;
  final String courseExcerpt;

  CertificateModel({
    required this.id,
    required this.certificateNumber,
    required this.isApproved,
    this.issuedAt,
    required this.studentName,
    required this.courseTitle,
    required this.courseExcerpt,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: json['id'] ?? 0,
      certificateNumber: json['certificate_number']?.toString() ?? '',
      isApproved: json['is_approved'] ?? true,
      issuedAt: _parseDate(json['issued_at']),
      studentName: json['student_name']?.toString() ?? '',
      courseTitle: json['course_title']?.toString() ?? '',
      courseExcerpt: json['course_excerpt']?.toString() ?? '',
    );
  }
}

/// One question in a trainer's draft write payload — matches the #67
/// aggregate shape exactly: `{question, options, correct_answer,
/// explanation}`, not per-option objects.
class QuizDraftQuestionInput {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  QuizDraftQuestionInput({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation = '',
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correct_answer': correctAnswer,
        'explanation': explanation,
      };
}

/// The full trainer draft write payload for POST/PATCH .../quiz/.
class QuizDraftPayload {
  final int passingScore;
  final int failedRetryCooldownMinutes;
  final bool requiredForCertificate;
  final List<QuizDraftQuestionInput> questions;

  QuizDraftPayload({
    required this.passingScore,
    required this.failedRetryCooldownMinutes,
    required this.requiredForCertificate,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
        'passing_score': passingScore,
        'failed_retry_cooldown_minutes': failedRetryCooldownMinutes,
        'required_for_certificate': requiredForCertificate,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}
