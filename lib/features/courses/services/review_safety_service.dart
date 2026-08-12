import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

enum ReviewTargetPart { review, reply }

extension ReviewTargetPartApi on ReviewTargetPart {
  String get apiValue => name;
}

enum ReviewReportReason { harassment, hate, sexual, violence, spam, other }

extension ReviewReportReasonCopy on ReviewReportReason {
  String get label {
    switch (this) {
      case ReviewReportReason.harassment:
        return 'Unyanyasaji au uonevu';
      case ReviewReportReason.hate:
        return 'Chuki au ubaguzi';
      case ReviewReportReason.sexual:
        return 'Maudhui ya kingono au yasiyofaa';
      case ReviewReportReason.violence:
        return 'Vurugu au vitisho';
      case ReviewReportReason.spam:
        return 'Taka au taarifa za kupotosha';
      case ReviewReportReason.other:
        return 'Sababu nyingine';
    }
  }
}

enum ReviewSafetyAction {
  reportReview,
  blockReviewAuthor,
  unblockReviewAuthor,
  reportReply,
  blockReplyAuthor,
  unblockReplyAuthor,
}

List<ReviewSafetyAction> reviewSafetyActions({
  required bool isOwner,
  required bool isTrainer,
  required bool hasTrainerReply,
  required bool isReviewAuthorBlocked,
  required bool isReplyAuthorBlocked,
}) {
  final actions = <ReviewSafetyAction>[];
  if (isReviewAuthorBlocked) {
    actions.add(ReviewSafetyAction.unblockReviewAuthor);
  } else if (!isOwner) {
    actions.addAll(const [
      ReviewSafetyAction.reportReview,
      ReviewSafetyAction.blockReviewAuthor,
    ]);
  }
  if (hasTrainerReply || isReplyAuthorBlocked) {
    if (isReplyAuthorBlocked) {
      actions.add(ReviewSafetyAction.unblockReplyAuthor);
    } else if (!isTrainer) {
      actions.addAll(const [
        ReviewSafetyAction.reportReply,
        ReviewSafetyAction.blockReplyAuthor,
      ]);
    }
  }
  return actions;
}

class ReviewSafetyService {
  final Dio _dio;

  ReviewSafetyService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  String _base(int courseId, int reviewId) =>
      '/api/v1/courses/$courseId/reviews/$reviewId';

  Future<void> report({
    required int courseId,
    required int reviewId,
    required ReviewTargetPart targetPart,
    required ReviewReportReason reason,
    String detail = '',
  }) async {
    try {
      await _dio.post(
        '${_base(courseId, reviewId)}/reports/',
        data: {
          'target_part': targetPart.apiValue,
          'reason': reason.name,
          'detail': detail.trim(),
        },
      );
    } catch (error) {
      throw ApiClient().parseError(error);
    }
  }

  Future<void> block({
    required int courseId,
    required int reviewId,
    required ReviewTargetPart targetPart,
  }) async {
    try {
      await _dio.post(
        '${_base(courseId, reviewId)}/block/',
        data: {'target_part': targetPart.apiValue},
      );
    } catch (error) {
      throw ApiClient().parseError(error);
    }
  }

  Future<void> unblock({
    required int courseId,
    required int reviewId,
    required ReviewTargetPart targetPart,
  }) async {
    try {
      await _dio.delete(
        '${_base(courseId, reviewId)}/block/',
        data: {'target_part': targetPart.apiValue},
      );
    } catch (error) {
      throw ApiClient().parseError(error);
    }
  }
}
