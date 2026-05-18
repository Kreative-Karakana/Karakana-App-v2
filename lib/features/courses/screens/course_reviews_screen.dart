import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/top_popup.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/course_provider.dart';

class CourseReviewsScreen extends StatefulWidget {
  final int courseId;

  const CourseReviewsScreen({
    super.key,
    required this.courseId,
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
      final res =
          await ApiClient().dio.get('/api/v1/courses/${widget.courseId}/reviews/');
      final data = res.data;
      final results =
          data is Map ? (data['results'] as List? ?? []) : (data as List? ?? []);
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
            24, 20, 24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D5C8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Jibu Maoni',
                style: GoogleFonts.montserrat(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fikia wanafunzi kwa kujibu maoni yao',
                style: GoogleFonts.montserrat(
                  fontSize: 13, color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                            showTopPopup(context, 'Jibu limetumwa kikamilifu!', isError: false);
                          } catch (_) {
                            setSheet(() => isSaving = false);
                            if (!ctx.mounted) return;
                            showTopPopup(context, 'Zoezi limeshindikana. Jaribu tena.');
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20,
                          child: KarakanaWaveLoader(color: Colors.white, strokeWidth: 2))
                      : Text(
                          existingReply != null && existingReply.isNotEmpty
                              ? 'Hariri Jibu'
                              : 'Tuma Jibu',
                          style: GoogleFonts.montserrat(
                              fontSize: 15, fontWeight: FontWeight.w600),
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
                              showTopPopup(context, 'Jibu limefutwa.', isError: false);
                            } catch (_) {
                              setSheet(() => isSaving = false);
                              if (!ctx.mounted) return;
                              showTopPopup(context, 'Zoezi limeshindikana.');
                            }
                          },
                    child: Text('Futa Jibu',
                        style: GoogleFonts.montserrat(
                            fontSize: 15, fontWeight: FontWeight.w600)),
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
      showTopPopup(context, 'Unahitaji kujiandikisha kwenye kozi hii kwanza ili uweze kutoa tathmini.');
      return;
    }

    final sections = provider.sections;
    final totalLessons = sections.fold<int>(0, (sum, s) => sum + s.lessons.length);
    final completedLessons = sections.fold<int>(
      0,
      (sum, s) => sum + s.lessons.where((l) => l.isRead).length,
    );
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    if (progress < 0.8) {
      showTopPopup(context, 'Kamilisha kozi hii kwanza ili uweze kutoa tathmini ya uzoefu wako.');
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
    final totalLessons = sections.fold<int>(0, (sum, s) => sum + s.lessons.length);
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
              const SizedBox(height: 16),
              Text(
                'Andika Tathmini',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3D1800),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setModalState(() => _selectedRating = i + 1),
                    child: Icon(
                      i < _selectedRating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFA726),
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
                            showTopPopup(context, 'Asante! Tathmini yako imetumwa.', isError: false);
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
                            fontSize: 15,
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
    final average = _reviews.isEmpty
        ? 0.0
        : (_reviews
                    .map((r) => (r as Map)['rating'] as int? ?? 0)
                    .reduce((a, b) => a + b) /
                _reviews.length)
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
            fontSize: 17,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE8A96A),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      _reviews.isEmpty ? '0.0' : average.toStringAsFixed(1),
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
                      '${_reviews.length} Tathmini',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFF9E8070),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((stars) {
                      final count = _reviews
                          .where((r) => (r as Map)['rating'] == stars)
                          .length;
                      final percent = _reviews.isEmpty ? 0.0 : count / _reviews.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '$stars',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
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
                                  fontSize: 11,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                        child: Icon(Icons.person, color: Colors.white, size: 20),
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
                            fontSize: 14,
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
                            const SizedBox(height: 16),
                            Text(
                              'Hakuna Tathmini Bado',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A0A00),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kuwa wa kwanza kutoa tathmini!',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
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
                          final isTrainer = context.read<AuthProvider>().isTrainer;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
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
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name.isEmpty ? 'Mwanafunzi' : name,
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
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
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  content,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: const Color(0xFF5C3D2E),
                                    height: 1.5,
                                  ),
                                ),
                                if (reply != null && reply.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5E6D8),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                                fontSize: 12,
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
      ),
    );
  }
}



