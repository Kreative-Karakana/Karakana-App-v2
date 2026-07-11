import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/trainer/utils/trainer_course_filters.dart';

void main() {
  group('TrainerCourseFilters', () {
    test('owned course query does not use learner enrollment filtering', () {
      expect(
        TrainerCourseFilters.ownedCoursesQueryParameters,
        isNot(contains('enrolled')),
      );
      expect(
          TrainerCourseFilters.ownedCoursesQueryParameters['page_size'], 100);
    });

    test('keeps only courses owned by the current trainer from paginated data',
        () {
      final courses = TrainerCourseFilters.ownedCoursesFromResponse({
        'results': [
          _course(1, 'draft', isOwner: true),
          _course(2, 'pending_review', isOwner: true),
          _course(3, 'published', isOwner: true),
          _course(4, 'rejected', isOwner: true),
          _course(5, 'published', isOwner: false),
        ],
      });

      expect(courses.map((course) => course['id']), [1, 2, 3, 4]);
      expect(courses.map((course) => course['status']), [
        'draft',
        'pending_review',
        'published',
        'rejected',
      ]);
    });

    test('returns no course when ownership metadata is absent', () {
      final courses = TrainerCourseFilters.ownedCoursesFromResponse([
        {'id': 1, 'status': 'published'},
        {
          'id': 2,
          'status': 'published',
          'trainer': {'is_owner': false},
        },
      ]);

      expect(courses, isEmpty);
    });
  });
}

Map<String, dynamic> _course(int id, String status, {required bool isOwner}) {
  return {
    'id': id,
    'status': status,
    'trainer': {'is_owner': isOwner},
  };
}
