import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../features/courses/models/course_model.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.onWishlistTap,
  });

  final CourseModel course;
  final VoidCallback onTap;
  final VoidCallback? onWishlistTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageSection(course: course, onWishlistTap: onWishlistTap),
            _InfoSection(course: course),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Image section
// ─────────────────────────────────────────────

class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.course, this.onWishlistTap});

  final CourseModel course;
  final VoidCallback? onWishlistTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(),
            if (course.isEnrolled)
              Positioned(
                top: 8,
                left: 8,
                child: _Badge(label: 'Enrolled', color: Colors.green.shade600),
              )
            else if (course.isFree)
              Positioned(
                top: 8,
                left: 8,
                child: _Badge(label: 'Free', color: AppColors.primary),
              ),
            Positioned(
              top: 2,
              right: 2,
              child: _WishlistButton(
                isWishlisted: course.isWishlisted,
                onTap: onWishlistTap,
              ),
            ),
          ],
        ),
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
          size: 40,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.isWishlisted, this.onTap});

  final bool isWishlisted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(70),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isWishlisted ? Icons.favorite : Icons.favorite_border,
          color: isWishlisted ? Colors.redAccent : Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

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
      return level.isEmpty ? 'General' : level;
  }
}

String _formatPrice(double price) {
  final formatter = NumberFormat('#,###', 'en_US');
  return 'TZS ${formatter.format(price)}';
}

// ─────────────────────────────────────────────
// Info section
// ─────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline, size: 12, color: AppColors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  course.trainerName,
                  style: TextStyle(fontSize: 11, color: AppColors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 12),
              const SizedBox(width: 2),
              Text(
                course.averageRating.toStringAsFixed(1),
                style: TextStyle(fontSize: 11, color: AppColors.grey),
              ),
              const SizedBox(width: 4),
              Text(
                '(${course.reviewsCount})',
                style: TextStyle(fontSize: 11, color: AppColors.grey),
              ),
              const Spacer(),
              if (course.level.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatLevel(course.level),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            course.isFree ? 'Free' : _formatPrice(course.price),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: course.isFree ? AppColors.primary : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}
