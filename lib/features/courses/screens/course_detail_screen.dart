import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/top_popup.dart';
import '../../payments/providers/iap_provider.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isEnrolling = false;
  bool _wishlistBusy = false;
  IAPProvider? _iapProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourseDetail(widget.courseId);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!Platform.isIOS) return;
      final course = context.read<CourseProvider>().selectedCourse;
      if (course == null) return;
      if (course.isFree) return;
      final productId = course.appleIapProductId ?? '';
      if (productId.isEmpty) return;
      await context.read<IAPProvider>().initializeForCourse(productId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextIapProvider = context.read<IAPProvider>();
    if (!identical(_iapProvider, nextIapProvider)) {
      _iapProvider?.removeListener(_onIAPStateChange);
      _iapProvider = nextIapProvider;
      _iapProvider?.addListener(_onIAPStateChange);
    }
  }

  @override
  void dispose() {
    _iapProvider?.removeListener(_onIAPStateChange);
    super.dispose();
  }

  void _onIAPStateChange() {
    if (!mounted) return;
    final iap = _iapProvider;
    if (iap == null) return;

    if (iap.purchaseSuccess) {
      iap.reset();
      context.read<CourseProvider>().loadCourseDetail(widget.courseId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Umesajiliwa kwa mafanikio!',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFE87722),
        ),
      );
    }

    if (iap.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            iap.errorMessage!,
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      iap.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingDetail) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const SafeArea(
              child: Center(
                child: KarakanaWaveLoader(
                  color: Color(0xFFE87722),
                ),
              ),
            ),
          );
        }

        final course = provider.selectedCourse;
        if (course == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      provider.errorMessage ?? 'Hatukuweza kupata kozi hii.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: AppTextStyles.bodyMedium.fontSize,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () =>
                          provider.loadCourseDetail(widget.courseId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE87722),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Jaribu tena',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: const Color(0xFF3D1800),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _shareCourse(course),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: _wishlistBusy
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: KarakanaWaveLoader(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              course.isWishlisted
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: course.isWishlisted
                                  ? const Color(0xFFE87722)
                                  : Colors.white,
                              size: 22,
                            ),
                            onPressed: () => _toggleWishlist(course, provider),
                          ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (course.coverPhoto != null)
                        CachedNetworkImage(
                          imageUrl: course.coverPhoto!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: isDark
                                ? const Color(0xFF2A1A0A)
                                : const Color(0xFFF5E6D8),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: isDark
                                ? const Color(0xFF2A1A0A)
                                : const Color(0xFFF5E6D8),
                          ),
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF3D1800), Color(0xFFE87722)],
                            ),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF3D1800).withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 16,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE87722),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                course.formattedLevel,
                                style: GoogleFonts.montserrat(
                                  fontSize: AppTextStyles.labelSmall.fontSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (course.isFree) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE87722),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'BURE',
                                  style: GoogleFonts.montserrat(
                                    fontSize: AppTextStyles.labelSmall.fontSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3D1800),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFA726),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.averageRating.toStringAsFixed(1),
                            style: GoogleFonts.montserrat(
                              fontSize: AppTextStyles.h4.fontSize,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5C3D2E),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${course.reviewCount} tathmini)',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: const Color(0xFF9E8070),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.people_outline,
                            size: 16,
                            color: Color(0xFF9E8070),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${course.studentCount} wanafunzi',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: const Color(0xFF9E8070),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          ClipOval(
                            child: course.trainerAvatar != null
                                ? CachedNetworkImage(
                                    imageUrl: course.trainerAvatar!,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _trainerFallback(),
                                  )
                                : _trainerFallback(),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mkufunzi',
                                style: GoogleFonts.montserrat(
                                  fontSize: AppTextStyles.caption.fontSize,
                                  color: const Color(0xFF9E8070),
                                ),
                              ),
                              Text(
                                course.trainerName,
                                style: GoogleFonts.montserrat(
                                  fontSize: AppTextStyles.bodyMedium.fontSize,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3D1800),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFFE8D5C8),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A1A0A)
                              : const Color(0xFFFFF8F4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE8D5C8),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  course.formattedPrice,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: course.isFree
                                        ? const Color(0xFFE87722)
                                        : const Color(0xFFE87722),
                                  ),
                                ),
                                if (!course.isFree)
                                  Text(
                                    '/ kozi mzima',
                                    style: GoogleFonts.montserrat(
                                      fontSize:
                                          AppTextStyles.bodySmall.fontSize,
                                      color: const Color(0xFF9E8070),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildEnrollButton(
                              context,
                              course,
                              provider,
                              context.read<IAPProvider>(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Muhtasari',
                        style: GoogleFonts.montserrat(
                          fontSize: AppTextStyles.bodyLarge.fontSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3D1800),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        course.excerpt,
                        style: GoogleFonts.montserrat(
                          fontSize: AppTextStyles.bodyMedium.fontSize,
                          color: const Color(0xFF5C3D2E),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFaqSection(course.faqs, isDark),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mtaala',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3D1800),
                            ),
                          ),
                          Text(
                            '${provider.sections.length} sehemu',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: const Color(0xFF9E8070),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!course.isEnrolled)
                        Container(
                          padding: AppSpacing.cardPadding,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A1A0A)
                                : const Color(0xFFFFF8F4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE8D5C8),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                color: Color(0xFFE87722),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Jiandikishe ili ufikie mtaala wote',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    color: const Color(0xFF5C3D2E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (provider.sectionsErrorMessage != null)
                        Container(
                          padding: AppSpacing.cardPadding,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A1A0A)
                                : const Color(0xFFFFF8F4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE8D5C8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFFE87722),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hatukuweza kufungua mtaala sasa hivi',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3D1800),
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          provider.sectionsErrorMessage!,
                                          style: GoogleFonts.montserrat(
                                            fontSize: AppTextStyles
                                                .bodySmall.fontSize,
                                            color: const Color(0xFF5C3D2E),
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          'Jaribu kuingia tena au fungua ukurasa huu baada ya ruhusa za kozi kusasishwa.',
                                          style: GoogleFonts.montserrat(
                                            fontSize: AppTextStyles
                                                .bodySmall.fontSize,
                                            color: const Color(0xFF9E8070),
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () =>
                                    provider.loadCourseDetail(widget.courseId),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFE87722),
                                  side: const BorderSide(
                                    color: Color(0xFFE8D5C8),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  'Jaribu tena',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (provider.sections.isEmpty)
                        Container(
                          padding: AppSpacing.cardPadding,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A1A0A)
                                : const Color(0xFFFFF8F4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE8D5C8),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.menu_book_outlined,
                                color: Color(0xFFE87722),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Mtaala wa kozi hii bado haujaonekana hapa.',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    color: const Color(0xFF5C3D2E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...provider.sections.asMap().entries.map(
                              (entry) => _buildSectionTile(
                                entry.key,
                                entry.value,
                                course.isEnrolled,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              if (provider.reviews.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tathmini',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3D1800),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push('/course/${course.id}/reviews'),
                              child: Text(
                                'Zote (${course.reviewCount})',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE87722),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...provider.reviews.take(3).map(_buildReviewCard),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnrollButton(
    BuildContext context,
    CourseModel course,
    CourseProvider provider,
    IAPProvider iapProvider,
  ) {
    if (course.isEnrolled) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
            'Endelea Kujifunza',
            style: GoogleFonts.montserrat(
              fontSize: AppTextStyles.bodyLarge.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE87722),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: () => context.push('/course/${course.id}/classroom'),
        ),
      );
    }

    if (course.isFree) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE87722),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: _isEnrolling
              ? null
              : () async {
                  setState(() => _isEnrolling = true);
                  await provider.enrollFreeCourse(course.id);
                  if (mounted) {
                    setState(() => _isEnrolling = false);
                  }
                },
          child: _isEnrolling
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: KarakanaWaveLoader(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Jiandikishe Bure',
                  style: GoogleFonts.montserrat(
                    fontSize: AppTextStyles.bodyLarge.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    }

    // iOS: Apple IAP
    if (Platform.isIOS) {
      final productId = course.appleIapProductId ?? '';
      if (productId.isEmpty) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: null,
            child: Text(
              'Haipatikani kwenye iOS',
              style: GoogleFonts.montserrat(
                fontSize: AppTextStyles.bodyLarge.fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE87722),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: iapProvider.isLoading
              ? null
              : () => iapProvider.purchase(productId),
          child: iapProvider.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: KarakanaWaveLoader(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Nunua Kozi • ${course.formattedPrice}',
                  style: GoogleFonts.montserrat(
                    fontSize: AppTextStyles.bodyLarge.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    }

    // Android: existing EVPay flow — keep exactly as is
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE87722),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: () => context.push(
          '/payment/${course.id}',
          extra: {
            'courseTitle': course.title,
            'coursePrice': course.price,
            'courseThumbnail': course.coverPhoto,
          },
        ),
        child: Text(
          'Nunua Kozi • ${course.formattedPrice}',
          style: GoogleFonts.montserrat(
            fontSize: AppTextStyles.bodyLarge.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTile(int index, SectionModel section, bool isEnrolled) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        section.title,
        style: GoogleFonts.montserrat(
          fontSize: AppTextStyles.bodyMedium.fontSize,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3D1800),
        ),
      ),
      subtitle: Text(
        '${section.lessons.length} masomo',
        style: GoogleFonts.montserrat(
          fontSize: AppTextStyles.bodySmall.fontSize,
          color: const Color(0xFF9E8070),
        ),
      ),
      iconColor: const Color(0xFFE87722),
      collapsedIconColor: const Color(0xFF9E8070),
      children: section.lessons
          .map(
            (lesson) => ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: lesson.isRead
                      ? const Color(0xFFE87722).withValues(alpha: 0.1)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A1A0A)
                          : const Color(0xFFF5E6D8)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  lesson.isRead
                      ? Icons.check_circle
                      : Icons.play_circle_outline,
                  color: lesson.isRead
                      ? const Color(0xFFE87722)
                      : const Color(0xFFE87722),
                  size: 20,
                ),
              ),
              title: Text(
                lesson.title,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: const Color(0xFF3D1800),
                ),
              ),
              trailing: !isEnrolled
                  ? const Icon(
                      Icons.lock_outline,
                      color: Color(0xFFBDA99C),
                      size: 16,
                    )
                  : null,
              onTap: isEnrolled
                  ? () => context.push('/lesson/${lesson.id}')
                  : null,
            ),
          )
          .toList(),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AC4620A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: review.userAvatar != null
                    ? CachedNetworkImage(
                        imageUrl: review.userAvatar!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _reviewFallback(review),
                      )
                    : _reviewFallback(review),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D1800),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star,
                          size: 12,
                          color: i < review.rating
                              ? const Color(0xFFFFA726)
                              : const Color(0xFFE8D5C8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatReviewDate(review.createdAt),
                style: GoogleFonts.montserrat(
                  fontSize: AppTextStyles.caption.fontSize,
                  color: const Color(0xFF9E8070),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            review.content,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: const Color(0xFF5C3D2E),
              height: 1.5,
            ),
          ),
          if (review.trainerReply != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2A1A0A) : const Color(0xFFFFF8F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.reply,
                    size: 14,
                    color: Color(0xFFE87722),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      review.trainerReply!,
                      style: GoogleFonts.montserrat(
                        fontSize: AppTextStyles.bodySmall.fontSize,
                        color: const Color(0xFF5C3D2E),
                      ),
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

  Widget _trainerFallback() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
      child: const Icon(
        Icons.person,
        color: Color(0xFFE87722),
        size: 20,
      ),
    );
  }

  Widget _reviewFallback(ReviewModel review) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
      child: Center(
        child: Text(
          review.userName.isNotEmpty ? review.userName[0] : 'U',
          style: GoogleFonts.montserrat(
            fontSize: AppTextStyles.bodyMedium.fontSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFE87722),
          ),
        ),
      ),
    );
  }

  String _formatReviewDate(String raw) {
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  Future<void> _toggleWishlist(
      CourseModel course, CourseProvider provider) async {
    if (_wishlistBusy) return;
    final previous = course.isWishlisted;
    setState(() {
      _wishlistBusy = true;
      course.isWishlisted = !previous;
    });

    final result = await provider.toggleWishlistSafe(course.id);
    if (!mounted) return;
    if (result == null) {
      setState(() => course.isWishlisted = previous);
      showTopPopup(context, 'Hitilafu. Jaribu tena.');
    } else {
      setState(() => course.isWishlisted = result);
    }
    setState(() => _wishlistBusy = false);
  }

  void _shareCourse(CourseModel course) {
    Share.share(
      'Angalia kozi hii kwenye Karakana:\n${course.title}\n${course.excerpt}',
      subject: course.title,
    );
  }

  Widget _buildFaqSection(List<CourseFaqModel> faqs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maswali Yanayoulizwa Mara kwa Mara (FAQ)',
          style: GoogleFonts.montserrat(
            fontSize: AppTextStyles.bodyLarge.fontSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D1800),
          ),
        ),
        const SizedBox(height: 10),
        if (faqs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFFFF8F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE8D5C8),
              ),
            ),
            child: Text(
              'Hakuna maswali ya FAQ kwa sasa.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF5C3D2E),
              ),
            ),
          )
        else
          ...faqs.map(
            (faq) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2A1A0A) : const Color(0xFFFFF8F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE8D5C8),
                ),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                iconColor: const Color(0xFFE87722),
                collapsedIconColor: const Color(0xFF9E8070),
                title: Text(
                  faq.question,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D1800),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Text(
                      faq.answer,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: const Color(0xFF5C3D2E),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
