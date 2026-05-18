import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../widgets/common/top_popup.dart';
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
  bool _balanceVisible = true;
  bool _showCoursesBackToTop = false;
  // ignore: unused_field
  Map _wallet = {};
  Map _stats = {
    'total_courses': 0,
    'total_students': 0,
    'avg_rating': 0.0,
    'balance': 0,
    'published_courses': 0,
    'draft_courses': 0,
  };

  List _certs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) setState(() {});
    });
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
        ApiClient().dio.get('/api/v1/certificates/?trainer=true'),
      ]);
      final coursesData = results[0].data;
      final courses = coursesData is Map
          ? (coursesData['results'] as List? ?? [])
          : (coursesData as List? ?? []);
      final wallet = results[1].data as Map? ?? {};
      final certsData = results[2].data;
      final certs = certsData is Map
          ? (certsData['results'] as List? ?? [])
          : (certsData as List? ?? []);
      final totalStudents = courses.fold<int>(
          0, (sum, c) => sum + ((c as Map)['student_count'] as int? ?? 0));
      if (mounted) {
        setState(() {
          _courses = courses;
          _wallet = wallet;
          _certs = certs;
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
            'published_courses': courses
                .where((c) => (c as Map)['status'] == 'published')
                .length,
            'draft_courses': courses
                .where((c) => (c as Map)['status'] != 'published')
                .length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshCurrentTab() async {
    await _loadAll();
  }

  Future<void> _togglePublish(Map course) async {
    final id = course['id'];
    final isPublished = course['status'] == 'published';
    try {
      await ApiClient().dio.patch('/api/v1/courses/$id/',
          data: {'status': isPublished ? 'draft' : 'published'});
      if (!mounted) return;
      showTopPopup(
        context,
        isPublished
            ? 'Kozi imefichwa kutoka kwa wanafunzi'
            : 'Kozi imechapishwa kikamilifu!',
        isError: false,
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      showTopPopup(context, 'Hitilafu. Jaribu tena.');
    }
  }

  Future<void> _openTrainerReviews() async {
    if (_courses.isEmpty) {
      showTopPopup(context, 'Bado huna kozi za kuonyesha tathmini.');
      return;
    }
    if (_courses.length == 1) {
      final courseId = (_courses.first as Map)['id'] as int? ?? 0;
      if (courseId > 0) {
        context.push('/course/$courseId/reviews');
      }
      return;
    }

    final selectedCourseId = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5C8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Chagua Kozi ya Tathmini',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D1800),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _courses.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF0E4DA)),
                itemBuilder: (_, i) {
                  final course = _courses[i] as Map;
                  final courseId = course['id'] as int? ?? 0;
                  final title = course['title'] as String? ?? 'Kozi';
                  final reviews = course['review_count'] as int? ?? 0;
                  final rating =
                      (course['average_rating'] as num? ?? 0).toDouble();
                  return ListTile(
                    onTap: () => Navigator.pop(ctx, courseId),
                    leading: const Icon(
                      Icons.rate_review_outlined,
                      color: Color(0xFFE87722),
                    ),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D1800),
                      ),
                    ),
                    subtitle: Text(
                      '$reviews tathmini • ${rating.toStringAsFixed(1)}★',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: const Color(0xFF7B3A10),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Color(0xFFE87722),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selectedCourseId == null || selectedCourseId <= 0) return;
    context.push('/course/$selectedCourseId/reviews');
  }

  String _formatNumber(dynamic n) {
    final num = int.tryParse(n.toString()) ?? 0;
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return '$num';
  }

  String _formatPrice(dynamic p) {
    try {
      final v = double.parse(p.toString());
      return NumberFormat('#,###').format(v);
    } catch (_) {
      return 'TZS $p';
    }
  }

  Future<void> _deleteCourse(Map course) async {
    final id = course['id'];
    final title = course['title']?.toString() ?? 'Kozi';
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Futa Kozi?',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Una uhakika unataka kufuta "$title"? Hii haiwezi kurejeshwa.',
          style: GoogleFonts.montserrat(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hapana', style: GoogleFonts.montserrat()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            child: Text('Ndiyo, Futa', style: GoogleFonts.montserrat()),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    try {
      await ApiClient().dio.delete('/api/v1/courses/$id/');
      if (!mounted) return;
      showTopPopup(context, 'Kozi imefutwa kikamilifu.', isError: false);
      _loadAll();
    } catch (_) {
      if (!mounted) return;
      showTopPopup(context, 'Imeshindikana kufuta kozi. Jaribu tena.');
    }
  }

  // ── CERT HELPERS ──────────────────────────────────────────────────────────

  String _certStudentName(Map cert) {
    final s = cert['student'] as Map?;
    if (s == null) return 'Mwanafunzi';
    final full = s['full_name'] as String?;
    if (full != null && full.trim().isNotEmpty) return full.trim();
    final fn = s['first_name'] as String? ?? '';
    final ln = s['last_name'] as String? ?? '';
    final name = '$fn $ln'.trim();
    return name.isNotEmpty ? name : 'Mwanafunzi';
  }

  String _certCourseName(Map cert) {
    final c = cert['course'] as Map?;
    return c?['title'] as String? ?? cert['course_title'] as String? ?? '';
  }

  String _certDate(Map cert) {
    final raw = cert['created_at'] as String? ?? cert['date'] as String? ?? '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  int _certProgress(Map cert) => cert['progress'] as int? ?? 100;

  Future<void> _approveCert(Map cert) async {
    final id = cert['id'];
    try {
      await ApiClient().dio.patch('/api/v1/certificates/$id/', data: {'is_approved': true});
      if (!mounted) return;
      showTopPopup(context, 'Cheti kimethibitishwa!', isError: false);
      _loadAll();
    } catch (_) {
      if (!mounted) return;
      showTopPopup(context, 'Hitilafu. Jaribu tena.');
    }
  }

  Future<void> _rejectCertApi(Map cert) async {
    final id = cert['id'];
    try {
      await ApiClient().dio.patch('/api/v1/certificates/$id/', data: {'status': 'rejected'});
      if (!mounted) return;
      showTopPopup(context, 'Ombi limekataliwa.', isError: false);
      _loadAll();
    } catch (_) {
      if (!mounted) return;
      showTopPopup(context, 'Hitilafu. Jaribu tena.');
    }
  }

  Future<void> _showAddContentDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unataka Kuongeza Nini?',
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D1800),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Chagua aina ya maudhui unayotaka kuunda.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF9E8070),
              ),
            ),
            const SizedBox(height: 24),
            // Kozi option
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push('/trainer/course/new');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8D5C8)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE87722),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.play_lesson_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kozi',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3D1800),
                            ),
                          ),
                          Text(
                            'Unda kozi mpya yenye sehemu na masomo ya video',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: const Color(0xFF9E8070),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xFFE87722),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Kitabu option
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push('/trainer/ebooks/add');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8D5C8)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D1800),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kitabu cha Kidijitali',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3D1800),
                            ),
                          ),
                          Text(
                            'Pakia na uuze eBook kwenye maktaba ya Karakana',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: const Color(0xFF9E8070),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xFF3D1800),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Cancel
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Ghairi',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xFF9E8070),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A0A00) : const Color(0xFFFFF8F4);
    final surfaceColor = isDark ? const Color(0xFF2A1400) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A0A00);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF7B3A10);

    return Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        bottomNavigationBar: _buildTrainerNavBar(),
        body: NestedScrollView(
            headerSliverBuilder: (_, innerBoxIsScrolled) => [
                  _buildHeroAppBar(innerBoxIsScrolled),
                ],
            body: _isLoading
                ? const Center(
                    child: KarakanaWaveLoader(color: Color(0xFFE87722)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(bgColor, surfaceColor, textPrimary, textSecondary),
                      _buildCoursesTab(bgColor, surfaceColor, textPrimary, textSecondary),
                      _buildStudentsTab(bgColor, surfaceColor, textPrimary, textSecondary),
                      _buildCertificatesTab(bgColor, surfaceColor, textPrimary, textSecondary),
                    ])));
  }

  // ── BOTTOM NAVBAR ─────────────────────────────────────────────────────────

  Widget _buildTrainerNavBar() {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.8),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildNavTab(index: 0, icon: Icons.dashboard_outlined)),
                        Expanded(child: _buildNavTab(index: 1, icon: Icons.school_outlined)),
                        const SizedBox(width: 72),
                        Expanded(child: _buildNavTab(index: 3, icon: Icons.workspace_premium_outlined)),
                        Expanded(
                          child: _buildNavAction(
                            icon: Icons.person_outline_rounded,
                            onTap: () => context.push('/trainer/account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -18,
                child: _buildWalletFab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletFab() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/wallet');
      },
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE87722),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFE87722).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab({required int index, required IconData icon}) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _tabController.animateTo(index));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected
                    ? const Color(0xFFE87722)
                    : Colors.white.withValues(alpha: 0.55),
                size: 24),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isSelected ? 5 : 0,
              height: isSelected ? 5 : 0,
              decoration: const BoxDecoration(
                  color: Color(0xFFE87722), shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.55),
          size: 24,
        ),
      ),
    );
  }

  // ── OVERVIEW TAB ──────────────────────────────────────────────────────────

  Widget _buildOverviewTab(Color bgColor, Color surfaceColor,
      Color textPrimary, Color textSecondary) {
    return RefreshIndicator(
        color: const Color(0xFFE87722),
        onRefresh: () async => _loadAll(),
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── QUICK ACTIONS ──
              Row(children: [
                _buildQuickAction(Icons.school_outlined, 'Kozi',
                    const Color(0xFFE87722), () => _tabController.animateTo(1)),
                const SizedBox(width: 10),
                _buildQuickAction(Icons.workspace_premium_outlined, 'Vyeti',
                    const Color(0xFF7B3A10), () => _tabController.animateTo(3)),
                const SizedBox(width: 10),
                _buildQuickAction(Icons.person_outline_rounded, 'Akaunti',
                    const Color(0xFF3D1800), () => context.push('/trainer/account')),
                const SizedBox(width: 10),
                _buildQuickAction(Icons.account_balance_wallet_outlined, 'Mkoba',
                    const Color(0xFF7B3A10), () => context.push('/wallet')),
              ]),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _openTrainerReviews,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE87722).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE87722).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.rate_review_outlined,
                        color: Color(0xFFE87722),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tathmini za Kozi',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7B3A10),
                          ),
                        ),
                      ),
                      Text(
                        'Fungua',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE87722),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Color(0xFFE87722),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

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
                        const Color(0xFF3D1800),
                        '${_stats['total_courses'] ?? 0} kozi',
                        true,
                        surfaceColor,
                        textPrimary)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard(
                        'Kozi Zilizochapishwa',
                        _formatNumber(_stats['published_courses'] ?? 0),
                        Icons.check_circle_outline,
                        const Color(0xFFE87722),
                        'hai',
                        true,
                        surfaceColor,
                        textPrimary)),
              ]),

              const SizedBox(height: 12),

              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: _buildStatCard(
                        'Kozi Rasimu',
                        _formatNumber(_stats['draft_courses'] ?? 0),
                        Icons.edit_outlined,
                        const Color(0xFF7B3A10),
                        'zinasubiri',
                        true,
                        surfaceColor,
                        textPrimary)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard(
                        'Ukadiriaji',
                        '${(_stats['avg_rating'] as double? ?? 0.0).toStringAsFixed(1)}',
                        Icons.star_outline,
                        const Color(0xFFFFA726),
                        'kwa kozi',
                        true,
                        surfaceColor,
                        textPrimary)),
              ]),

              const SizedBox(height: 28),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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

              const SizedBox(height: 100),
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
                    border: Border.all(color: color.withValues(alpha: 0.2))),
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
            border: Border.all(color: const Color(0xFFE87722).withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF3D1800).withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4)),
              BoxShadow(
                  color: const Color(0xFF3D1800).withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1)),
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
                    color: const Color(0xFFE87722).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(trend,
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE87722)))),
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

  Widget _buildEmptyState(String message, IconData icon, Color surfaceColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8), shape: BoxShape.circle),
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
                  onPressed: () => context.push('/trainer/course-builder'),
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

  // ── COURSES TAB ───────────────────────────────────────────────────────────

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
            : NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final show = notification.metrics.pixels > 420;
                  if (show != _showCoursesBackToTop && mounted) {
                    setState(() => _showCoursesBackToTop = show);
                  }
                  return false;
                },
                child: Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                      itemCount: _courses.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE87722), Color(0xFFB85A16)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE87722).withValues(alpha: 0.28),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    await _showAddContentDialog(context);
                                    await _refreshCurrentTab();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Ongeza Kozi',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'Unda kozi mpya kwa wanafunzi wako',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return _buildCourseCard(
                          _courses[i - 1] as Map,
                          surfaceColor,
                          textPrimary,
                          textSecondary,
                        );
                      },
                    ),
                    if (_showCoursesBackToTop)
                      Positioned(
                        right: 20,
                        bottom: 100,
                        child: FloatingActionButton.small(
                          heroTag: 'coursesBackToTop',
                          backgroundColor: const Color(0xFFE87722),
                          foregroundColor: Colors.white,
                          onPressed: () {
                            final controller = PrimaryScrollController.of(context);
                            if (controller != null) {
                              controller.animateTo(
                                0,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          child: const Icon(Icons.keyboard_arrow_up_rounded),
                        ),
                      ),
                  ],
                ),
              ));
  }

  String _computeRevenue(Map course) {
    final students = course['student_count'] as int? ?? 0;
    final price = (course['price'] as num? ?? 0).toInt();
    final commissionRate = (course['commission_rate'] as num?)?.toDouble();
    int gross = students * price;
    if (commissionRate != null && commissionRate > 0 && commissionRate <= 100) {
      gross = (gross * (1 - commissionRate / 100)).round();
    }
    return _formatPrice(gross);
  }

  Widget _buildCourseCard(Map course, Color surfaceColor, Color textPrimary,
      Color textSecondary, {bool compact = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courseStatus = (course['status'] as String? ?? 'draft');
    final isPublished = courseStatus == 'published';
    final isPendingReview = courseStatus == 'pending_review';
    final statusLabel = isPublished
        ? 'Imechapishwa'
        : isPendingReview
            ? 'Inasubiri Ukaguzi'
            : 'Rasimu';
    final statusBgColor = isPublished
        ? const Color(0xFF2E7D32)
        : isPendingReview
            ? const Color(0xFFE87722)
            : const Color(0xFF6B7280);
    final statusTextColor = isPublished
        ? const Color(0xFF2E7D32)
        : isPendingReview
            ? const Color(0xFFE87722)
            : const Color(0xFF6B7280);
    final publishButtonText = isPublished
        ? 'Imechapishwa'
        : isPendingReview
            ? 'Inasubiri Ukaguzi'
            : 'Chapisha Sasa';
    final title = course['title'] as String? ?? '';
    final thumbnail = course['cover_photo'] as String?;
    final students = course['student_count'] as int? ?? 0;
    final rating = (course['average_rating'] as num? ?? 0).toDouble();
    final price = course['price'];
    final courseId = course['id'] as int? ?? 0;

    return GestureDetector(
      onTap: () => context.push('/trainer/course/$courseId/sections', extra: {'title': title}),
      child: Container(
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
                        height: compact ? 110 : 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            height: compact ? 110 : 130,
                            color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
                            child: const Center(
                                child: KarakanaWaveLoader(
                                    strokeWidth: 2,
                                    color: Color(0xFFE87722)))),
                        errorWidget: (_, __, ___) => Container(
                            height: compact ? 110 : 130,
                            color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
                            child: const Icon(Icons.school_outlined,
                                color: Color(0xFFE87722), size: 44)))
                    : Container(
                        height: compact ? 110 : 130,
                        color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
                        child: const Center(
                            child: Icon(Icons.school_outlined,
                                color: Color(0xFFE87722), size: 44))),

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

                Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFA726))),
                          const SizedBox(width: 5),
                          Text(statusLabel,
                              style: GoogleFonts.montserrat(
                              fontSize: compact ? 8 : 9,
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
                      Text('TZS ${_formatPrice(price)}',
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
                    Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF5E6D8)),
                    const SizedBox(height: 10),

                    // ── ACTION BUTTONS ROW ──
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        GestureDetector(
                          onTap: isPendingReview
                              ? null
                              : () => _showPublishConfirm(course),
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                  color: statusTextColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: statusTextColor.withValues(alpha: 0.35))),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(
                                    isPublished
                                        ? Icons.visibility_outlined
                                        : isPendingReview
                                            ? Icons.hourglass_top_rounded
                                            : Icons.visibility_off_outlined,
                                    size: 13,
                                    color: statusTextColor),
                                const SizedBox(width: 5),
                                Text(
                                  publishButtonText,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusTextColor,
                                  ),
                                ),
                              ])),
                        ),
                        _buildSmallAction('Ongeza Somo', Icons.post_add_rounded,
                            () => context.push('/trainer/course/$courseId/sections',
                                extra: {'title': title})),
                        _buildSmallAction('Majaribio', Icons.quiz_outlined,
                            () => context.push('/trainer/quiz/$courseId')),
                        _buildSmallAction('Tathmini', Icons.rate_review_outlined,
                            () => context.push('/course/$courseId/reviews')),
                        _buildSmallAction(
                            'Hariri',
                            Icons.edit_outlined,
                            () => context.push(
                                '/trainer/course-builder?courseId=$courseId')),
                        _buildSmallAction(
                            'Futa',
                            Icons.delete_outline_rounded,
                            () => _deleteCourse(course),
                            isDanger: true),
                      ],
                    ),
                  ])),
        ]),
      ),
    );
  }

  Widget _buildSmallAction(String label, IconData icon, VoidCallback onTap,
      {bool isDanger = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
                color: isDanger
                    ? const Color(0xFFB71C1C).withValues(alpha: 0.08)
                    : (isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8)),
                border: Border.all(
                  color: isDanger
                      ? const Color(0xFFB71C1C).withValues(alpha: 0.25)
                      : Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 12, color: isDanger ? const Color(0xFFB71C1C) : const Color(0xFF7B3A10)),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDanger ? const Color(0xFFB71C1C) : const Color(0xFF7B3A10))),
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
                              ? const Color(0xFF3D1800)
                              : const Color(0xFFE87722),
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

  // ── STUDENTS TAB ──────────────────────────────────────────────────────────

  Widget _buildStudentsTab(Color bgColor, Color surfaceColor,
      Color textPrimary, Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
                              color: const Color(0xFF3D1800).withValues(alpha: 0.3),
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
                                    color: Colors.white.withValues(alpha: 0.7))),
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
                                    color: Colors.white.withValues(alpha: 0.6))),
                          ])),
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.school_outlined,
                                    color: Colors.white, size: 26)),
                            const SizedBox(height: 4),
                            Text('Kozi Zote',
                                style: GoogleFonts.montserrat(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.6))),
                          ]),
                    ])),

                const SizedBox(height: 24),

                // ── MINI STATS ROW ──
                Row(children: [
                  _buildMiniStat('$totalStudents', 'Wote', const Color(0xFF3D1800)),
                  const SizedBox(width: 10),
                  _buildMiniStat('${_stats['published_courses'] ?? 0}',
                      'Kozi Hai', const Color(0xFFE87722)),
                  const SizedBox(width: 10),
                  _buildMiniStat('${_stats['draft_courses'] ?? 0}',
                      'Rasimu', const Color(0xFF7B3A10)),
                ]),

                const SizedBox(height: 24),

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
                  final courseStatus = (course['status'] as String? ?? 'draft');
                  final isPublished = courseStatus == 'published';
                  final isPendingReview = courseStatus == 'pending_review';
                  final statusLabel = isPublished
                      ? 'Imechapishwa'
                      : isPendingReview
                          ? 'Inasubiri Ukaguzi'
                          : 'Rasimu';
                  final statusColor = isPublished
                      ? const Color(0xFF2E7D32)
                      : isPendingReview
                          ? const Color(0xFFE87722)
                          : const Color(0xFF6B7280);
                  final courseId = course['id'] as int? ?? 0;
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
                                                      color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
                                                      child: const Icon(
                                                          Icons.school_outlined,
                                                          color: Color(0xFFE87722),
                                                          size: 26)))
                                          : Container(
                                              width: 56,
                                              height: 56,
                                              color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
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
                                              size: 12, color: Color(0xFF7B3A10)),
                                          const SizedBox(width: 4),
                                          Text('$students wanafunzi',
                                              style: GoogleFonts.montserrat(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF7B3A10))),
                                          const SizedBox(width: 10),
                                          const Icon(Icons.star_rounded,
                                              size: 12, color: Color(0xFFFFA726)),
                                          const SizedBox(width: 3),
                                          Text(rating.toStringAsFixed(1),
                                              style: GoogleFonts.montserrat(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF7B3A10))),
                                        ]),
                                      ])),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8)),
                                      child: Text(
                                          statusLabel,
                                          style: GoogleFonts.montserrat(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: statusColor))),
                                ]),

                            const SizedBox(height: 16),
                            Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF5E6D8)),
                            const SizedBox(height: 14),

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
                                        foregroundColor: const Color(0xFFE87722),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(28)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10)))),
                          ]));
                }),
              ])),
    );
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

  // ── CERTIFICATES TAB ──────────────────────────────────────────────────────

  Widget _buildCertificatesTab(Color bgColor, Color surfaceColor,
      Color textPrimary, Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pending = _certs.where((c) => (c as Map)['is_approved'] != true).length;
    final approved = _certs.where((c) => (c as Map)['is_approved'] == true).length;

    return RefreshIndicator(
      color: const Color(0xFFE87722),
      onRefresh: () async => _loadAll(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── INFO BANNER ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE87722).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFE87722).withValues(alpha: 0.25))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            _buildMiniStat('$approved', 'Zilizoidhinishwa', const Color(0xFFE87722)),
            const SizedBox(width: 10),
            _buildMiniStat('${_certs.length}', 'Zote', const Color(0xFF3D1800)),
          ]),

          const SizedBox(height: 24),

          Text('Maombi ya Vyeti',
              style: GoogleFonts.montserrat(fontSize: 15,
                  fontWeight: FontWeight.w600, color: textPrimary)),

          const SizedBox(height: 14),

          // ── CERTIFICATE CARDS ──
          if (_certs.isEmpty)
            _buildEmptyState('Hakuna maombi ya vyeti bado.',
                Icons.workspace_premium_outlined, surfaceColor)
          else
            ..._certs.map((c) {
            final cert = c as Map;
            final isApproved = cert['is_approved'] == true;
            final progress = _certProgress(cert);
            final name = _certStudentName(cert);
            final course = _certCourseName(cert);
            final date = _certDate(cert);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isApproved
                        ? const Color(0xFFE87722).withValues(alpha: 0.2)
                        : const Color(0xFFE87722).withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(
                    color: const Color(0xFFE87722).withValues(alpha: 0.07),
                    blurRadius: 10, offset: const Offset(0, 3))]),
              child: Column(children: [

                // ── STUDENT INFO ──
                Padding(padding: const EdgeInsets.all(16), child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 50, height: 50,
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                colors: [Color(0xFF3D1800), Color(0xFFE87722)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            shape: BoxShape.circle),
                        child: Center(child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'M',
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
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF7B3A10)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 5),
                          Row(children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 11, color: Color(0xFFBDA99C)),
                            const SizedBox(width: 4),
                            Text(date, style: GoogleFonts.montserrat(fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFBDA99C))),
                          ]),
                        ])),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: isApproved
                                ? const Color(0xFFE87722).withValues(alpha: 0.1)
                                : const Color(0xFFFFA726).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                            isApproved ? '✓ Imethibitishwa' : '⏳ Inasubiri',
                            style: GoogleFonts.montserrat(fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isApproved
                                    ? const Color(0xFFE87722)
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
                                        color: const Color(0xFFE87722))),
                              ]),
                          const SizedBox(height: 6),
                          ClipRRect(borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                  value: progress / 100,
                                  backgroundColor: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
                                  valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFFE87722)),
                                  minHeight: 8)),
                        ])),

                const SizedBox(height: 14),

                // ── ACTION BUTTONS ──
                Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: !isApproved
                        ? Row(children: [
                            Expanded(child: OutlinedButton(
                                onPressed: () => _showRejectConfirm(cert),
                                style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: const Color(0xFF3D1800).withValues(alpha: 0.4)),
                                    foregroundColor: const Color(0xFF3D1800),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10)),
                                child: Text('Kataa',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)))),
                            const SizedBox(width: 10),
                            Expanded(child: ElevatedButton.icon(
                                onPressed: () => _showApproveConfirm(cert),
                                icon: const Icon(
                                    Icons.workspace_premium_outlined, size: 15),
                                label: Text('Thibitisha Cheti',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE87722),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(28)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10)))),
                          ])
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                                color: const Color(0xFFE87722).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(28)),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      color: Color(0xFFE87722), size: 16),
                                  const SizedBox(width: 8),
                                  Text('Cheti Kimethibitishwa',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFE87722))),
                                ]))),
              ]));
          }),
        ]),
      ),
    );
  }

  void _showApproveConfirm(Map cert) {
    showDialog(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.workspace_premium_outlined, color: Color(0xFFE87722)),
          const SizedBox(width: 8),
          Text('Thibitisha Cheti', style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700, color: const Color(0xFF1A0A00))),
        ]),
        content: Text(
            'Unathibitisha kwamba ${_certStudentName(cert)} amekamilisha '
            '"${_certCourseName(cert)}" kwa mafanikio na anastahili cheti rasmi?',
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
                _approveCert(cert);
              },
              icon: const Icon(Icons.workspace_premium_outlined, size: 16),
              label: Text('Thibitisha',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE87722),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)))),
        ]));
  }

  void _showRejectConfirm(Map cert) {
    showDialog(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Kataa Ombi?', style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700, color: const Color(0xFF1A0A00))),
        content: Text(
            'Ombi la cheti la ${_certStudentName(cert)} litakataliwa. '
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
                _rejectCertApi(cert);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D1800),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('Ndiyo, Kataa',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700))),
        ]));
  }

  // ── HERO APP BAR ──────────────────────────────────────────────────────────

  Widget _buildHeroAppBar(bool innerBoxIsScrolled) {
    String pageTitle;
    switch (_tabController.index) {
      case 1:
        pageTitle = 'Kozi';
        break;
      case 2:
        pageTitle = 'Wanafunzi';
        break;
      case 3:
        pageTitle = 'Vyeti';
        break;
      default:
        pageTitle = 'Muhtasari';
    }
    return SliverAppBar(
        expandedHeight: 196,
        pinned: true,
        forceElevated: innerBoxIsScrolled,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF3D1800),
        actions: const [],
        title: innerBoxIsScrolled
            ? Text(
                pageTitle,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              )
            : null,
        flexibleSpace: FlexibleSpaceBar(
            title: null,
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
                              color: Colors.white.withValues(alpha: 0.04)))),
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
                              const EdgeInsets.fromLTRB(20, 16, 20, 10),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Consumer<AuthProvider>(
                                    builder: (_, auth, __) {
                                      final firstName = auth.userFullName.isNotEmpty
                                          ? auth.userFullName.split(' ').first
                                          : 'Mkufunzi';
                                      final avatarUrl = auth.userAvatar;
                                      final hasAvatar =
                                          avatarUrl != null && avatarUrl.isNotEmpty;
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 20.r,
                                            backgroundColor: AppColors.primary,
                                            backgroundImage: hasAvatar
                                                ? NetworkImage(avatarUrl)
                                                : null,
                                            child: !hasAvatar
                                                ? Text(
                                                    firstName.isNotEmpty
                                                        ? firstName[0]
                                                            .toUpperCase()
                                                        : 'M',
                                                    style: GoogleFonts
                                                        .montserrat(
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('Habari, $firstName!',
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      fontSize: 18.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                    )),
                                                Text('Mkufunzi wa Karakana',
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      fontSize: 12.sp,
                                                      color: Colors.white70,
                                                    )),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                Icons
                                                    .notifications_outlined,
                                                color: Colors.white,
                                                size: 24.r),
                                            onPressed: () =>
                                                context.push('/notifications'),
                                            tooltip: 'Arifa',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                Icons.settings_outlined,
                                                color: Colors.white,
                                                size: 24.r),
                                            onPressed: () =>
                                                context.push('/trainer/account'),
                                            tooltip: 'Mipangilio',
                                          ),
                                        ],
                                      );
                                    }),
                                SizedBox(height: 8.h),
                                Row(children: [
                                  _buildHeroStat('${_stats['total_courses']}',
                                      'Kozi', Icons.school_outlined),
                                  Container(
                                      width: 1,
                                      height: 36,
                                      color: Colors.white.withValues(alpha: 0.2)),
                                  _buildHeroStat(
                                      _formatNumber(
                                          _stats['total_students'] ?? 0),
                                      'Wanafunzi',
                                      Icons.people_outlined),
                                  Container(
                                      width: 1,
                                      height: 36,
                                      color: Colors.white.withValues(alpha: 0.2)),
                                  _buildHeroStat(
                                      '${(_stats['avg_rating'] as double? ?? 0.0).toStringAsFixed(1)}',
                                      'Ukadiriaji',
                                      Icons.star_outline),
                                ]),
                                SizedBox(height: 8.h),
                                Builder(builder: (context) {
                                  final balance =
                                      (_stats['balance'] as num?) ?? 0;
                                  return GestureDetector(
                                    onTap: () => context.push('/wallet'),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                  Icons
                                                      .account_balance_wallet_outlined,
                                                  color: AppColors.primary,
                                                  size: 18.r),
                                              SizedBox(width: 8.w),
                                              Text('Mapato wa Mwezi',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 12.sp,
                                                    color: Colors.white70,
                                                  )),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                _balanceVisible
                                                    ? 'TSh ${balance.toStringAsFixed(0)}'
                                                    : 'TSh ••••••',
                                                style:
                                                    GoogleFonts.montserrat(
                                                  fontSize: 15.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              GestureDetector(
                                                onTap: () => setState(() =>
                                                    _balanceVisible =
                                                        !_balanceVisible),
                                                child: Icon(
                                                  _balanceVisible
                                                      ? Icons
                                                          .visibility_outlined
                                                      : Icons
                                                          .visibility_off_outlined,
                                                  color: Colors.white70,
                                                  size: 18.r,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ])))
                ]))));
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



