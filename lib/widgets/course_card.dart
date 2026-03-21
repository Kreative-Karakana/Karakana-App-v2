import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/courses/models/course_model.dart';

/// A reusable course card used on the home, explore, search, and wishlist
/// screens. Displays thumbnail, title, trainer, rating, level, price, and
/// enrolment/wishlist state.
class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.onWishlistTap,
  });

  final CourseModel course;
  final VoidCallback onTap;

  /// Called when the user taps the heart icon. If null, the button is hidden.
  final VoidCallback? onWishlistTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        color: AppColors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(course: course, onWishlistTap: onWishlistTap),
            _CourseInfo(course: course),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Thumbnail section
// ─────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.course, this.onWishlistTap});

  final CourseModel course;
  final VoidCallback? onWishlistTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Course thumbnail image ───────────
          _buildImage(),

          // ── Status badge (Enrolled / Free) ───
          Positioned(top: 10, left: 10, child: _buildStatusBadge()),

          // ── Wishlist heart button ─────────────
          if (onWishlistTap != null)
            Positioned(
              top: 4,
              right: 4,
              child: _WishlistButton(
                isWishlisted: course.isWishlisted,
                onTap: onWishlistTap!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (course.thumbnail == null || course.thumbnail!.isEmpty) {
      return _placeholder();
    }

    return CachedNetworkImage(
      imageUrl: course.thumbnail!,
      fit: BoxFit.cover,
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.lightOrange,
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          color: AppColors.primary,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (course.isEnrolled) {
      return _Badge(label: 'Enrolled', backgroundColor: Colors.green.shade600);
    }
    if (course.isFree) {
      return _Badge(label: 'Free', backgroundColor: AppColors.primary);
    }
    return const SizedBox.shrink();
  }
}

/// Small pill badge placed over the thumbnail.
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.backgroundColor});

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Semi-transparent heart button overlaid on the thumbnail.
class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.isWishlisted, required this.onTap});

  final bool isWishlisted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(90),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isWishlisted ? Icons.favorite : Icons.favorite_border,
          color: isWishlisted ? Colors.redAccent : Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info section
// ─────────────────────────────────────────────

class _CourseInfo extends StatelessWidget {
  const _CourseInfo({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ────────────────────────────
          Text(
            course.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.dark,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // ── Trainer name ─────────────────────
          Row(
            children: [
              Icon(Icons.person_outline, size: 12, color: AppColors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  course.trainerName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Rating + Level ───────────────────
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text(
                course.averageRating.toStringAsFixed(1),
                style: TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                '(${course.reviewsCount})',
                style: TextStyle(color: AppColors.grey, fontSize: 11),
              ),
              const Spacer(),
              _LevelBadge(level: course.level),
            ],
          ),

          const SizedBox(height: 8),

          // ── Price + Students count ────────────
          Row(
            children: [
              Text(
                course.isFree
                    ? 'Free'
                    : 'TZS ${course.price.toStringAsFixed(0)}',
                style: TextStyle(
                  color: course.isFree ? AppColors.primary : AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(Icons.people_outline, size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(
                '${course.studentsCount} students',
                style: TextStyle(color: AppColors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small pill badge showing the course difficulty level.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final String level;

  String get _label =>
      level.isEmpty ? '' : '${level[0].toUpperCase()}${level.substring(1)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
