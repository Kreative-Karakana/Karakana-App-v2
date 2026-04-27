import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List _courses = [];
  bool _isLoading = true;
  // ignore: unused_field
  Map _wallet = {};
  Map _stats = {
    'total_courses': 0,
    'total_students': 0,
    'avg_rating': 0.0,
    'balance': 0,
    'completion_rate': 78,
    'total_views': 0,
  };

  final List<Map<String, dynamic>> _pendingCerts = [
    {'name': 'Juma Ally', 'course': 'Misingi ya Ujasiriamali',
      'progress': 100, 'date': '24 Apr 2026', 'is_approved': false},
    {'name': 'Fatuma Hassan', 'course': 'Fedha za Biashara',
      'progress': 100, 'date': '23 Apr 2026', 'is_approved': false},
    {'name': 'Peter Kimaro', 'course': 'Masoko ya Kidijitali',
      'progress': 100, 'date': '22 Apr 2026', 'is_approved': true},
    {'name': 'Amina Salim', 'course': 'Uongozi na Timu',
      'progress': 98, 'date': '21 Apr 2026', 'is_approved': false},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiClient().dio.get('/api/v1/courses/?enrolled=true&page_size=50'),
        ApiClient().dio.get('/api/v1/wallet/me/'),
      ]);
      final coursesData = results[0].data;
      final courses = coursesData is Map
          ? (coursesData['results'] as List? ?? [])
          : (coursesData as List? ?? []);
      final wallet = results[1].data as Map? ?? {};
      final totalStudents = courses.fold<int>(
          0, (sum, c) => sum + ((c as Map)['student_count'] as int? ?? 0));
      if (mounted) {
        setState(() {
          _courses = courses;
          _wallet = wallet;
          _stats = {
            'total_courses': courses.length,
            'total_students': totalStudents,
            'avg_rating': courses.isEmpty
                ? 0.0
                : courses.fold<double>(
                        0.0,
                        (sum, c) =>
                            sum +
                            ((c as Map)['average_rating'] as num? ?? 0.0)
                                .toDouble()) /
                    courses.length,
            'balance': wallet['balance'] ?? 0,
            'completion_rate': 78,
            'total_views': totalStudents * 4,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePublish(Map course) async {
    final id = course['id'];
    final isPublished = course['status'] == 'published';
    try {
      await ApiClient().dio.patch('/api/v1/courses/$id/',
          data: {'status': isPublished ? 'draft' : 'published'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              isPublished
                  ? 'Kozi imefichwa kutoka kwa wanafunzi'
                  : 'Kozi imechapishwa kikamilifu! ✓',
              style: GoogleFonts.montserrat()),
          backgroundColor:
              isPublished ? const Color(0xFF7B3A10) : const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hitilafu. Jaribu tena.',
              style: GoogleFonts.montserrat()),
          backgroundColor: const Color(0xFFB71C1C)));
    }
  }

  String _formatNumber(dynamic n) {
    final num = int.tryParse(n.toString()) ?? 0;
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return '$num';
  }

  String _formatPrice(dynamic p) {
    try {
      final v = double.parse(p.toString());
      if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
      if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
      return 'TZS ${v.toStringAsFixed(0)}';
    } catch (_) {
      return 'TZS $p';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF1A0A00) : const Color(0xFFFFF8F4);
    final surfaceColor =
        isDark ? const Color(0xFF2A1400) : Colors.white;
    final textPrimary =
        isDark ? Colors.white : const Color(0xFF1A0A00);
    final textSecondary =
        isDark ? Colors.white60 : const Color(0xFF7B3A10);

    return Scaffold(
        backgroundColor: bgColor,
        body: NestedScrollView(
            headerSliverBuilder: (_, innerBoxIsScrolled) => [
                  _buildHeroAppBar(innerBoxIsScrolled),
                  _buildStickyTabBar(),
                ],
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFE87722)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(bgColor, surfaceColor, textPrimary, textSecondary),
                      _buildCoursesTab(bgColor, surfaceColor, textPrimary, textSecondary),
                      _buildStudentsTab(bgColor, surfaceColor, textPrimary, textSecondary),
                      _buildCertificatesTab(bgColor, surfaceColor, textPrimary, textSecondary),
                    ])));
  }

  Widget _buildOverviewTab(Color bgColor, Color surfaceColor,
      Color textPrimary, Color textSecondary) {
    return RefreshIndicator(
        color: const Color(0xFFE87722),
        onRefresh: () async => _loadAll(),
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── QUICK ACTIONS ──
              Row(children: [
                _buildQuickAction(Icons.add_circle_outline_rounded, 'Unda Kozi',
                    const Color(0xFFE87722),
                    () => context.push('/trainer/course-builder')),
                const SizedBox(width: 10),
                _buildQuickAction(Icons.people_outline_rounded, 'Wanafunzi',
                    const Color(0xFF1A2E5A), () => _tabController.animateTo(2)),
                const SizedBox(width: 10),
                _buildQuickAction(Icons.workspace_premium_outlined, 'Vyeti',
                    const Color(0xFF2E7D32), () => _tabController.animateTo(3)),
                const SizedBox(width: 10),
                _buildQuickAction(Icons.account_balance_wallet_outlined, 'Mkoba',
                    const Color(0xFF7B3A10), () => context.push('/wallet')),
              ]),

              const SizedBox(height: 28),

              // ── STATS TITLE ──
              Text('Takwimu za Jumla',
                  style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),

              const SizedBox(height: 14),

              // ── STATS 2x2 GRID ──
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: _buildStatCard(
                        'Wanafunzi Wote',
                        _formatNumber(_stats['total_students'] ?? 0),
                        Icons.people_outlined,
                        const Color(0xFF1A2E5A),
                        '+12%',
                        true,
                        surfaceColor,
                        textPrimary)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard(
                        'Maoni ya Jumla',
                        _formatNumber(_stats['total_views'] ?? 0),
                        Icons.visibility_outlined,
                        const Color(0xFFE87722),
                        '+8%',
                        true,
                        surfaceColor,
                        textPrimary)),
              ]),

              const SizedBox(height: 12),

              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: _buildStatCard(
                        'Ukamilishaji',
                        '${_stats['completion_rate'] ?? 0}%',
                        Icons.check_circle_outline,
                        const Color(0xFF2E7D32),
                        'wastani',
                        true,
                        surfaceColor,
                        textPrimary)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard(
                        'Ukadiriaji',
                        '${(_stats['avg_rating'] as double? ?? 0.0).toStringAsFixed(1)}★',
                        Icons.star_outline,
                        const Color(0xFFFFA726),
                        'kwa kozi',
                        true,
                        surfaceColor,
                        textPrimary)),
              ]),

              const SizedBox(height: 28),

              // ── RECENT COURSES HEADER ──
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kozi Zangu',
                        style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary)),
                    GestureDetector(
                        onTap: () => _tabController.animateTo(1),
                        child: Text('Zote →',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE87722)))),
                  ]),

              const SizedBox(height: 14),

              // ── RECENT COURSES (max 3) ──
              if (_courses.isEmpty)
                _buildEmptyState(
                    'Huna kozi bado.\nBonyeza + kuunda kozi yako ya kwanza!',
                    Icons.school_outlined,
                    surfaceColor)
              else
                ..._courses
                    .take(3)
                    .map((c) => _buildCourseCard(
                        c as Map, surfaceColor, textPrimary, textSecondary)),

              const SizedBox(height: 80),
            ])));
  }

  Widget _buildQuickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
        child: GestureDetector(
            onTap: onTap,
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: color.withValues(alpha: 0.2))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 18)),
                  const SizedBox(height: 6),
                  Text(label,
                      style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color),
                      textAlign: TextAlign.center),
                ]))));
  }

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color color,
      String trend,
      bool trendUp,
      Color surfaceColor,
      Color textPrimary) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFE87722).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20)),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: trendUp
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                        : const Color(0xFFB71C1C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(trend,
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: trendUp
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFB71C1C)))),
          ]),
          const SizedBox(height: 14),
          Text(value,
              style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textPrimary)),
          const SizedBox(height: 4),
          Text(title,
              style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7B3A10))),
        ]));
  }

  Widget _buildEmptyState(
      String message, IconData icon, Color surfaceColor) {
    return Center(
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                      color: Color(0xFFF5E6D8), shape: BoxShape.circle),
                  child: Icon(icon, size: 44, color: const Color(0xFFE87722))),
              const SizedBox(height: 20),
              Text(message,
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7B3A10),
                      height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/trainer/course-builder'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Unda Kozi',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE87722),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14))),
            ])));
  }

  Widget _buildCoursesTab(Color bgColor, Color surfaceColor,
      Color textPrimary, Color textSecondary) {
    return RefreshIndicator(
        color: const Color(0xFFE87722),
        onRefresh: () async => _loadAll(),
        child: _courses.isEmpty
            ? _buildEmptyState(
                'Huna kozi bado.\nAnza kuunda kozi yako ya kwanza!',
                Icons.school_outlined,
                surfaceColor)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                itemCount: _courses.length,
                itemBuilder: (_, i) => _buildCourseCard(
                    _courses[i] as Map,
                    surfaceColor,
                    textPrimary,
                    textSecondary)));
  }

  Widget _buildCourseCard(Map course, Color surfaceColor, Color textPrimary,
      Color textSecondary) {
    final isPublished = course['status'] == 'published';
    final title = course['title'] as String? ?? '';
    final thumbnail = course['cover_photo'] as String?;
    final students = course['student_count'] as int? ?? 0;
    final rating = (course['average_rating'] as num? ?? 0).toDouble();
    final price = course['price'];
    final courseId = course['id'] as int? ?? 0;

    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFE87722).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: Column(children: [
          // ── THUMBNAIL WITH STATUS BADGE ──
          ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16)),
              child: Stack(children: [
                thumbnail != null && thumbnail.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumbnail,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            height: 130,
                            color: const Color(0xFFF5E6D8),
                            child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFE87722)))),
                        errorWidget: (_, __, ___) => Container(
                            height: 130,
                            color: const Color(0xFFF5E6D8),
                            child: const Icon(Icons.school_outlined,
                                color: Color(0xFFE87722), size: 44)))
                    : Container(
                        height: 130,
                        color: const Color(0xFFF5E6D8),
                        child: const Center(
                            child: Icon(Icons.school_outlined,
                                color: Color(0xFFE87722), size: 44))),

                // Dark gradient at bottom of thumbnail
                Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                          Colors.transparent,
                          const Color(0xFF1A0A00).withValues(alpha: 0.55)
                        ], begin: Alignment.topCenter, end: Alignment.bottomCenter)))),

                // Status badge top-right
                Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: isPublished
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF7B3A10),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPublished
                                      ? const Color(0xFF81C784)
                                      : const Color(0xFFFFB74D))),
                          const SizedBox(width: 5),
                          Text(isPublished ? 'Imechapishwa' : 'Rasimu',
                              style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ]))),
              ])),

          // ── COURSE DETAILS ──
          Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),

                    const SizedBox(height: 10),

                    // Metrics row
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
                      Text(_formatPrice(price),
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE87722))),
                    ]),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF5E6D8)),
                    const SizedBox(height: 10),

                    // ── ACTION BUTTONS ROW ──
                    Row(children: [
                      // Publish toggle
                      GestureDetector(
                          onTap: () => _showPublishConfirm(course),
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                  color: isPublished
                                      ? const Color(0xFF2E7D32)
                                          .withValues(alpha: 0.08)
                                      : const Color(0xFFE87722)
                                          .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: isPublished
                                          ? const Color(0xFF2E7D32)
                                              .withValues(alpha: 0.35)
                                          : const Color(0xFFE87722)
                                              .withValues(alpha: 0.35))),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        isPublished
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 13,
                                        color: isPublished
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFE87722)),
                                    const SizedBox(width: 5),
                                    Text(
                                        isPublished
                                            ? 'Imechapishwa'
                                            : 'Chapisha',
                                        style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isPublished
                                                ? const Color(0xFF2E7D32)
                                                : const Color(0xFFE87722))),
                                  ]))),

                      const Spacer(),

                      // Quiz button
                      _buildSmallAction('Majaribio', Icons.quiz_outlined,
                          () => context.push('/trainer/quiz/$courseId')),
                      const SizedBox(width: 6),

                      // Edit button
                      _buildSmallAction(
                          'Hariri',
                          Icons.edit_outlined,
                          () => context.push(
                              '/trainer/course-builder?courseId=$courseId')),
                    ]),
                  ])),
        ]));
  }

  Widget _buildSmallAction(
      String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFF5E6D8),
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 12, color: const Color(0xFF7B3A10)),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7B3A10))),
            ])));
  }

  void _showPublishConfirm(Map course) {
    final isPublished = course['status'] == 'published';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text(isPublished ? 'Ficha Kozi?' : 'Chapisha Kozi?',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A0A00))),
                content: Text(
                    isPublished
                        ? 'Kozi itafichwa na wanafunzi hawataweza kuiona tena.'
                        : 'Kozi itaonekana kwa wanafunzi wote. Tayari?',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: const Color(0xFF7B3A10),
                        height: 1.5)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Hapana',
                          style: GoogleFonts.montserrat(
                              color: const Color(0xFF7B3A10)))),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _togglePublish(course);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: isPublished
                              ? const Color(0xFFB71C1C)
                              : const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(
                          isPublished ? 'Ndiyo, Ficha' : 'Ndiyo, Chapisha',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              color: Colors.white))),
                ]));
  }

  Widget _buildStudentsTab(Color bgColor, Color surfaceColor,
      Color textPrimary, Color textSecondary) {
    final totalStudents = _stats['total_students'] as int? ?? 0;

    return RefreshIndicator(
      color: const Color(0xFFE87722),
      onRefresh: () async => _loadAll(),
      child: _courses.isEmpty
          ? _buildEmptyState(
              'Huna wanafunzi bado.\nChapisha kozi ili wanafunzi waweze kujiunga.',
              Icons.people_outline,
              surfaceColor)
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // ── TOTAL STUDENTS SUMMARY CARD ──
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF3D1800), Color(0xFF7B3A10)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  const Color(0xFF3D1800).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6))
                        ]),
                    child: Row(children: [
                      Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.people_outlined,
                              color: Colors.white, size: 30)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Wanafunzi Wote',
                                style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Colors.white.withValues(alpha: 0.7))),
                            const SizedBox(height: 4),
                            Text('$totalStudents',
                                style: GoogleFonts.montserrat(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            Text('katika ${_courses.length} kozi',
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color:
                                        Colors.white.withValues(alpha: 0.6))),
                          ])),
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 52,
                                height: 52,
                                child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                          value:
                                              (_stats['completion_rate'] as int? ??
                                                      0) /
                                                  100,
                                          strokeWidth: 5,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.2),
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                  Color(0xFFFFA726))),
                                      Text('${_stats['completion_rate']}%',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                    ])),
                            const SizedBox(height: 4),
                            Text('Ukamilishaji',
                                style: GoogleFonts.montserrat(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Colors.white.withValues(alpha: 0.6))),
                          ]),
                    ])),

                const SizedBox(height: 24),

                // ── MINI STATS ROW ──
                Row(children: [
                  _buildMiniStat(
                      '$totalStudents', 'Wote', const Color(0xFF1A2E5A)),
                  const SizedBox(width: 10),
                  _buildMiniStat('${(totalStudents * 0.78).round()}',
                      'Wanaoendelea', const Color(0xFFE87722)),
                  const SizedBox(width: 10),
                  _buildMiniStat('${(totalStudents * 0.65).round()}',
                      'Wamekamilisha', const Color(0xFF2E7D32)),
                ]),

                const SizedBox(height: 24),

                // ── PER COURSE BREAKDOWN ──
                Text('Maendeleo kwa Kozi',
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),

                const SizedBox(height: 14),

                ..._courses.map((c) {
                  final course = c as Map;
                  final title = course['title'] as String? ?? '';
                  final students = course['student_count'] as int? ?? 0;
                  final thumbnail = course['cover_photo'] as String?;
                  final rating =
                      (course['average_rating'] as num? ?? 0).toDouble();
                  final isPublished = course['status'] == 'published';
                  final courseId = course['id'] as int? ?? 0;
                  final completionRate = students > 0 ? 0.65 : 0.0;
                  final activeRate = students > 0 ? 0.78 : 0.0;

                  return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFFE87722)
                                    .withValues(alpha: 0.07),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ]),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── COURSE HEADER ROW ──
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: thumbnail != null &&
                                              thumbnail.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: thumbnail,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) =>
                                                  Container(
                                                      width: 56,
                                                      height: 56,
                                                      color: const Color(
                                                          0xFFF5E6D8),
                                                      child: const Icon(
                                                          Icons.school_outlined,
                                                          color: Color(
                                                              0xFFE87722),
                                                          size: 26)))
                                          : Container(
                                              width: 56,
                                              height: 56,
                                              color: const Color(0xFFF5E6D8),
                                              child: const Icon(
                                                  Icons.school_outlined,
                                                  color: Color(0xFFE87722),
                                                  size: 26))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(title,
                                            style: GoogleFonts.montserrat(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          const Icon(Icons.people_outline,
                                              size: 12,
                                              color: Color(0xFF7B3A10)),
                                          const SizedBox(width: 4),
                                          Text('$students wanafunzi',
                                              style: GoogleFonts.montserrat(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      const Color(0xFF7B3A10))),
                                          const SizedBox(width: 10),
                                          const Icon(Icons.star_rounded,
                                              size: 12,
                                              color: Color(0xFFFFA726)),
                                          const SizedBox(width: 3),
                                          Text(rating.toStringAsFixed(1),
                                              style: GoogleFonts.montserrat(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      const Color(0xFF7B3A10))),
                                        ]),
                                      ])),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: isPublished
                                              ? const Color(0xFF2E7D32)
                                                  .withValues(alpha: 0.1)
                                              : const Color(0xFF7B3A10)
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(
                                          isPublished ? 'Hai' : 'Rasimu',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isPublished
                                                  ? const Color(0xFF2E7D32)
                                                  : const Color(0xFF7B3A10)))),
                                ]),

                            const SizedBox(height: 16),
                            const Divider(
                                height: 1, color: Color(0xFFF5E6D8)),
                            const SizedBox(height: 14),

                            // ── COMPLETION BAR ──
                            _buildProgressRow(
                                'Wamekamilisha',
                                completionRate,
                                const Color(0xFF2E7D32),
                                '${(completionRate * 100).round()}%'),

                            const SizedBox(height: 10),

                            // ── ACTIVE BAR ──
                            _buildProgressRow(
                                'Wanaoendelea',
                                activeRate,
                                const Color(0xFFE87722),
                                '${(activeRate * 100).round()}%'),

                            const SizedBox(height: 14),

                            // ── VIEW STUDENTS BUTTON ──
                            SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                    onPressed: () => context.push(
                                        '/trainer/students?courseId=$courseId'),
                                    icon: const Icon(Icons.people_outline,
                                        size: 15),
                                    label: Text('Angalia Wanafunzi',
                                        style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                    style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: const Color(0xFFE87722)
                                                .withValues(alpha: 0.4)),
                                        foregroundColor:
                                            const Color(0xFFE87722),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(28)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10)))),
                          ]));
                }),
              ])));
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Expanded(
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(value,
                  style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(height: 3),
              Text(label,
                  style: GoogleFonts.montserrat(
                      fontSize: 9, fontWeight: FontWeight.w600, color: color),
                  textAlign: TextAlign.center),
            ])));
  }

  Widget _buildProgressRow(
      String label, double value, Color color, String valueText) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7B3A10))),
        Text(valueText,
            style: GoogleFonts.montserrat(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
              value: value,
              backgroundColor: const Color(0xFFF5E6D8),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8)),
    ]);
  }

  Widget _buildCertificatesTab(Color bgColor, Color surfaceColor,
      Color textPrimary, Color textSecondary) {

    final pending = _pendingCerts.where((c) => !(c['is_approved'] as bool)).length;
    final approved = _pendingCerts.where((c) => c['is_approved'] as bool).length;

    return RefreshIndicator(
      color: const Color(0xFFE87722),
      onRefresh: () async => _loadAll(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [

          // ── INFO BANNER ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE87722).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE87722).withValues(alpha: 0.25))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Icon(Icons.workspace_premium_outlined,
                color: Color(0xFFE87722), size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text('Uthibitishaji wa Vyeti',
                  style: GoogleFonts.montserrat(fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D1800))),
                const SizedBox(height: 4),
                Text('Kagua ukamilishaji wa mwanafunzi kisha '
                  'thibitisha ili apate cheti rasmi cha Karakana.',
                  style: GoogleFonts.montserrat(fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7B3A10), height: 1.5)),
              ])),
            ])),

          const SizedBox(height: 16),

          // ── SUMMARY STATS ROW ──
          Row(children: [
            _buildMiniStat('$pending', 'Zinasubiri', const Color(0xFFFFA726)),
            const SizedBox(width: 10),
            _buildMiniStat('$approved', 'Zilizoidhinishwa', const Color(0xFF2E7D32)),
            const SizedBox(width: 10),
            _buildMiniStat('${_pendingCerts.length}', 'Zote', const Color(0xFF1A2E5A)),
          ]),

          const SizedBox(height: 24),

          // ── SECTION TITLE ──
          Text('Maombi ya Vyeti',
            style: GoogleFonts.montserrat(fontSize: 15,
              fontWeight: FontWeight.w600, color: textPrimary)),

          const SizedBox(height: 14),

          // ── CERTIFICATE CARDS ──
          ..._pendingCerts.asMap().entries.map((entry) {
            final index = entry.key;
            final cert = entry.value;
            final isApproved = cert['is_approved'] as bool;
            final progress = cert['progress'] as int;
            final name = cert['name'] as String;
            final course = cert['course'] as String;
            final date = cert['date'] as String;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isApproved
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.2)
                    : const Color(0xFFE87722).withValues(alpha: 0.15)),
                boxShadow: [BoxShadow(
                  color: const Color(0xFFE87722).withValues(alpha: 0.07),
                  blurRadius: 10, offset: const Offset(0, 3))]),
              child: Column(children: [

                // ── STUDENT INFO ──
                Padding(padding: const EdgeInsets.all(16), child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Avatar with initial
                  Container(width: 50, height: 50,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3D1800), Color(0xFFE87722)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                      shape: BoxShape.circle),
                    child: Center(child: Text(
                      name[0].toUpperCase(),
                      style: GoogleFonts.montserrat(fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(name, style: GoogleFonts.montserrat(fontSize: 14,
                      fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 3),
                    Text(course, style: GoogleFonts.montserrat(fontSize: 12,
                      fontWeight: FontWeight.w400, color: const Color(0xFF7B3A10)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                        size: 11, color: Color(0xFFBDA99C)),
                      const SizedBox(width: 4),
                      Text(date, style: GoogleFonts.montserrat(fontSize: 10,
                        fontWeight: FontWeight.w400, color: const Color(0xFFBDA99C))),
                    ]),
                  ])),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isApproved
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                        : const Color(0xFFFFA726).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      isApproved ? '✓ Imethibitishwa' : '⏳ Inasubiri',
                      style: GoogleFonts.montserrat(fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isApproved
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFFFA726)))),
                ])),

                // ── PROGRESS BAR ──
                Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Text('Ukamilishaji wa Kozi',
                        style: GoogleFonts.montserrat(fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7B3A10))),
                      Text('$progress%',
                        style: GoogleFonts.montserrat(fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: progress == 100
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE87722))),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: const Color(0xFFF5E6D8),
                        valueColor: AlwaysStoppedAnimation(
                          progress == 100
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE87722)),
                        minHeight: 8)),
                  ])),

                const SizedBox(height: 14),

                // ── ACTION BUTTONS ──
                Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: !isApproved
                    ? Row(children: [
                        // Reject
                        Expanded(child: OutlinedButton(
                          onPressed: () => _rejectCertificate(index),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: const Color(0xFFB71C1C).withValues(alpha: 0.4)),
                            foregroundColor: const Color(0xFFB71C1C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                            padding: const EdgeInsets.symmetric(vertical: 10)),
                          child: Text('Kataa',
                            style: GoogleFonts.montserrat(fontSize: 13,
                              fontWeight: FontWeight.w700)))),
                        const SizedBox(width: 10),
                        // Approve
                        Expanded(child: ElevatedButton.icon(
                          onPressed: () => _showApproveConfirm(index, cert),
                          icon: const Icon(Icons.workspace_premium_outlined,
                            size: 15),
                          label: Text('Thibitisha Cheti',
                            style: GoogleFonts.montserrat(fontSize: 13,
                              fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                            padding: const EdgeInsets.symmetric(vertical: 10)))),
                      ])
                    // Already approved state
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(28)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          const Icon(Icons.check_circle_outline,
                            color: Color(0xFF2E7D32), size: 16),
                          const SizedBox(width: 8),
                          Text('Cheti Kimethibitishwa',
                            style: GoogleFonts.montserrat(fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E7D32))),
                        ]))),
              ]));
          }),
        ])));
  }

  void _showApproveConfirm(int index, Map<String, dynamic> cert) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.workspace_premium_outlined, color: Color(0xFFE87722)),
        const SizedBox(width: 8),
        Text('Thibitisha Cheti', style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w700, color: const Color(0xFF1A0A00))),
      ]),
      content: Text(
        'Unathibitisha kwamba ${cert['name']} amekamilisha '
        '"${cert['course']}" kwa mafanikio na anastahili cheti rasmi?',
        style: GoogleFonts.montserrat(fontSize: 13,
          color: const Color(0xFF7B3A10), height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hapana',
            style: GoogleFonts.montserrat(color: const Color(0xFF7B3A10)))),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              _pendingCerts[index]['is_approved'] = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                '✓ Cheti cha ${cert['name']} kimethibitishwa!',
                style: GoogleFonts.montserrat()),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))));
          },
          icon: const Icon(Icons.workspace_premium_outlined, size: 16),
          label: Text('Thibitisha', style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)))),
      ]));
  }

  void _rejectCertificate(int index) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Kataa Ombi?', style: GoogleFonts.montserrat(
        fontWeight: FontWeight.w700, color: const Color(0xFF1A0A00))),
      content: Text(
        'Ombi la cheti la ${_pendingCerts[index]['name']} litakataliwa. '
        'Mwanafunzi ataarifiwa.',
        style: GoogleFonts.montserrat(fontSize: 13,
          color: const Color(0xFF7B3A10), height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hapana',
            style: GoogleFonts.montserrat(color: const Color(0xFF7B3A10)))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() => _pendingCerts.removeAt(index));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Ombi limekataliwa.',
                style: GoogleFonts.montserrat()),
              backgroundColor: const Color(0xFFB71C1C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB71C1C),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
          child: Text('Ndiyo, Kataa',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700))),
      ]));
  }

  Widget _buildHeroAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
        expandedHeight: 220,
        pinned: true,
        forceElevated: innerBoxIsScrolled,
        backgroundColor: const Color(0xFF3D1800),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => context.pop()),
        actions: [
          GestureDetector(
              onTap: () => context.push('/wallet'),
              child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(_formatPrice(_stats['balance'] ?? 0),
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ]))),
          IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: Color(0xFFFFA726), size: 24),
              onPressed: () => context.push('/trainer/course-builder')),
        ],
        flexibleSpace: FlexibleSpaceBar(
            title: const SizedBox.shrink(),
            background: Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [
                      Color(0xFF3D1800),
                      Color(0xFF7B3A10),
                      Color(0xFFE87722)
                    ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)),
                child: Stack(clipBehavior: Clip.hardEdge, children: [
                  Positioned(
                      top: -50,
                      right: -30,
                      child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  Colors.white.withValues(alpha: 0.04)))),
                  Positioned(
                      bottom: 20,
                      left: -40,
                      child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFA726)
                                  .withValues(alpha: 0.08)))),
                  SafeArea(
                      child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFE87722)
                                            .withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: const Color(0xFFE87722)
                                                .withValues(alpha: 0.4))),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                              Icons.verified_outlined,
                                              color: Color(0xFFFFA726),
                                              size: 12),
                                          const SizedBox(width: 4),
                                          Text('MWALIMU WA KARAKANA',
                                              style: GoogleFonts.montserrat(
                                                  fontSize: 9,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color:
                                                      const Color(0xFFFFA726),
                                                  letterSpacing: 1.2)),
                                        ])),
                                const SizedBox(height: 12),
                                Consumer<AuthProvider>(
                                    builder: (_, auth, __) => Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Habari, ${auth.userFullName.split(' ').first}! 👋',
                                                  style:
                                                      GoogleFonts.montserrat(
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              Colors.white)),
                                              const SizedBox(height: 4),
                                              Text(
                                                  'Dashibodi yako ya mwalimu',
                                                  style:
                                                      GoogleFonts.montserrat(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: Colors.white
                                                              .withValues(
                                                                  alpha:
                                                                      0.7))),
                                            ])),
                                const SizedBox(height: 20),
                                Row(children: [
                                  _buildHeroStat(
                                      '${_stats['total_courses']}',
                                      'Kozi',
                                      Icons.school_outlined),
                                  Container(
                                      width: 1,
                                      height: 36,
                                      color: Colors.white
                                          .withValues(alpha: 0.2)),
                                  _buildHeroStat(
                                      _formatNumber(
                                          _stats['total_students'] ?? 0),
                                      'Wanafunzi',
                                      Icons.people_outlined),
                                  Container(
                                      width: 1,
                                      height: 36,
                                      color: Colors.white
                                          .withValues(alpha: 0.2)),
                                  _buildHeroStat(
                                      '${(_stats['avg_rating'] as double? ?? 0.0).toStringAsFixed(1)}★',
                                      'Ukadiriaji',
                                      Icons.star_outline),
                                ]),
                              ])))
                ]))));
  }

  Widget _buildStickyTabBar() {
    return SliverPersistentHeader(
        pinned: true,
        delegate: _StickyTabBarDelegate(
            color: const Color(0xFF3D1800),
            tabBar: TabBar(
                controller: _tabController,
                isScrollable: false,
                labelStyle: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w500),
                labelColor: const Color(0xFFE87722),
                unselectedLabelColor:
                    Colors.white.withValues(alpha: 0.5),
                indicatorColor: const Color(0xFFE87722),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Muhtasari'),
                  Tab(text: 'Kozi'),
                  Tab(text: 'Wanafunzi'),
                  Tab(text: 'Vyeti'),
                ])));
  }

  Widget _buildHeroStat(String value, String label, IconData icon) {
    return Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 14),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
      Text(label,
          style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6))),
    ]));
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;

  const _StickyTabBarDelegate({required this.tabBar, required this.color});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: color, child: tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate old) =>
      tabBar != old.tabBar || color != old.color;
}
