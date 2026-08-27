import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/top_popup.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../services/review_safety_service.dart';
import '../widgets/star_rating_input.dart';

class CourseReviewsScreen extends StatefulWidget {
  final int courseId;
  final ReviewSafetyService? safetyService;
  final Future<List<dynamic>> Function()? reviewLoader;

  const CourseReviewsScreen({
    super.key,
    required this.courseId,
    this.safetyService,
    this.reviewLoader,
  });

  @override
  State<CourseReviewsScreen> createState() => _CourseReviewsScreenState();
}

class _CourseReviewsScreenState extends State<CourseReviewsScreen> {
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  bool _hasReviewed = false;
  int _selectedRating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  late final ReviewSafetyService _safetyService =
      widget.safetyService ?? ReviewSafetyService();

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      final currentUserId = context.read<AuthProvider>().userId;
      late final List<dynamic> results;
      if (widget.reviewLoader != null) {
        results = await widget.reviewLoader!();
      } else {
        final res = await ApiClient()
            .dio
            .get('/api/v1/courses/${widget.courseId}/reviews/');
        final data = res.data;
        results = data is Map
            ? (data['results'] as List? ?? [])
            : (data as List? ?? []);
      }
      if (!mounted) return;
      setState(() {
        _reviews = results;
        _isLoading = false;
        _hasReviewed = results.any(
          (r) => (r as Map)['student']?['id'] == currentUserId,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showReportSheet(
    int reviewId,
    ReviewTargetPart targetPart,
  ) async {
    var reason = ReviewReportReason.harassment;
    final detailController = TextEditingController();
    var isSending = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                targetPart == ReviewTargetPart.review
                    ? 'Ripoti tathmini'
                    : 'Ripoti jibu',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ReviewReportReason>(
                initialValue: reason,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sababu'),
                items: ReviewReportReason.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: isSending
                    ? null
                    : (value) {
                        if (value != null) setSheet(() => reason = value);
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: detailController,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Maelezo ya ziada (si lazima)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          setSheet(() => isSending = true);
                          try {
                            await _safetyService.report(
                              courseId: widget.courseId,
                              reviewId: reviewId,
                              targetPart: targetPart,
                              reason: reason,
                              detail: detailController.text,
                            );
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            if (!mounted) return;
                            showTopPopup(
                              context,
                              'Ripoti yako imetumwa. Asante kwa kutusaidia kuweka jumuiya salama.',
                              isError: false,
                            );
                          } catch (_) {
                            if (!ctx.mounted) return;
                            setSheet(() => isSending = false);
                            showTopPopup(
                              ctx,
                              'Imeshindikana kutuma ripoti. Jaribu tena.',
                            );
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: KarakanaWaveLoader(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Tuma Ripoti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    detailController.dispose();
  }

  Future<void> _blockUser(
    int reviewId,
    ReviewTargetPart targetPart,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zuia mtumiaji?'),
        content: const Text(
          'Hutaona tena maudhui ya mtumiaji huyu. Unaweza kuondoa zuio baadaye.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Zuia'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _safetyService.block(
        courseId: widget.courseId,
        reviewId: reviewId,
        targetPart: targetPart,
      );
      await _loadReviews();
      if (!mounted) return;
      showTopPopup(
        context,
        'Mtumiaji amezuiwa na maudhui yake yamefichwa.',
        isError: false,
      );
    } catch (_) {
      if (!mounted) return;
      showTopPopup(context, 'Imeshindikana kumzuia mtumiaji. Jaribu tena.');
    }
  }

  Future<void> _unblockUser(
    int reviewId,
    ReviewTargetPart targetPart,
  ) async {
    try {
      await _safetyService.unblock(
        courseId: widget.courseId,
        reviewId: reviewId,
        targetPart: targetPart,
      );
      await _loadReviews();
      if (!mounted) return;
      showTopPopup(context, 'Zuio la mtumiaji limeondolewa.', isError: false);
    } catch (_) {
      if (!mounted) return;
      showTopPopup(context, 'Imeshindikana kuondoa zuio. Jaribu tena.');
    }
  }

  Future<void> _handleSafetyAction(
    ReviewSafetyAction action,
    int reviewId,
  ) async {
    switch (action) {
      case ReviewSafetyAction.reportReview:
        return _showReportSheet(reviewId, ReviewTargetPart.review);
      case ReviewSafetyAction.blockReviewAuthor:
        return _blockUser(reviewId, ReviewTargetPart.review);
      case ReviewSafetyAction.unblockReviewAuthor:
        return _unblockUser(reviewId, ReviewTargetPart.review);
      case ReviewSafetyAction.reportReply:
        return _showReportSheet(reviewId, ReviewTargetPart.reply);
      case ReviewSafetyAction.blockReplyAuthor:
        return _blockUser(reviewId, ReviewTargetPart.reply);
      case ReviewSafetyAction.unblockReplyAuthor:
        return _unblockUser(reviewId, ReviewTargetPart.reply);
    }
  }

  String _safetyActionLabel(ReviewSafetyAction action) {
    switch (action) {
      case ReviewSafetyAction.reportReview:
        return 'Ripoti tathmini';
      case ReviewSafetyAction.blockReviewAuthor:
        return 'Zuia mtumiaji';
      case ReviewSafetyAction.unblockReviewAuthor:
        return 'Ondoa zuio la mtumiaji';
      case ReviewSafetyAction.reportReply:
        return 'Ripoti jibu';
      case ReviewSafetyAction.blockReplyAuthor:
        return 'Zuia mkufunzi';
      case ReviewSafetyAction.unblockReplyAuthor:
        return 'Ondoa zuio la mkufunzi';
    }
  }

  void _showReplySheet(int reviewId, String? existingReply) {
    final controller = TextEditingController(text: existingReply ?? '');
    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D5C8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Jibu Maoni',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fikia wanafunzi kwa kujibu maoni yao',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'Andika jibu lako hapa...',
                  filled: true,
                  fillColor: const Color(0xFFFFF8F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (controller.text.trim().isEmpty) return;
                          setSheet(() => isSaving = true);
                          try {
                            await ApiClient().dio.put(
                              '/api/v1/courses/${widget.courseId}/reviews/$reviewId/reply/',
                              data: {'reply': controller.text.trim()},
                            );
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            await _loadReviews();
                            if (!mounted) return;
                            showTopPopup(context, 'Jibu limetumwa kikamilifu!',
                                isError: false);
                          } catch (_) {
                            setSheet(() => isSaving = false);
                            if (!ctx.mounted) return;
                            showTopPopup(
                                context, 'Zoezi limeshindikana. Jaribu tena.');
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: KarakanaWaveLoader(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          existingReply != null && existingReply.isNotEmpty
                              ? 'Hariri Jibu'
                              : 'Tuma Jibu',
                          style: GoogleFonts.montserrat(
                              fontSize: AppTextStyles.h4.fontSize,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              if (existingReply != null && existingReply.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB71C1C),
                      side: const BorderSide(color: Color(0xFFB71C1C)),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            setSheet(() => isSaving = true);
                            try {
                              await ApiClient().dio.delete(
                                    '/api/v1/courses/${widget.courseId}/reviews/$reviewId/reply/',
                                  );
                              if (!ctx.mounted) return;
                              Navigator.of(ctx).pop();
                              await _loadReviews();
                              if (!mounted) return;
                              showTopPopup(context, 'Jibu limefutwa.',
                                  isError: false);
                            } catch (_) {
                              setSheet(() => isSaving = false);
                              if (!ctx.mounted) return;
                              showTopPopup(context, 'Zoezi limeshindikana.');
                            }
                          },
                    child: Text('Futa Jibu',
                        style: GoogleFonts.montserrat(
                            fontSize: AppTextStyles.h4.fontSize,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onWriteReviewTap() {
    final provider = context.read<CourseProvider>();
    final course = provider.selectedCourse;
    final isEnrolled = course?.isEnrolled ?? false;

    if (!isEnrolled) {
      showTopPopup(context,
          'Unahitaji kujiandikisha kwenye kozi hii kwanza ili uweze kutoa tathmini.');
      return;
    }

    final sections = provider.sections;
    final totalLessons =
        sections.fold<int>(0, (sum, s) => sum + s.lessons.length);
    final completedLessons = sections.fold<int>(
      0,
      (sum, s) => sum + s.lessons.where((l) => l.isRead).length,
    );
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    if (progress < 0.8) {
      showTopPopup(context,
          'Kamilisha kozi hii kwanza ili uweze kutoa tathmini ya uzoefu wako.');
      return;
    }

    _showReviewForm();
  }

  void _showReviewForm() {
    final provider = context.read<CourseProvider>();
    final course = provider.selectedCourse;
    final isEnrolled = course?.isEnrolled ?? false;
    if (!isEnrolled) return;
    final sections = provider.sections;
    final totalLessons =
        sections.fold<int>(0, (sum, s) => sum + s.lessons.length);
    final completedLessons = sections.fold<int>(
      0,
      (sum, s) => sum + s.lessons.where((l) => l.isRead).length,
    );
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;
    if (progress < 0.8) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D5C8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Andika Tathmini',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3D1800),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: StarRatingInput(
                  rating: _selectedRating,
                  onChanged: (rating) =>
                      setModalState(() => _selectedRating = rating),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Elezea uzoefu wako na kozi hii...',
                  filled: true,
                  fillColor: const Color(0xFFFFF8F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE87722),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
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
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (_reviewController.text.isEmpty) return;
                          final navigator = Navigator.of(ctx);
                          setState(() => _isSubmitting = true);
                          try {
                            await ApiClient().dio.post(
                              '/api/v1/courses/${widget.courseId}/reviews/',
                              data: {
                                'rating': _selectedRating,
                                'content': _reviewController.text,
                              },
                            );
                            if (!mounted) return;
                            navigator.pop();
                            _reviewController.clear();
                            setState(() {
                              _hasReviewed = true;
                              _isSubmitting = false;
                            });
                            await _loadReviews();
                            if (!mounted) return;
                            showTopPopup(
                                context, 'Asante! Tathmini yako imetumwa.',
                                isError: false);
                          } catch (_) {
                            if (mounted) {
                              setState(() => _isSubmitting = false);
                            }
                          }
                        },
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: KarakanaWaveLoader(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Tuma Tathmini',
                          style: GoogleFonts.montserrat(
                            fontSize: AppTextStyles.h4.fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleReviews = _reviews.where((review) {
      final data = review as Map;
      return data['is_review_author_blocked'] != true;
    }).toList();
    final average = visibleReviews.isEmpty
        ? 0.0
        : (visibleReviews
                    .map((r) => (r as Map)['rating'] as int? ?? 0)
                    .reduce((a, b) => a + b) /
                visibleReviews.length)
            .toDouble();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Tathmini',
          style: GoogleFonts.montserrat(
            fontSize: AppTextStyles.h3.fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!_hasReviewed)
            TextButton(
              onPressed: _onWriteReviewTap,
              child: Text(
                'Tathmini',
                style: GoogleFonts.montserrat(
                  fontSize: AppTextStyles.bodyMedium.fontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE8A96A),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
          child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      visibleReviews.isEmpty
                          ? '0.0'
                          : average.toStringAsFixed(1),
                      style: GoogleFonts.montserrat(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D1800),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (_) => const Icon(
                          Icons.star,
                          color: Color(0xFFFFA726),
                          size: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${visibleReviews.length} Tathmini',
                      style: GoogleFonts.montserrat(
                        fontSize: AppTextStyles.bodySmall.fontSize,
                        color: const Color(0xFF9E8070),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((stars) {
                      final count = visibleReviews
                          .where((r) => (r as Map)['rating'] == stars)
                          .length;
                      final percent = visibleReviews.isEmpty
                          ? 0.0
                          : count / visibleReviews.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '$stars',
                              style: GoogleFonts.montserrat(
                                fontSize: AppTextStyles.bodySmall.fontSize,
                                color: const Color(0xFF5C3D2E),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              size: 10,
                              color: Color(0xFFFFA726),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor: const Color(0xFFF0E4DA),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFFFA726),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '$count',
                                style: GoogleFonts.montserrat(
                                  fontSize: AppTextStyles.caption.fontSize,
                                  color: const Color(0xFF9E8070),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0E4DA)),
          if (!_hasReviewed)
            GestureDetector(
              onTap: _onWriteReviewTap,
              child: Container(
                color: const Color(0xFFFFF8F4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE87722),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child:
                            Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE8D5C8)),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Andika tathmini yako...',
                          style: GoogleFonts.montserrat(
                            fontSize: AppTextStyles.bodyMedium.fontSize,
                            color: const Color(0xFFBDA99C),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: KarakanaWaveLoader(color: Color(0xFFE87722)),
                  )
                : _reviews.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.rate_review_outlined,
                              size: 64,
                              color: Color(0xFFE8D5C8),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Hakuna Tathmini Bado',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A0A00),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Kuwa wa kwanza kutoa tathmini!',
                              style: GoogleFonts.montserrat(
                                fontSize: AppTextStyles.bodyMedium.fontSize,
                                color: const Color(0xFF9E8070),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        itemCount: _reviews.length,
                        itemBuilder: (_, i) {
                          final review = _reviews[i] as Map;
                          final reviewId = review['id'] as int? ?? 0;
                          final student = review['student'] as Map? ?? {};
                          final name =
                              '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'
                                  .trim();
                          final rating = review['rating'] as int? ?? 0;
                          final content = review['content'] as String? ?? '';
                          final reply = review['reply'] as String?;
                          final isOwner = review['is_owner'] == true;
                          final isTrainer = review['is_trainer'] == true;
                          final hasTrainerReply =
                              review['has_trainer_reply'] == true ||
                                  (reply != null && reply.isNotEmpty);
                          final isReviewAuthorBlocked =
                              review['is_review_author_blocked'] == true;
                          final isReplyAuthorBlocked =
                              review['is_reply_author_blocked'] == true;
                          final safetyActions = reviewSafetyActions(
                            isOwner: isOwner,
                            isTrainer: isTrainer,
                            hasTrainerReply: hasTrainerReply,
                            isReviewAuthorBlocked: isReviewAuthorBlocked,
                            isReplyAuthorBlocked: isReplyAuthorBlocked,
                          );
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: AppSpacing.cardPadding,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0FC4620A),
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
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE87722),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'U',
                                          style: GoogleFonts.montserrat(
                                            fontSize: AppTextStyles
                                                .bodyMedium.fontSize,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name.isEmpty ? 'Mwanafunzi' : name,
                                            style: GoogleFonts.montserrat(
                                              fontSize: AppTextStyles
                                                  .bodyMedium.fontSize,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF3D1800),
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (j) => Icon(
                                                j < rating
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: const Color(0xFFFFA726),
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (safetyActions.isNotEmpty)
                                      PopupMenuButton<ReviewSafetyAction>(
                                        tooltip: 'Chaguo za usalama',
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (action) =>
                                            _handleSafetyAction(
                                          action,
                                          reviewId,
                                        ),
                                        itemBuilder: (_) => safetyActions
                                            .map(
                                              (action) => PopupMenuItem(
                                                value: action,
                                                child: Text(
                                                  _safetyActionLabel(action),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  isReviewAuthorBlocked
                                      ? 'Maudhui ya mtumiaji huyu yamefichwa.'
                                      : content,
                                  style: GoogleFonts.montserrat(
                                    fontSize: AppTextStyles.bodyMedium.fontSize,
                                    color: const Color(0xFF5C3D2E),
                                    height: 1.5,
                                  ),
                                ),
                                if (isReplyAuthorBlocked) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5E6D8),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Jibu la mtumiaji huyu limefichwa.',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        color: const Color(0xFF5C3D2E),
                                      ),
                                    ),
                                  ),
                                ],
                                if (reply != null && reply.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5E6D8),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.reply,
                                              color: Color(0xFFE87722),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Jibu la Mkufunzi',
                                              style: GoogleFonts.montserrat(
                                                fontSize: AppTextStyles
                                                    .bodySmall.fontSize,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFE87722),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          reply,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            color: const Color(0xFF5C3D2E),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (isTrainer) ...[
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          _showReplySheet(reviewId, reply),
                                      icon: Icon(
                                        reply != null && reply.isNotEmpty
                                            ? Icons.edit_outlined
                                            : Icons.reply_outlined,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      label: Text(
                                        reply != null && reply.isNotEmpty
                                            ? 'Hariri Jibu'
                                            : 'Jibu',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      )),
    );
  }
}
