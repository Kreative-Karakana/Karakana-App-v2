import 'package:intl/intl.dart';

class CategoryModel {
  final int id;
  final String name;
  final int? parentId;

  CategoryModel({required this.id, required this.name, this.parentId});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      parentId: json['parent'],
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'parent': parentId};
}

class CourseModel {
  final int id;
  final String title;
  final String excerpt;
  final String description;
  final double price;
  final String status;
  final String level;
  final String? coverPhoto;
  final String? playbackUrl;
  final String? appleIapProductId;
  final String trainerName;
  final String? trainerAvatar;
  final int trainerId;
  final int studentCount;
  final double averageRating;
  final int reviewCount;
  bool isEnrolled;
  bool isWishlisted;
  final List<String> categories;
  final List<CourseFaqModel> faqs;

  CourseModel({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.description,
    required this.price,
    required this.status,
    required this.level,
    this.coverPhoto,
    this.playbackUrl,
    this.appleIapProductId,
    required this.trainerName,
    this.trainerAvatar,
    required this.trainerId,
    required this.studentCount,
    required this.averageRating,
    required this.reviewCount,
    required this.isEnrolled,
    required this.isWishlisted,
    required this.categories,
    required this.faqs,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final trainer = json['trainer'];
    String trainerName = '';
    String? trainerAvatar;
    int trainerId = 0;
    if (trainer is Map) {
      trainerName =
          '${trainer['first_name'] ?? ''} ${trainer['last_name'] ?? ''}'.trim();
      trainerAvatar = trainer['avatar']?.toString();
      trainerId = trainer['id'] ?? 0;
    }

    final cats = json['categories'];
    List<String> categories = [];
    if (cats is List) {
      categories = cats.map((c) {
        if (c is Map) return c['name']?.toString() ?? '';
        return c.toString();
      }).where((s) => s.isNotEmpty).toList();
    }

    final rawFaqs = json['faqs'];
    List<CourseFaqModel> faqs = [];
    if (rawFaqs is List) {
      faqs = rawFaqs
          .whereType<Map>()
          .map((f) => CourseFaqModel.fromJson(Map<String, dynamic>.from(f)))
          .where((f) => f.question.isNotEmpty || f.answer.isNotEmpty)
          .toList();
    }

    return CourseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      excerpt: json['excerpt'] ?? '',
      description: json['description'] ?? '',
      price: _parseDouble(json['price']),
      status: json['status'] ?? '',
      level: json['level'] ?? '',
      coverPhoto: json['cover_photo']?.toString(),
      playbackUrl: json['playback_url']?.toString(),
      appleIapProductId: json['apple_iap_product_id']?.toString(),
      trainerName: trainerName,
      trainerAvatar: trainerAvatar,
      trainerId: trainerId,
      studentCount: json['student_count'] ?? 0,
      averageRating: _parseDouble(json['average_rating']),
      reviewCount: json['review_count'] ?? 0,
      isEnrolled: json['is_enrolled'] ?? false,
      isWishlisted: json['is_in_wishlist'] ?? false,
      categories: categories,
      faqs: faqs,
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'level': level,
        'cover_photo': coverPhoto,
        'apple_iap_product_id': appleIapProductId,
        'is_enrolled': isEnrolled,
        'is_in_wishlist': isWishlisted,
        'faqs': faqs.map((f) => f.toJson()).toList(),
      };

  bool get isFree => price == 0;

  String get formattedPrice =>
      isFree ? 'BURE' : 'TZS ${NumberFormat('#,###').format(price)}';

  String get formattedLevel {
    switch (level.toUpperCase()) {
      case 'BGN':
        return 'Beginner';
      case 'INT':
        return 'Intermediate';
      case 'ADV':
        return 'Advanced';
      case 'SHT':
        return 'Short Course';
      case 'PRO':
        return 'Professional';
      case 'ALL':
        return 'All Levels';
      default:
        return level.isNotEmpty ? level : 'All Levels';
    }
  }
}

class CourseFaqModel {
  final String question;
  final String answer;

  CourseFaqModel({required this.question, required this.answer});

  factory CourseFaqModel.fromJson(Map<String, dynamic> json) {
    final answerRaw = json['answer'];
    final answer = answerRaw is Map
        ? (answerRaw['delta']?.toString() ?? answerRaw.toString())
        : (answerRaw?.toString() ?? '');
    return CourseFaqModel(
      question: json['question']?.toString() ?? '',
      answer: answer,
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };
}

class BannerModel {
  final int id;
  final String title;
  final String? ctaText;
  final String? image;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.title,
    this.ctaText,
    this.image,
    required this.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      ctaText: json['cta_text']?.toString(),
      image: json['image']?.toString(),
      isActive: json['is_active'] ?? true,
    );
  }
}

class SectionModel {
  final int id;
  final String title;
  final int ordering;
  final List<LessonModel> lessons;

  SectionModel({
    required this.id,
    required this.title,
    required this.ordering,
    required this.lessons,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'];
    final lessons = rawLessons is List
        ? rawLessons.map((l) => LessonModel.fromJson(l as Map<String, dynamic>)).toList()
        : <LessonModel>[];
    return SectionModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      ordering: json['ordering'] ?? 0,
      lessons: lessons,
    );
  }
}

class LessonModel {
  final int id;
  final String title;
  final String? content;
  final int ordering;
  final bool hasVideo;
  bool isRead;

  LessonModel({
    required this.id,
    required this.title,
    this.content,
    required this.ordering,
    required this.hasVideo,
    required this.isRead,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content']?.toString(),
      ordering: json['index'] ?? json['ordering'] ?? 0,
      hasVideo: json['has_video'] ?? false,
      isRead: json['is_completed'] ?? json['is_read'] ?? false,
    );
  }
}

class ReviewModel {
  final int id;
  final String userName;
  final String? userAvatar;
  final int rating;
  final String content;
  final String? trainerReply;
  final String createdAt;

  ReviewModel({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.content,
    this.trainerReply,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String userName = '';
    String? userAvatar;
    if (user is Map) {
      userName =
          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
      userAvatar = user['avatar']?.toString();
    } else {
      userName = json['user_name']?.toString() ?? '';
    }
    return ReviewModel(
      id: json['id'] ?? 0,
      userName: userName,
      userAvatar: userAvatar,
      rating: json['rating'] ?? 0,
      content: json['content'] ?? '',
      trainerReply: json['trainer_reply']?.toString(),
      createdAt: json['created_at'] ?? '',
    );
  }
}
