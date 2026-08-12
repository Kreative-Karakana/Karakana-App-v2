import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/courses/models/course_model.dart';
import 'package:karakana_app/features/courses/services/review_safety_service.dart';

void main() {
  group('Review safety API', () {
    late Dio dio;
    late List<RequestOptions> requests;
    late ReviewSafetyService service;

    setUp(() {
      requests = [];
      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<void>(requestOptions: options, statusCode: 200),
            );
          },
        ),
      );
      service = ReviewSafetyService(dio: dio);
    });

    test(
      'report sends only target, supported reason, and trimmed detail',
      () async {
        await service.report(
          courseId: 4,
          reviewId: 9,
          targetPart: ReviewTargetPart.reply,
          reason: ReviewReportReason.harassment,
          detail: '  maelezo  ',
        );

        expect(requests.single.method, 'POST');
        expect(requests.single.path, '/api/v1/courses/4/reviews/9/reports/');
        expect(requests.single.data, {
          'target_part': 'reply',
          'reason': 'harassment',
          'detail': 'maelezo',
        });
        expect((requests.single.data as Map).containsKey('reporter'), isFalse);
      },
    );

    test(
      'block and unblock are review scoped and never send user identity',
      () async {
        await service.block(
          courseId: 4,
          reviewId: 9,
          targetPart: ReviewTargetPart.review,
        );
        await service.unblock(
          courseId: 4,
          reviewId: 9,
          targetPart: ReviewTargetPart.review,
        );

        expect(requests.map((request) => request.method), ['POST', 'DELETE']);
        for (final request in requests) {
          expect(request.path, '/api/v1/courses/4/reviews/9/block/');
          expect(request.data, {'target_part': 'review'});
          expect((request.data as Map).containsKey('blocker'), isFalse);
          expect((request.data as Map).containsKey('blocked'), isFalse);
        }
      },
    );
  });

  group('Review safety presentation contract', () {
    test('parses the real backend review and moderation flags', () {
      final review = ReviewModel.fromJson({
        'id': 9,
        'first_name': 'Asha',
        'last_name': 'Juma',
        'avatar': 'https://example.test/avatar.png',
        'rating': 4,
        'content': 'Kozi nzuri',
        'reply': 'Asante',
        'updated_at': 'dakika 2 zilizopita',
        'is_owner': false,
        'is_trainer': false,
        'has_trainer_reply': true,
        'is_review_author_blocked': false,
        'is_reply_author_blocked': true,
      });

      expect(review.userName, 'Asha Juma');
      expect(review.userAvatar, 'https://example.test/avatar.png');
      expect(review.trainerReply, 'Asante');
      expect(review.createdAt, 'dakika 2 zilizopita');
      expect(review.hasTrainerReply, isTrue);
      expect(review.isReplyAuthorBlocked, isTrue);
    });

    test('offers report/block actions and discoverable unblock actions', () {
      expect(
        reviewSafetyActions(
          isOwner: false,
          isTrainer: false,
          hasTrainerReply: true,
          isReviewAuthorBlocked: false,
          isReplyAuthorBlocked: false,
        ),
        containsAll(const [
          ReviewSafetyAction.reportReview,
          ReviewSafetyAction.blockReviewAuthor,
          ReviewSafetyAction.reportReply,
          ReviewSafetyAction.blockReplyAuthor,
        ]),
      );
      expect(
        reviewSafetyActions(
          isOwner: false,
          isTrainer: false,
          hasTrainerReply: false,
          isReviewAuthorBlocked: true,
          isReplyAuthorBlocked: true,
        ),
        const [
          ReviewSafetyAction.unblockReviewAuthor,
          ReviewSafetyAction.unblockReplyAuthor,
        ],
      );
    });

    test('does not offer self-block actions', () {
      final actions = reviewSafetyActions(
        isOwner: true,
        isTrainer: true,
        hasTrainerReply: true,
        isReviewAuthorBlocked: false,
        isReplyAuthorBlocked: false,
      );
      expect(actions, isEmpty);
    });
  });
}
