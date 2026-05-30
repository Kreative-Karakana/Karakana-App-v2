import '../../courses/models/course_model.dart';

class TrainerStats {
  final int totalCourses;
  final int totalStudents;
  final int totalViews;
  final int newStudents;
  final double completionRate;
  final double avgRating;
  final int totalReviews;
  final double viewsTrend;
  final double studentTrend;

  const TrainerStats({
    required this.totalCourses,
    required this.totalStudents,
    required this.totalViews,
    required this.newStudents,
    required this.completionRate,
    required this.avgRating,
    required this.totalReviews,
    required this.viewsTrend,
    required this.studentTrend,
  });

  factory TrainerStats.fromJson(Map<String, dynamic> json) {
    return TrainerStats(
      totalCourses: json['total_courses'] ?? 0,
      totalStudents: json['total_students'] ?? 0,
      totalViews: json['total_views'] ?? 0,
      newStudents: json['new_students'] ?? 0,
      completionRate: _toDouble(json['completion_rate']),
      avgRating: _toDouble(json['avg_rating']),
      totalReviews: json['total_reviews'] ?? 0,
      viewsTrend: _toDouble(json['views_trend']),
      studentTrend: _toDouble(json['student_trend']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_courses': totalCourses,
      'total_students': totalStudents,
      'total_views': totalViews,
      'new_students': newStudents,
      'completion_rate': completionRate,
      'avg_rating': avgRating,
      'total_reviews': totalReviews,
      'views_trend': viewsTrend,
      'student_trend': studentTrend,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class TrainerCourse extends CourseModel {
  final int draftLessonCount;
  final int publishedLessonCount;
  final int enrolledStudents;
  final double revenue;

  TrainerCourse({
    required super.id,
    required super.title,
    required super.excerpt,
    required super.description,
    required super.price,
    required super.status,
    required super.level,
    super.coverPhoto,
    super.playbackUrl,
    required super.trainerName,
    super.trainerAvatar,
    required super.trainerId,
    required super.studentCount,
    required super.averageRating,
    required super.reviewCount,
    required super.isEnrolled,
    required super.isWishlisted,
    required super.categories,
    required super.faqs,
    required this.draftLessonCount,
    required this.publishedLessonCount,
    required this.enrolledStudents,
    required this.revenue,
  });

  bool get isPublished => status == 'published';

  factory TrainerCourse.fromJson(Map<String, dynamic> json) {
    final course = CourseModel.fromJson(json);
    return TrainerCourse(
      id: course.id,
      title: course.title,
      excerpt: course.excerpt,
      description: course.description,
      price: course.price,
      status: course.status,
      level: course.level,
      coverPhoto: course.coverPhoto,
      playbackUrl: course.playbackUrl,
      trainerName: course.trainerName,
      trainerAvatar: course.trainerAvatar,
      trainerId: course.trainerId,
      studentCount: course.studentCount,
      averageRating: course.averageRating,
      reviewCount: course.reviewCount,
      isEnrolled: course.isEnrolled,
      isWishlisted: course.isWishlisted,
      categories: course.categories,
      faqs: course.faqs,
      draftLessonCount: json['draft_lesson_count'] ?? 0,
      publishedLessonCount: json['published_lesson_count'] ?? 0,
      enrolledStudents: json['enrolled_students'] ?? course.studentCount,
      revenue: TrainerStats._toDouble(json['revenue']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final base = super.toJson();
    base.addAll({
      'draft_lesson_count': draftLessonCount,
      'published_lesson_count': publishedLessonCount,
      'enrolled_students': enrolledStudents,
      'revenue': revenue,
    });
    return base;
  }
}
