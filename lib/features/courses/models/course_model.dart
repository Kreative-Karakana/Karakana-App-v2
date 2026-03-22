/// Data models for the Courses feature.
///
/// All models support JSON serialization via [fromJson] and [toJson].
/// Null values are handled safely using the `??` operator with sensible defaults.
library;


// ─────────────────────────────────────────────
// CategoryModel
// ─────────────────────────────────────────────

/// Represents a course category hierarchy node (e.g. "Business" > "Finance").
class CategoryModel {
  const CategoryModel({required this.id, required this.name, this.parentId});

  /// Unique identifier for the category.
  final int id;

  /// Display name of the category.
  final String name;

  /// ID of the parent category, or null if this is a top-level category.
  final int? parentId;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      parentId: json['parent_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'parent_id': parentId,
  };
}

// ─────────────────────────────────────────────
// CourseModel
// ─────────────────────────────────────────────

/// Represents a full course listing as returned by the API.
class CourseModel {
  const CourseModel({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.description,
    required this.price,
    required this.status,
    required this.level,
    required this.isBlocked,
    this.thumbnail,
    this.trailerPlaybackId,
    required this.categories,
    required this.trainerName,
    this.trainerAvatar,
    required this.studentsCount,
    required this.averageRating,
    required this.reviewsCount,
    required this.isEnrolled,
    required this.isWishlisted,
  });

  final int id;
  final String title;

  /// Short marketing description shown in course cards.
  final String excerpt;

  /// Full course description shown on the detail screen.
  final String description;

  /// Price in the local currency (TZS). 0 means the course is free.
  final double price;

  /// Publication status: "published", "draft", etc.
  final String status;

  /// Difficulty level: "beginner", "intermediate", "advanced".
  final String level;

  /// Whether the course is blocked from new enrolments.
  final bool isBlocked;

  /// URL of the course thumbnail image.
  final String? thumbnail;

  /// Mux playback ID for the course trailer video.
  final String? trailerPlaybackId;

  /// List of category names the course belongs to.
  final List<String> categories;

  final String trainerName;
  final String? trainerAvatar;

  /// Total number of enrolled students.
  final int studentsCount;

  /// Average star rating (0.0 – 5.0).
  final double averageRating;

  final int reviewsCount;

  /// Whether the current user is enrolled in the course.
  final bool isEnrolled;

  /// Whether the current user has wishlisted the course.
  final bool isWishlisted;

  /// Returns true when the course is free (price == 0).
  bool get isFree => price == 0;

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final trainer = json['trainer'] as Map<String, dynamic>?;
    final firstName = trainer?['first_name'] as String? ?? '';
    final lastName = trainer?['last_name'] as String? ?? '';
    final trainerName =
        [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    final rawPrice = json['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

    final rawRating = json['average_rating'];
    final averageRating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating?.toString() ?? '') ?? 0.0;

    final rawCategories = json['categories'] as List<dynamic>? ?? [];
    final categories = rawCategories.map((e) {
      if (e is String) return e;
      if (e is Map<String, dynamic>) return e['name'] as String? ?? '';
      return '';
    }).where((s) => s.isNotEmpty).toList();

    return CourseModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: price,
      status: json['status'] as String? ?? '',
      level: json['level'] as String? ?? '',
      isBlocked: json['is_blocked'] as bool? ?? false,
      thumbnail: json['cover_photo'] as String?,
      trailerPlaybackId: json['playback_url'] as String?,
      categories: categories,
      trainerName: trainerName,
      trainerAvatar: trainer?['avatar'] as String?,
      studentsCount: json['student_count'] as int? ?? 0,
      averageRating: averageRating,
      reviewsCount: json['review_count'] as int? ?? 0,
      isEnrolled: json['is_enrolled'] as bool? ?? false,
      isWishlisted: json['is_in_wishlist'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'excerpt': excerpt,
    'description': description,
    'price': price,
    'status': status,
    'level': level,
    'is_blocked': isBlocked,
    'thumbnail': thumbnail,
    'trailer_playback_id': trailerPlaybackId,
    'categories': categories,
    'trainer_name': trainerName,
    'trainer_avatar': trainerAvatar,
    'students_count': studentsCount,
    'average_rating': averageRating,
    'reviews_count': reviewsCount,
    'is_enrolled': isEnrolled,
    'is_wishlisted': isWishlisted,
  };
}

// ─────────────────────────────────────────────
// SectionModel
// ─────────────────────────────────────────────

/// A named section within a course, containing an ordered list of lessons.
class SectionModel {
  const SectionModel({
    required this.id,
    required this.title,
    required this.index,
    required this.lessons,
  });

  final int id;
  final String title;

  /// Zero-based ordering index within the course.
  final int index;

  final List<LessonModel> lessons;

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      index: json['index'] as int? ?? 0,
      lessons:
          (json['lessons'] as List<dynamic>?)
              ?.map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'index': index,
    'lessons': lessons.map((l) => l.toJson()).toList(),
  };
}

// ─────────────────────────────────────────────
// LessonModel
// ─────────────────────────────────────────────

/// A single lesson within a course section.
class LessonModel {
  const LessonModel({
    required this.id,
    required this.title,
    this.content,
    required this.index,
    this.muxPlaybackId,
    required this.isRead,
    this.signedPlaybackUrl,
  });

  final int id;
  final String title;

  /// Optional rich-text body for text-based lessons.
  final String? content;

  /// Zero-based ordering index within the section.
  final int index;

  /// Mux playback ID for video lessons. Null for text-only lessons.
  final String? muxPlaybackId;

  /// Whether the current user has marked this lesson as read/watched.
  final bool isRead;

  /// Signed Mux URL generated server-side for authenticated playback.
  final String? signedPlaybackUrl;

  /// Returns true when the lesson has an associated video.
  bool get hasVideo => muxPlaybackId != null;

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      index: json['index'] as int? ?? 0,
      muxPlaybackId: json['mux_playback_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      signedPlaybackUrl: json['signed_playback_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'index': index,
    'mux_playback_id': muxPlaybackId,
    'is_read': isRead,
    'signed_playback_url': signedPlaybackUrl,
  };
}

// ─────────────────────────────────────────────
// ReviewModel
// ─────────────────────────────────────────────

/// A student review for a course, optionally with a trainer reply.
class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.content,
    this.trainerReply,
    required this.createdAt,
  });

  final int id;
  final String userName;
  final String? userAvatar;

  /// Star rating from 1 to 5.
  final int rating;

  /// The body of the review written by the student.
  final String content;

  /// Optional reply from the course trainer.
  final String? trainerReply;

  /// ISO 8601 timestamp of when the review was submitted.
  final String createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as int? ?? 0,
      userName: json['user_name'] as String? ?? '',
      userAvatar: json['user_avatar'] as String?,
      rating: json['rating'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      trainerReply: json['trainer_reply'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_name': userName,
    'user_avatar': userAvatar,
    'rating': rating,
    'content': content,
    'trainer_reply': trainerReply,
    'created_at': createdAt,
  };
}

// ─────────────────────────────────────────────
// BannerModel
// ─────────────────────────────────────────────

/// A promotional banner displayed on the home / discovery screens.
class BannerModel {
  const BannerModel({
    required this.id,
    required this.title,
    this.ctaText,
    this.ctaRoute,
    this.image,
    this.imageMedium,
    this.imageLarge,
    this.blurHash,
    required this.isActive,
  });

  final int id;
  final String title;

  /// Label for the call-to-action button (e.g. "Enroll Now").
  final String? ctaText;

  /// In-app route path to navigate to when the banner is tapped.
  final String? ctaRoute;

  /// Small/default image URL.
  final String? image;

  /// Medium-resolution image URL for tablets.
  final String? imageMedium;

  /// High-resolution image URL for large displays.
  final String? imageLarge;

  /// BlurHash placeholder string for smooth image loading transitions.
  final String? blurHash;

  /// Whether the banner is currently visible to users.
  final bool isActive;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      ctaText: json['cta_text'] as String?,
      ctaRoute: json['cta_route'] as String?,
      image: json['image'] as String?,
      imageMedium: json['image_medium'] as String?,
      imageLarge: json['image_large'] as String?,
      blurHash: json['blur_hash'] as String?,
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'cta_text': ctaText,
    'cta_route': ctaRoute,
    'image': image,
    'image_medium': imageMedium,
    'image_large': imageLarge,
    'blur_hash': blurHash,
    'is_active': isActive,
  };
}
