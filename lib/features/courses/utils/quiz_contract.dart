import '../models/quiz_model.dart';

class QuizVersionStatusPresentation {
  final String label;
  final int colorValue;

  const QuizVersionStatusPresentation(this.label, this.colorValue);
}

class QuizValidationResult {
  final Map<String, String> fieldErrors;

  const QuizValidationResult(this.fieldErrors);

  bool get isValid => fieldErrors.isEmpty;
  String? get firstError =>
      fieldErrors.values.isEmpty ? null : fieldErrors.values.first;
}

/// Pure, testable quiz-lifecycle/copy/validation logic shared by the
/// trainer authoring screens and the learner attempt flow — mirrors
/// `lib/features/trainer/utils/course_contract.dart`'s pattern for course
/// status. Backend remains authoritative for every actual decision; this
/// only maps backend-given values to Swahili copy/presentation.
class QuizContract {
  static const statusDraft = 'draft';
  static const statusPendingReview = 'pending_review';
  static const statusPublished = 'published';
  static const statusRejected = 'rejected';
  static const statusRetired = 'retired';

  static const minPassingScore = 60;
  static const maxPassingScore = 100;
  static const requiredOptionCount = 4;

  static const statusPresentations = {
    statusDraft: QuizVersionStatusPresentation('Rasimu', 0xFF6B7280),
    statusPendingReview:
        QuizVersionStatusPresentation('Inasubiri Ukaguzi', 0xFFE87722),
    statusPublished: QuizVersionStatusPresentation('Imechapishwa', 0xFF2E7D32),
    statusRejected: QuizVersionStatusPresentation('Imekataliwa', 0xFFB71C1C),
    statusRetired: QuizVersionStatusPresentation('Imeondolewa', 0xFF8D6E63),
  };

  static String normalizeStatus(String? value) {
    if (statusPresentations.containsKey(value)) return value!;
    return statusDraft;
  }

  static QuizVersionStatusPresentation statusPresentation(String? value) {
    return statusPresentations[normalizeStatus(value)]!;
  }

  static bool isRejected(String? value) => normalizeStatus(value) == statusRejected;

  /// Swahili copy for every backend reason/error code this contract's
  /// endpoints can return — certificate-eligibility `reason_code`s and
  /// quiz-attempt `QuizActionException.code`s share one lookup since a
  /// learner-facing screen may need to render either.
  static const Map<String, String> _reasonCodeMessages = {
    // Certificate eligibility reason codes.
    'NOT_ENROLLED': 'Hujajiandikisha kwenye kozi hii.',
    'LESSONS_INCOMPLETE': 'Kamilisha masomo yote kabla ya kuendelea.',
    'QUIZ_NOT_ATTEMPTED': 'Bado hujafanya mtihani wa mwisho wa kozi hii.',
    'QUIZ_COOLDOWN_ACTIVE':
        'Umeshindwa mtihani mara ya mwisho. Subiri muda uliobaki kabla ya kujaribu tena.',
    'ELIGIBLE_LESSONS_ONLY': 'Umekamilisha masomo yote. Unastahili cheti.',
    'ELIGIBLE_QUIZ_PASSED': 'Umefaulu mtihani. Unastahili cheti.',
    'ELIGIBLE_EXEMPTION': 'Unastahili cheti.',
    // Quiz-attempt action error codes.
    'QUIZ_NOT_AVAILABLE': 'Mtihani wa kozi hii haupatikani kwa sasa.',
    'COOLDOWN_ACTIVE':
        'Umeshindwa mtihani mara ya mwisho. Subiri muda uliobaki kabla ya kujaribu tena.',
    'ATTEMPT_NOT_IN_PROGRESS': 'Jaribio hili halipo tena katika hali ya kuendelea.',
    'QUIZ_EMPTY': 'Mtihani huu haujawa na maswali.',
  };

  static String reasonCodeMessage(String? code, {String? fallback}) {
    if (code == null || code.isEmpty) {
      return fallback ?? 'Huna ruhusa ya kupata cheti kwa sasa.';
    }
    return _reasonCodeMessages[code] ?? fallback ?? 'Huna ruhusa ya kupata cheti kwa sasa.';
  }

  /// Human-readable remaining-cooldown copy, or null once it has expired.
  static String? formatCooldownRemaining(DateTime? cooldownExpiresAt) {
    if (cooldownExpiresAt == null) return null;
    final remaining = cooldownExpiresAt.difference(DateTime.now());
    if (remaining.isNegative) return null;
    if (remaining.inMinutes < 1) {
      return 'Unaweza kujaribu tena baada ya sekunde ${remaining.inSeconds}.';
    }
    if (remaining.inHours < 1) {
      return 'Unaweza kujaribu tena baada ya dakika ${remaining.inMinutes}.';
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return 'Unaweza kujaribu tena baada ya saa $hours dakika $minutes.';
  }

  static QuizValidationResult validatePassingScore(int passingScore) {
    if (passingScore < minPassingScore || passingScore > maxPassingScore) {
      return const QuizValidationResult({
        'passing_score':
            'Alama ya kufaulu lazima iwe kati ya $minPassingScore na $maxPassingScore.',
      });
    }
    return const QuizValidationResult({});
  }

  static QuizValidationResult validateQuestion(QuizDraftQuestionInput question) {
    final errors = <String, String>{};
    if (question.question.trim().isEmpty) {
      errors['question'] = 'Jaza swali.';
    }
    if (question.options.length != requiredOptionCount) {
      errors['options'] = 'Swali linahitaji chaguo $requiredOptionCount kamili.';
    } else if (question.options.any((o) => o.trim().isEmpty)) {
      errors['options'] = 'Jaza chaguo zote $requiredOptionCount.';
    }
    if (question.correctAnswer < 0 ||
        question.correctAnswer >= question.options.length) {
      errors['correct_answer'] = 'Chagua jibu sahihi.';
    }
    return QuizValidationResult(errors);
  }

  static QuizValidationResult validateDraft({
    required int passingScore,
    required List<QuizDraftQuestionInput> questions,
  }) {
    final scoreResult = validatePassingScore(passingScore);
    if (!scoreResult.isValid) return scoreResult;
    if (questions.isEmpty) {
      return const QuizValidationResult(
        {'questions': 'Ongeza angalau swali moja.'},
      );
    }
    for (final question in questions) {
      final result = validateQuestion(question);
      if (!result.isValid) return result;
    }
    return const QuizValidationResult({});
  }
}
