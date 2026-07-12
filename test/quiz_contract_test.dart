import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/courses/models/quiz_model.dart';
import 'package:karakana_app/features/courses/utils/quiz_contract.dart';

void main() {
  group('QuizContract status presentation', () {
    test('supports every backend quiz version status', () {
      expect(QuizContract.statusPresentation('draft').label, 'Rasimu');
      expect(
        QuizContract.statusPresentation('pending_review').label,
        'Inasubiri Ukaguzi',
      );
      expect(
        QuizContract.statusPresentation('published').label,
        'Imechapishwa',
      );
      expect(
        QuizContract.statusPresentation('rejected').label,
        'Imekataliwa',
      );
      expect(
        QuizContract.statusPresentation('retired').label,
        'Imeondolewa',
      );
      expect(QuizContract.normalizeStatus('unsupported'), 'draft');
    });

    test('identifies rejected status', () {
      expect(QuizContract.isRejected('rejected'), isTrue);
      expect(QuizContract.isRejected('draft'), isFalse);
    });
  });

  group('QuizContract reason code messages', () {
    test('maps every certificate-eligibility reason code to copy', () {
      for (final code in [
        'NOT_ENROLLED',
        'LESSONS_INCOMPLETE',
        'QUIZ_NOT_ATTEMPTED',
        'QUIZ_COOLDOWN_ACTIVE',
        'ELIGIBLE_LESSONS_ONLY',
        'ELIGIBLE_QUIZ_PASSED',
        'ELIGIBLE_EXEMPTION',
      ]) {
        expect(QuizContract.reasonCodeMessage(code), isNotEmpty);
      }
    });

    test('maps every quiz-attempt action error code to copy', () {
      for (final code in [
        'NOT_ENROLLED',
        'LESSONS_INCOMPLETE',
        'QUIZ_NOT_AVAILABLE',
        'COOLDOWN_ACTIVE',
        'ATTEMPT_NOT_IN_PROGRESS',
        'QUIZ_EMPTY',
      ]) {
        expect(QuizContract.reasonCodeMessage(code), isNotEmpty);
      }
    });

    test('falls back to a generic message for an unknown or null code', () {
      expect(QuizContract.reasonCodeMessage(null), isNotEmpty);
      expect(QuizContract.reasonCodeMessage(''), isNotEmpty);
      expect(QuizContract.reasonCodeMessage('SOMETHING_NEW'), isNotEmpty);
      expect(
        QuizContract.reasonCodeMessage('SOMETHING_NEW', fallback: 'Custom'),
        'Custom',
      );
    });
  });

  group('QuizContract cooldown formatting', () {
    test('returns null once the cooldown has expired', () {
      final past = DateTime.now().subtract(const Duration(minutes: 1));
      expect(QuizContract.formatCooldownRemaining(past), isNull);
      expect(QuizContract.formatCooldownRemaining(null), isNull);
    });

    test('formats remaining cooldown time', () {
      final soon = DateTime.now().add(const Duration(minutes: 30));
      final text = QuizContract.formatCooldownRemaining(soon);
      expect(text, isNotNull);
      expect(text, contains('dakika'));
    });
  });

  group('QuizContract draft validation', () {
    QuizDraftQuestionInput validQuestion({int correctAnswer = 0}) {
      return QuizDraftQuestionInput(
        question: 'Swali?',
        options: const ['A', 'B', 'C', 'D'],
        correctAnswer: correctAnswer,
        explanation: '',
      );
    }

    test('rejects passing score outside 60-100', () {
      expect(QuizContract.validatePassingScore(59).isValid, isFalse);
      expect(QuizContract.validatePassingScore(101).isValid, isFalse);
      expect(QuizContract.validatePassingScore(60).isValid, isTrue);
      expect(QuizContract.validatePassingScore(100).isValid, isTrue);
    });

    test('requires exactly 4 non-empty options', () {
      final tooFew = QuizDraftQuestionInput(
        question: 'Swali?',
        options: const ['A', 'B', 'C'],
        correctAnswer: 0,
      );
      final blank = QuizDraftQuestionInput(
        question: 'Swali?',
        options: const ['A', '', 'C', 'D'],
        correctAnswer: 0,
      );
      expect(QuizContract.validateQuestion(tooFew).isValid, isFalse);
      expect(QuizContract.validateQuestion(blank).isValid, isFalse);
      expect(QuizContract.validateQuestion(validQuestion()).isValid, isTrue);
    });

    test('requires correct_answer to index into options', () {
      expect(
        QuizContract.validateQuestion(validQuestion(correctAnswer: 4)).isValid,
        isFalse,
      );
      expect(
        QuizContract.validateQuestion(validQuestion(correctAnswer: -1)).isValid,
        isFalse,
      );
    });

    test('requires at least one question', () {
      final result =
          QuizContract.validateDraft(passingScore: 70, questions: const []);
      expect(result.isValid, isFalse);
      expect(result.fieldErrors['questions'], isNotNull);
    });

    test('accepts a fully valid draft', () {
      final result = QuizContract.validateDraft(
        passingScore: 70,
        questions: [validQuestion()],
      );
      expect(result.isValid, isTrue);
    });
  });
}
