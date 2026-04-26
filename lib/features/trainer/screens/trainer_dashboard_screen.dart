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
                      Center(
                          child: Text('Wanafunzi - inajengwa',
                              style: GoogleFonts.montserrat())),
                      Center(
                          child: Text('Vyeti - inajengwa',
                              style: GoogleFonts.montserrat())),
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
