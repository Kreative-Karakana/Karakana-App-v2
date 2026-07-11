import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../widgets/common/karakana_wave_loader.dart';
import '../../../widgets/common/top_popup.dart';
import '../utils/course_contract.dart';
import '../utils/trainer_course_filters.dart';

class TrainerCoursesListScreen extends StatefulWidget {
  const TrainerCoursesListScreen({super.key});

  @override
  State<TrainerCoursesListScreen> createState() =>
      _TrainerCoursesListScreenState();
}

class _TrainerCoursesListScreenState extends State<TrainerCoursesListScreen> {
  final _currency = NumberFormat('#,###');

  List _courses = [];
  bool _loading = true;
  String? _error;

  // ── HELPERS ───────────────────────────────────────────────────────────────

  String _fmtPrice(dynamic v) {
    if (v == null) return '0';
    final n = double.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return _currency.format(n.toInt());
  }

  String _statusLabel(String s) {
    return CourseContract.statusPresentation(s).label;
  }

  Color _statusColor(String s) {
    return Color(CourseContract.statusPresentation(s).colorValue);
  }

  String _computeRevenue(Map c) {
    final students = c['student_count'] as int? ?? 0;
    final price =
        (double.tryParse((c['price'] ?? '0').toString()) ?? 0).toInt();
    final commissionRate = (c['commission_rate'] as num?)?.toDouble();
    int gross = students * price;
    if (commissionRate != null && commissionRate > 0 && commissionRate <= 100) {
      gross = (gross * (1 - commissionRate / 100)).round();
    }
    return _fmtPrice(gross);
  }

  // ── DATA ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient().dio.get(
            '/api/v1/courses/',
            queryParameters: TrainerCourseFilters.ownedCoursesQueryParameters,
          );
      final courses = TrainerCourseFilters.ownedCoursesFromResponse(res.data);
      if (mounted) {
        setState(() {
          _courses = courses;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient().parseError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteCourse(Map course) async {
    final id = course['id'] as int? ?? 0;
    final title = course['title'] as String? ?? 'Kozi';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Futa Kozi?',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Una uhakika unataka kufuta "$title"?',
          style: GoogleFonts.montserrat(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Ghairi',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
            ),
            child: Text('Futa',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiClient().dio.post('/api/v1/courses/$id/deletion-request/');
      if (!mounted) return;
      showTopPopup(context, 'Ombi la kufuta kozi limetumwa.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showTopPopup(context, ApiClient().parseError(e), isError: true);
    }
  }

  Future<void> _showPublishConfirm(Map course) async {
    final id = course['id'] as int? ?? 0;
    final isPublished = (course['status'] as String? ?? '') == 'published';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isPublished ? 'Ficha Kozi?' : 'Tuma kwa Ukaguzi?',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Text(
          isPublished
              ? 'Kozi itafichwa na wanafunzi wapya hawataweza kuisajili.'
              : 'Kozi itatumwa kwa timu ya Karakana kwa ukaguzi kabla ya kuchapishwa.',
          style: GoogleFonts.montserrat(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Ghairi',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE87722),
            ),
            child: Text(isPublished ? 'Ficha' : 'Tuma',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiClient().dio.patch(
        '/api/v1/courses/$id/',
        data: {'status': isPublished ? 'draft' : 'pending_review'},
      );
      if (!mounted) return;
      showTopPopup(context,
          isPublished ? 'Kozi imefichwa.' : 'Kozi imetumwa kwa ukaguzi.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showTopPopup(context, ApiClient().parseError(e), isError: true);
    }
  }

  // ── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _buildSmallAction(String label, IconData icon, VoidCallback onTap,
      {bool isDanger = false}) {
    final color = isDanger ? const Color(0xFFB71C1C) : const Color(0xFFE87722);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  Widget _buildCourseCard(Map course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF2A1A0A) : Colors.white;
    final textPrimary =
        isDark ? const Color(0xFFF5E6D8) : const Color(0xFF1A0A00);

    final statusStr = course['status'] as String? ?? 'draft';
    final isPublished = statusStr == 'published';
    final isPendingReview = statusStr == 'pending_review';
    final title = course['title'] as String? ?? '';
    final thumbnail = course['cover_photo'] as String?;
    final students = course['student_count'] as int? ?? 0;
    final rating = (course['average_rating'] as num? ?? 0).toDouble();
    final price = course['price'];
    final courseId = course['id'] as int? ?? 0;
    final statusColor = _statusColor(statusStr);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE87722).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        // ── THUMBNAIL ──
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Stack(children: [
            thumbnail != null && thumbnail.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: thumbnail,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 130,
                      color: isDark
                          ? const Color(0xFF3A2010)
                          : const Color(0xFFF5E6D8),
                      child: const Center(
                          child: KarakanaWaveLoader(
                              strokeWidth: 2, color: Color(0xFFE87722))),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 130,
                      color: isDark
                          ? const Color(0xFF3A2010)
                          : const Color(0xFFF5E6D8),
                      child: const Icon(Icons.school_outlined,
                          color: Color(0xFFE87722), size: 44),
                    ),
                  )
                : Container(
                    height: 130,
                    color: isDark
                        ? const Color(0xFF3A2010)
                        : const Color(0xFFF5E6D8),
                    child: const Center(
                        child: Icon(Icons.school_outlined,
                            color: Color(0xFFE87722), size: 44)),
                  ),
            // gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1A0A00).withValues(alpha: 0.55),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // status badge
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFFFFA726)),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _statusLabel(statusStr),
                    style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ]),
              ),
            ),
          ]),
        ),

        // ── DETAILS ──
        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.people_outline,
                  size: 13, color: Color(0xFF7B3A10)),
              const SizedBox(width: 4),
              Text('$students wanafunzi',
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7B3A10))),
              const SizedBox(width: 14),
              const Icon(Icons.star_rounded,
                  size: 13, color: Color(0xFFFFA726)),
              const SizedBox(width: 3),
              Text(rating.toStringAsFixed(1),
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7B3A10))),
              const Spacer(),
              Text('TZS ${_fmtPrice(price)}',
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE87722))),
            ]),
            if (students > 0) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 13, color: Color(0xFF7B3A10)),
                const SizedBox(width: 4),
                Text('Mapato: TZS ${_computeRevenue(course)}',
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7B3A10))),
              ]),
            ],
            const SizedBox(height: 12),
            Divider(
                height: 1,
                color: isDark ? Colors.white10 : const Color(0xFFF5E6D8)),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _buildSmallAction(
                isPublished
                    ? 'Imechapishwa'
                    : isPendingReview
                        ? 'Inasubiri'
                        : 'Tuma kwa Ukaguzi',
                isPublished
                    ? Icons.visibility_outlined
                    : isPendingReview
                        ? Icons.hourglass_top_rounded
                        : Icons.visibility_off_outlined,
                isPendingReview ? () {} : () => _showPublishConfirm(course),
              ),
              _buildSmallAction(
                'Ongeza Somo',
                Icons.post_add_rounded,
                () => context.push('/trainer/course/$courseId/sections',
                    extra: {'title': title}),
              ),
              _buildSmallAction(
                'Majaribio',
                Icons.quiz_outlined,
                () => context.push('/trainer/quiz/$courseId'),
              ),
              _buildSmallAction(
                'Hariri',
                Icons.edit_outlined,
                () async {
                  await context
                      .push('/trainer/course-builder?courseId=$courseId');
                  await _load();
                },
              ),
              _buildSmallAction(
                'Futa',
                Icons.delete_outline_rounded,
                () => _deleteCourse(course),
                isDanger: true,
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      const SizedBox(height: 6),
      Text(value,
          style: GoogleFonts.montserrat(
              fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
      Text(label,
          style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A0A00) : const Color(0xFFF7F2ED);

    final published =
        _courses.where((c) => (c as Map)['status'] == 'published').length;
    final totalStudents = _courses.fold<int>(
        0, (sum, c) => sum + ((c as Map)['student_count'] as int? ?? 0));

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        color: const Color(0xFFE87722),
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          // ── HEADER ──
          SliverAppBar(
            expandedHeight: 220,
            collapsedHeight: kToolbarHeight,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF3D1800),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3D1800), Color(0xFFE87722)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kozi Zangu',
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_courses.length} kozi zote',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatChip(Icons.school_outlined, 'Kozi Zote',
                                '${_courses.length}'),
                            _buildStatChip(Icons.people_outline, 'Wanafunzi',
                                '$totalStudents'),
                            _buildStatChip(Icons.check_circle_outline,
                                'Zilizochapishwa', '$published'),
                            _buildStatChip(
                              Icons.edit_note_outlined,
                              'Rasimu',
                              '${_courses.length - published}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── FAB-style add button ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: GestureDetector(
                onTap: () async {
                  await context.push('/trainer/course-builder');
                  await _load();
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE87722), Color(0xFFB85A16)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE87722).withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unda Kozi Mpya',
                              style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          Text('Anza kuunda kozi yako ya kwanza',
                              style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.88))),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ]),
                ),
              ),
            ),
          ),

          // ── BODY ──
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: KarakanaWaveLoader()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFE87722), size: 48),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: GoogleFonts.montserrat(fontSize: 14),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _load,
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE87722)),
                        child: const Text('Jaribu tena'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_courses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE87722).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_outlined,
                          color: Color(0xFFE87722), size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text('Huna kozi bado.',
                        style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D1800))),
                    const SizedBox(height: 8),
                    Text('Anza kuunda kozi yako ya kwanza!',
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: const Color(0xFF7B3A10))),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildCourseCard(_courses[i] as Map),
                  childCount: _courses.length,
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
