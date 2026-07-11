import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/trainer/utils/course_contract.dart';

void main() {
  group('CourseContract', () {
    test('exposes backend-supported level values', () {
      expect(
        CourseContract.levelOptions.map((option) => option.value),
        ['beginner', 'intermediate', 'advanced', 'short_course'],
      );
      expect(CourseContract.levelLabel('short_course'), 'Kozi Fupi');
      expect(CourseContract.normalizeLevel('unsupported'), 'beginner');
    });

    test('supports all backend course statuses', () {
      expect(CourseContract.statusPresentation('draft').label, 'Rasimu');
      expect(
        CourseContract.statusPresentation('pending_review').label,
        'Inasubiri Ukaguzi',
      );
      expect(
        CourseContract.statusPresentation('published').label,
        'Imechapishwa',
      );
      expect(
          CourseContract.statusPresentation('rejected').label, 'Imekataliwa');
      expect(CourseContract.normalizeStatus('unsupported'), 'draft');
    });

    test('validates required fields and invalid price', () {
      final result = CourseContract.validatePayloadInput(
        const CoursePayloadInput(
          title: '',
          description: '',
          priceText: 'abc',
          level: 'beginner',
          categoryId: '',
          status: 'pending_review',
        ),
        requireCategory: true,
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors.keys,
          containsAll(['title', 'description', 'category', 'price']));
    });

    test('rejects unsupported lifecycle values in builder payloads', () {
      final result = CourseContract.validatePayloadInput(
        const CoursePayloadInput(
          title: 'Course',
          description: 'Description',
          priceText: '0',
          level: 'beginner',
          categoryId: '1',
          status: 'published',
        ),
        requireCategory: true,
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors['status'], isNotNull);
    });

    test('builds backend-compatible create and update payload', () {
      final payload = CourseContract.buildPayload(
        const CoursePayloadInput(
          title: '  Course title  ',
          description: '  Course description  ',
          priceText: '15000',
          level: 'short_course',
          categoryId: '7',
          status: 'pending_review',
        ),
      );

      expect(payload, {
        'title': 'Course title',
        'description': 'Course description',
        'price': 15000.0,
        'level': 'short_course',
        'status': 'pending_review',
        'category': 7,
      });
    });
  });
}
