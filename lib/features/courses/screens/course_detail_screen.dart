import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';

/// Full course detail screen — description, curriculum, reviews, and enrolment.
///
/// Navigate to this screen by pushing `/courses/:id` with [courseId].
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
          backgroundColor: AppColors.white,
          body: CustomScrollView(
            slivers: [
              // ── Hero app bar ──────────────────────────
              _CourseAppBar(
                course: course,
                onWishlistTap: () => provider.toggleWishlist(course.id),
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  // ── Header (title, rating, trainer) ───
                  _CourseHeader(course: course),
                  const Divider(height: 1),

                  // ── Price & enrol action ──────────────
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
                    onPayToEnroll: () => context.push('/payment/${course.id}'),
                    onContinueLearning: () =>
                        context.push('/classroom/${course.id}'),
                  ),
                  const Divider(height: 1),

                  // ── About ─────────────────────────────
                  _AboutSection(course: course),

                  // ── Curriculum ────────────────────────
                  _CurriculumSection(
                    sections: provider.sections,
                    isLoading: provider.isLoadingSections,
                  ),

                  // ── Reviews ───────────────────────────
                  _ReviewsSection(reviews: provider.reviews),

                  // Bottom clearance so content doesn't hide behind nav bar.
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
// Sliver app bar (hero thumbnail)
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
            // Thumbnail image
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

            // Dark gradient overlay for legibility
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
// Course header
// ─────────────────────────────────────────────

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final level = course.level.isEmpty
        ? ''
        : '${course.level[0].toUpperCase()}${course.level.substring(1)}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            course.title,
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 8),

          // Rating + level
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                course.averageRating.toStringAsFixed(1),
                style: TextStyle(color: AppColors.grey, fontSize: 13),
              ),
              const SizedBox(width: 4),
              Text(
                '(${course.reviewsCount})',
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
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Trainer + students count
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
              const SizedBox(width: 8),
              Icon(Icons.people_outline, size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(
                '${course.studentsCount} students',
                style: TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Excerpt
          Text(
            course.excerpt,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 14,
              fontFamily: 'Inter',
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Price display
          Text(
            course.isFree ? 'Free' : 'TZS ${course.price.toStringAsFixed(0)}',
            style: TextStyle(
              color: course.isFree ? AppColors.primary : AppColors.dark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),

          const Spacer(),

          // Action button
          if (course.isEnrolled)
            ElevatedButton(
              onPressed: onContinueLearning,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Continue Learning'),
            )
          else if (course.isFree)
            ElevatedButton(
              onPressed: onEnrollFree,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Enroll Free'),
            )
          else
            ElevatedButton(
              onPressed: onPayToEnroll,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Pay to Enroll'),
            ),
        ],
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Course',
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course.description,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 14,
              fontFamily: 'Inter',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Curriculum section
// ─────────────────────────────────────────────

class _CurriculumSection extends StatelessWidget {
  const _CurriculumSection({required this.sections, required this.isLoading});

  final List<SectionModel> sections;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Curriculum',
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),

          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            ...sections.map((section) => _SectionTile(section: section)),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section});

  final SectionModel section;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Remove default leading icon indentation from ExpansionTile.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
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
    // Show at most 3 reviews to keep the screen manageable.
    final displayed = reviews.take(3).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviews',
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),

          if (displayed.isEmpty)
            Center(
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
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reviewer row
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.lightOrange,
                  backgroundImage:
                      review.userAvatar != null && review.userAvatar!.isNotEmpty
                      ? CachedNetworkImageProvider(review.userAvatar!)
                      : null,
                  child:
                      (review.userAvatar == null || review.userAvatar!.isEmpty)
                      ? Icon(Icons.person, size: 16, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.userName,
                    style: TextStyle(
                      color: AppColors.dark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Star rating
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: i < review.rating ? Colors.amber : AppColors.grey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Review content
            Text(
              review.content,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 13,
                fontFamily: 'Inter',
                height: 1.4,
              ),
            ),

            // Trainer reply
            if (review.trainerReply != null &&
                review.trainerReply!.isNotEmpty) ...[
              const SizedBox(height: 8),
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
      ),
    );
  }
}
