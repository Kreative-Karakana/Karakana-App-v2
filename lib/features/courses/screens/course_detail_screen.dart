import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final int courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourseDetail(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingDetail) {
          return Scaffold(
            backgroundColor: AppColors.white,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final course = provider.selectedCourse;
        if (course == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: AppColors.white),
            backgroundColor: AppColors.white,
            body: Center(
              child: Text(
                'Course not found.',
                style: TextStyle(color: AppColors.grey),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: CustomScrollView(
            slivers: [
              // ── Hero app bar (unchanged) ──────────
              _CourseAppBar(
                course: course,
                onWishlistTap: () => provider.toggleWishlist(course.id),
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),

                  // ── Course header card ────────────
                  _CourseHeaderCard(course: course),

                  // ── Price & enrol action ──────────
                  _EnrolSection(
                    course: course,
                    onEnrollFree: () async {
                      await provider.enrollFreeCourse(course.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Successfully enrolled!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    onPayToEnroll: () => context.push(
                      '/payment/${course.id}',
                      extra: {
                        'title': course.title,
                        'price': course.price,
                      },
                    ),
                    onContinueLearning: () =>
                        context.push('/enrolled-courses'),
                  ),

                  // ── About ─────────────────────────
                  _AboutSection(course: course),

                  // ── Curriculum ────────────────────
                  _CurriculumSection(
                    course: course,
                    sections: provider.sections,
                    isLoading: provider.isLoadingSections,
                  ),

                  // ── Reviews ───────────────────────
                  _ReviewsSection(reviews: provider.reviews),

                  const SizedBox(height: 80),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Sliver app bar (hero thumbnail — unchanged)
// ─────────────────────────────────────────────

class _CourseAppBar extends StatelessWidget {
  const _CourseAppBar({required this.course, required this.onWishlistTap});

  final CourseModel course;
  final VoidCallback onWishlistTap;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.dark,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: Icon(
            course.isWishlisted ? Icons.favorite : Icons.favorite_border,
            color: course.isWishlisted ? Colors.redAccent : Colors.white,
          ),
          onPressed: onWishlistTap,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (course.thumbnail != null && course.thumbnail!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: course.thumbnail!,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppColors.lightOrange),
                errorWidget: (_, _, _) =>
                    Container(color: AppColors.lightOrange),
              )
            else
              Container(color: AppColors.dark),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withAlpha(180)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section header (shared style)
// ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Course header card
// ─────────────────────────────────────────────

class _CourseHeaderCard extends StatelessWidget {
  const _CourseHeaderCard({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final level = _formatLevel(course.level);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),

          // Rating + level
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                course.averageRating.toStringAsFixed(1),
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${course.reviewsCount} reviews)',
                style: TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              const Spacer(),
              if (level.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    level,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Trainer + students
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.lightOrange,
                backgroundImage:
                    course.trainerAvatar != null &&
                        course.trainerAvatar!.isNotEmpty
                    ? CachedNetworkImageProvider(course.trainerAvatar!)
                    : null,
                child:
                    (course.trainerAvatar == null ||
                        course.trainerAvatar!.isEmpty)
                    ? Icon(Icons.person, size: 16, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  course.trainerName,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.people_outline, size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(
                '${course.studentsCount} students',
                style: TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Enrol section
// ─────────────────────────────────────────────

class _EnrolSection extends StatelessWidget {
  const _EnrolSection({
    required this.course,
    required this.onEnrollFree,
    required this.onPayToEnroll,
    required this.onContinueLearning,
  });

  final CourseModel course;
  final VoidCallback onEnrollFree;
  final VoidCallback onPayToEnroll;
  final VoidCallback onContinueLearning;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Course Price',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                course.isFree ? 'Free' : _formatPrice(course.price),
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const Spacer(),
          if (course.isEnrolled)
            _EnrollButton(
              label: 'Continue Learning',
              color: Colors.green.shade600,
              onPressed: onContinueLearning,
            )
          else if (course.isFree)
            _EnrollButton(
              label: 'Enroll Free',
              color: AppColors.primary,
              onPressed: onEnrollFree,
            )
          else
            _EnrollButton(
              label: 'Pay to Enroll',
              color: AppColors.dark,
              onPressed: onPayToEnroll,
            ),
        ],
      ),
    );
  }
}

class _EnrollButton extends StatelessWidget {
  const _EnrollButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// About section
// ─────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final description = _parseDescription(course.description);
    if (description.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('About This Course'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            description,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 14,
              fontFamily: 'Inter',
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Curriculum section
// ─────────────────────────────────────────────

class _CurriculumSection extends StatelessWidget {
  const _CurriculumSection({
    required this.course,
    required this.sections,
    required this.isLoading,
  });

  final CourseModel course;
  final List<SectionModel> sections;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Curriculum'),

        if (course.isEnrolled) ...[
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (sections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No curriculum available',
                style: TextStyle(color: AppColors.grey),
              ),
            )
          else
            ...sections.asMap().entries.map(
              (entry) => _SectionTile(
                section: entry.value,
                index: entry.key + 1,
              ),
            ),
        ] else ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enroll to Access Curriculum',
                        style: TextStyle(
                          color: AppColors.dark,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Purchase this course to unlock all sections and lessons',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section, required this.index});

  final SectionModel section;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.lightOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            section.title,
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          subtitle: Text(
            '${section.lessons.length} lessons',
            style: TextStyle(color: AppColors.grey, fontSize: 12),
          ),
          children: section.lessons.map((l) => _LessonRow(lesson: l)).toList(),
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson});

  final LessonModel lesson;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            lesson.hasVideo
                ? Icons.play_circle_outline
                : Icons.article_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lesson.title,
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Icon(
            lesson.isRead ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: lesson.isRead ? Colors.green : AppColors.grey,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reviews section
// ─────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews});

  final List<ReviewModel> reviews;

  @override
  Widget build(BuildContext context) {
    final displayed = reviews.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Reviews'),

        if (displayed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No reviews yet',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
          )
        else
          ...displayed.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer row: avatar + name + stars + date
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.lightOrange,
                backgroundImage:
                    review.userAvatar != null && review.userAvatar!.isNotEmpty
                    ? CachedNetworkImageProvider(review.userAvatar!)
                    : null,
                child:
                    (review.userAvatar == null || review.userAvatar!.isEmpty)
                    ? Icon(Icons.person, size: 18, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: i < review.rating
                              ? Colors.amber
                              : AppColors.grey.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (review.createdAt.isNotEmpty)
                Text(
                  _formatDate(review.createdAt),
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Review content
          Text(
            review.content,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              fontFamily: 'Inter',
              height: 1.5,
            ),
          ),

          // Trainer reply
          if (review.trainerReply != null &&
              review.trainerReply!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trainer reply',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.trainerReply!,
                    style: TextStyle(
                      color: AppColors.dark,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

String _parseDescription(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map && decoded.containsKey('ops')) {
      final ops = decoded['ops'] as List;
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map && op.containsKey('insert')) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          }
        }
      }
      return buffer.toString().trim();
    }
    return raw;
  } catch (e) {
    return raw;
  }
}

String _formatLevel(String level) {
  switch (level.toLowerCase()) {
    case 'bgn':
    case 'beginner':
      return 'Beginner';
    case 'int':
    case 'intermediate':
      return 'Intermediate';
    case 'adv':
    case 'advanced':
      return 'Advanced';
    case 'all':
    case 'all_levels':
      return 'All Levels';
    case 'sht':
    case 'short':
      return 'Short Course';
    case 'pro':
    case 'professional':
      return 'Professional';
    default:
      return level.isEmpty ? '' : level;
  }
}

String _formatPrice(double price) {
  final formatter = NumberFormat('#,###', 'en_US');
  return 'TZS ${formatter.format(price)}';
}
