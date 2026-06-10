import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../widgets/common/top_popup.dart';
import '../../auth/providers/auth_provider.dart';
import 'trainer_account_screen.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List _courses = [];
  List _ebooks = [];
  bool _isLoading = true;
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
    // ebook analytics
    'total_ebooks': 0,
    'total_ebook_readers': 0,
    'total_ebook_revenue': 0.0,
    'published_ebooks': 0,
  };

  List _certs = [];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        ApiClient().dio.get('/api/v1/ebooks/my/'),
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
      final ebooksData = results[3].data;
      final ebooks = ebooksData is Map
          ? (ebooksData['results'] as List? ?? [])
          : (ebooksData as List? ?? []);

      final totalStudents = courses.fold<int>(
          0, (sum, c) => sum + ((c as Map)['student_count'] as int? ?? 0));
      final totalEbookReaders = ebooks.fold<int>(
          0, (sum, e) => sum + ((e as Map)['buyers_count'] as int? ?? 0));
      final totalEbookRevenue = ebooks.fold<double>(
          0.0,
          (sum, e) =>
              sum +
              (double.tryParse(
                      ((e as Map)['total_revenue'] ?? '0').toString()) ??
                  0.0));

      if (mounted) {
        setState(() {
          _courses = courses;
          _ebooks = ebooks;
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
            // ebook analytics
            'total_ebooks': ebooks.length,
            'total_ebook_readers': totalEbookReaders,
            'total_ebook_revenue': totalEbookRevenue,
            'published_ebooks': ebooks
                .where((e) => (e as Map)['status'] == 'published')
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

  void _openAccountTab() {
    _tabController.animateTo(4);
  }

  Future<void> _togglePublish(Map course) async {
    final id = course['id'];
    final isPublished = course['status'] == 'published';
    try {
      await ApiClient().dio.patch('/api/v1/courses/$id/',
          data: {'status': isPublished ? 'draft' : 'pending_review'});
      if (!mounted) return;
      showTopPopup(
        context,
        isPublished
            ? 'Kozi imefichwa kutoka kwa wanafunzi'
            : 'Kozi imetumwa kwa ukaguzi. Itachapishwa baada ya kupitishwa na timu ya Kreative Karakana.',
        isError: false,
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      showTopPopup(context, 'Hitilafu. Jaribu tena.');
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
      return NumberFormat('#,###').format(v);
    } catch (_) {
      return 'TZS $p';
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Habari za Asubuhi';
    if (hour < 17) return 'Habari za Mchana';
    if (hour < 21) return 'Habari za Jioni';
    return 'Habari za Usiku';
  }

  IconData _getTimeIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.light_mode_outlined;
    if (hour < 17) return Icons.wb_sunny_outlined;
    if (hour < 21) return Icons.wb_twilight_outlined;
    return Icons.bedtime_outlined;
  }

  String _getTagline() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Siku nzuri ya kufundisha na kukua';
    if (hour < 17) return 'Endelea kusukuma mafanikio yako leo';
    if (hour < 21) return 'Angalia maendeleo ya kozi zako';
    return 'Pitia takwimu zako kabla ya kesho';
  }

  String _getFirstName(AuthProvider auth) {
    final fullName = auth.userFullName.trim();
    if (fullName.isNotEmpty) return fullName.split(' ').first;
    final email = auth.userEmail;
    if (email.isNotEmpty) return email.split('@').first;
    return 'Mkufunzi';
  }

  Future<void> _deleteCourse(Map course) async {
    final id = course['id'];
    final title = course['title']?.toString() ?? 'Kozi';
    final shouldRequestDeletion = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Omba Kufuta Kozi?',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Ombi lako la kufuta "$title" litatumwa kwa timu ya Kreative Karakana kwa ukaguzi kabla kozi haijafutwa.',
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
            child: Text('Tuma Ombi', style: GoogleFonts.montserrat()),
          ),
        ],
      ),
    );
    if (shouldRequestDeletion != true) return;
    try {
      await ApiClient().dio.post('/api/v1/courses/$id/deletion-request/');
      if (!mounted) return;
      showTopPopup(
        context,
        'Ombi lako la kufuta kozi limepokelewa na lipo kwenye ukaguzi.',
        isError: false,
      );
      _loadAll();
    } catch (_) {
      if (!mounted) return;
      showTopPopup(
          context, 'Imeshindikana kutuma ombi la kufuta kozi. Jaribu tena.');
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
      await ApiClient()
          .dio
          .patch('/api/v1/certificates/$id/', data: {'is_approved': true});
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
      await ApiClient()
          .dio
          .patch('/api/v1/certificates/$id/', data: {'status': 'rejected'});
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
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
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
                'Ongeza Kozi au Kitabu cha Kidijitali',
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3D1800),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chagua kama unataka kuunda kozi au kupakia kitabu cha kidijitali.',
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
                  context.push('/trainer/course-builder');
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
                  context.push('/trainer/ebooks');
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
                              'Vitabu vya Kidijitali',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3D1800),
                              ),
                            ),
                            Text(
                              'Simamia na angalia takwimu za eBooks zako',
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
                  _buildHeroAppBar(context, innerBoxIsScrolled),
                ],
            body: _isLoading
                ? const Center(
                    child: KarakanaWaveLoader(color: Color(0xFFE87722)))
                : TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                        _buildOverviewTab(
                            surfaceColor, textPrimary, textSecondary),
                        _buildCoursesTab(
                            bgColor, surfaceColor, textPrimary, textSecondary),
                        _buildStudentsTab(
                            bgColor, surfaceColor, textPrimary, textSecondary),
                        _buildCertificatesTab(
                            bgColor, surfaceColor, textPrimary, textSecondary),
                        TrainerAccountScreen(
                          embeddedInDashboard: true,
                          onTabSwitch: (index) =>
                              _tabController.animateTo(index),
                        ),
                      ])));
  }

  // ── BOTTOM NAVBAR ─────────────────────────────────────────────────────────

  Widget _buildTrainerNavBar() {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildNavTab(
                            index: 0,
                            icon: Icons.dashboard_outlined,
                          ),
                        ),
                        Expanded(
                          child: _buildNavTab(
                            index: 1,
                            icon: Icons.collections_bookmark_outlined,
                          ),
                        ),
                        const SizedBox(width: 56),
                        Expanded(
                          child: _buildNavTab(
                            index: 3,
                            icon: Icons.workspace_premium_outlined,
                          ),
                        ),
                        Expanded(
                          child: _buildNavAction(
                            index: 4,
                            icon: Icons.person_outline_rounded,
                            onTap: () => setState(_openAccountTab),
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
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white, size: 28),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected
                    ? const Color(0xFFE87722)
                    : Colors.white.withValues(alpha: 0.55),
                size: 22),
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
    required int index,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFE87722)
                  : Colors.white.withValues(alpha: 0.55),
              size: 22,
            ),
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

  // ── OVERVIEW TAB ──────────────────────────────────────────────────────────

  Widget _buildOverviewTab(
      Color surfaceColor, Color textPrimary, Color textSecondary) {
    return RefreshIndicator(
        color: const Color(0xFFE87722),
        onRefresh: () async => _loadAll(),
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildQuickActionsRow(),
              const SizedBox(height: 22),
              Text(
                'Takwimu za Jumla',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(surfaceColor, textPrimary),
              const SizedBox(height: 24),
              _sectionHeader(
                'Kozi Zangu',
                'Angalia hali ya kozi zako na uendelee kuziboresha.',
                onTap: () => _tabController.animateTo(1),
                actionLabel: 'Zote',
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 12),
              if (_courses.isEmpty)
                _buildEmptyState(
                  'Huna kozi bado.\nBonyeza + kuunda kozi yako ya kwanza!',
                  Icons.school_outlined,
                  surfaceColor,
                )
              else
                ..._courses.take(3).map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCourseCard(
                          c as Map,
                          surfaceColor,
                          textPrimary,
                          textSecondary,
                        ),
                      ),
                    ),

              const SizedBox(height: 28),

              // ── EBOOKS PREVIEW SECTION ──
              _sectionHeader(
                'Vitabu vya Kidijitali',
                'Fuatilia mauzo na wasomaji wa eBooks zako.',
                onTap: () => _tabController.animateTo(1),
                actionLabel: 'Zote',
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 12),
              if (_ebooks.isEmpty)
                GestureDetector(
                  onTap: () => context.push('/trainer/ebooks/add'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFE87722)
                              .withValues(alpha: 0.2),
                          style: BorderStyle.solid),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE87722)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.menu_book_outlined,
                            color: Color(0xFFE87722), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pakia eBook yako ya kwanza',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Gusa hapa kuanza kupata mapato kutoka vitabu',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: const Color(0xFF7B3A10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.add_circle_outline_rounded,
                          color: Color(0xFFE87722), size: 22),
                    ]),
                  ),
                )
              else
                ..._ebooks.take(2).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildEbookOverviewCard(
                          e as Map, surfaceColor, textPrimary),
                    )),

              const SizedBox(height: 100),
            ])));
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        _buildQuickAction(
          Icons.school_outlined,
          'Kozi',
          'Boresha maudhui',
          const Color(0xFFE87722),
          () => _tabController.animateTo(1),
        ),
        const SizedBox(width: 10),
        _buildQuickAction(
          Icons.menu_book_outlined,
          'Vitabu',
          'Simamia eBooks',
          const Color(0xFF3D1800),
          () => _tabController.animateTo(1),
        ),
        const SizedBox(width: 10),
        _buildQuickAction(
          Icons.workspace_premium_outlined,
          'Vyeti',
          'Pitia vyeti',
          const Color(0xFF7B3A10),
          () => _tabController.animateTo(3),
        ),
        const SizedBox(width: 10),
        _buildQuickAction(
          Icons.account_balance_wallet_outlined,
          'Mkoba',
          'Mapato',
          const Color(0xFF7B3A10),
          () => context.push('/wallet'),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Color surfaceColor, Color textPrimary) {
    final ebookRevenue = _stats['total_ebook_revenue'] as double? ?? 0.0;
    final ebookRevenueStr = ebookRevenue >= 1000000
        ? 'TZS ${(ebookRevenue / 1000000).toStringAsFixed(1)}M'
        : ebookRevenue >= 1000
            ? 'TZS ${(ebookRevenue / 1000).toStringAsFixed(0)}K'
            : 'TZS ${_formatNumber(ebookRevenue.toInt())}';

    return Column(
      children: [
        // ── ROW 1: courses ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildStatCard(
                'Wanafunzi Wote',
                _formatNumber(_stats['total_students'] ?? 0),
                Icons.people_outlined,
                const Color(0xFF3D1800),
                '${_stats['total_courses'] ?? 0} kozi',
                true,
                surfaceColor,
                textPrimary,
              ),
            ),
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
                textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ── ROW 2: course misc + rating ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildStatCard(
                'Kozi Rasimu',
                _formatNumber(_stats['draft_courses'] ?? 0),
                Icons.edit_outlined,
                const Color(0xFF7B3A10),
                'zinasubiri',
                true,
                surfaceColor,
                textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Ukadiriaji',
                (_stats['avg_rating'] as double? ?? 0.0).toStringAsFixed(1),
                Icons.star_outline,
                const Color(0xFFFFA726),
                'kwa kozi',
                true,
                surfaceColor,
                textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // ── EBOOK SECTION DIVIDER ──
        Row(children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE87722),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Vitabu vya Kidijitali',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        // ── ROW 3: ebook readers + revenue ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildStatCard(
                'Wasomaji',
                _formatNumber(_stats['total_ebook_readers'] ?? 0),
                Icons.people_outlined,
                const Color(0xFF3D1800),
                '${_stats['total_ebooks'] ?? 0} vitabu',
                true,
                surfaceColor,
                textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Mapato ya eBooks',
                ebookRevenueStr,
                Icons.payments_outlined,
                const Color(0xFF2E7D32),
                'jumla',
                true,
                surfaceColor,
                textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ── ROW 4: published ebooks + total ebooks ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildStatCard(
                'eBooks Zilizochapishwa',
                _formatNumber(_stats['published_ebooks'] ?? 0),
                Icons.check_circle_outline,
                const Color(0xFFE87722),
                'zinaonekana',
                true,
                surfaceColor,
                textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'eBooks Zote',
                _formatNumber(_stats['total_ebooks'] ?? 0),
                Icons.menu_book_outlined,
                const Color(0xFF1565C0),
                'zilizopakiwa',
                true,
                surfaceColor,
                textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionHeader(
    String title,
    String subtitle, {
    required Color textPrimary,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 11.5,
                  color: const Color(0xFF7B3A10),
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              '$actionLabel →',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE87722),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, String subtitle,
      Color color, VoidCallback onTap) {
    return Expanded(
        child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 114,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D1800).withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 10),
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
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: color.withValues(alpha: 0.55),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A0A00),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 9.8,
                  height: 1.1,
                  color: const Color(0xFF7B3A10),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      String trend, bool trendUp, Color surfaceColor, Color textPrimary) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFFE87722).withValues(alpha: 0.15)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0EAE3),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(trend,
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9E8070)))),
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
                      color: isDark
                          ? const Color(0xFF2A1A0A)
                          : const Color(0xFFF5E6D8),
                      shape: BoxShape.circle),
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
                      style:
                          GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
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

  Widget _buildCoursesTab(Color bgColor, Color surfaceColor, Color textPrimary,
      Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_courses.isEmpty && _ebooks.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFFE87722),
        onRefresh: () async => _loadAll(),
        child: ListView(
          children: [
            // CTA banner even when empty
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _buildMaudhuiCtaBanner(),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: _buildEmptyState(
                'Huna kozi au eBook bado.\nAnza kuunda maudhui yako ya kwanza!',
                Icons.collections_bookmark_outlined,
                surfaceColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFE87722),
      onRefresh: () async => _loadAll(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 100),
        children: [
          // ── CTA BANNER ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildMaudhuiCtaBanner(),
          ),

          // ── COURSES CAROUSEL ──
          if (_courses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE87722).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_outlined,
                      size: 17, color: Color(0xFFE87722)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kozi',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                // count chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFE87722).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_courses.length}',
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE87722)),
                  ),
                ),
                const SizedBox(width: 8),
                // "View all" link
                GestureDetector(
                  onTap: () => context.push('/trainer/courses'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE87722).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFE87722).withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        'Zote',
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE87722)),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 12, color: Color(0xFFE87722)),
                    ]),
                  ),
                ),
              ]),
            ),
            SizedBox(
              height: 230,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _courses.length,
                itemBuilder: (context, i) {
                  final c = _courses[i] as Map;
                  return _buildCarouselCourseCard(
                      c, surfaceColor, textPrimary, textSecondary, isDark);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── EBOOKS CAROUSEL ──
          if (_ebooks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D1800).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book_outlined,
                      size: 17, color: Color(0xFF3D1800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vitabu vya Kidijitali',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D1800).withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_ebooks.length}',
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D1800)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.push('/trainer/ebooks'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D1800).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              const Color(0xFF3D1800).withValues(alpha: 0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        'Zote',
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D1800)),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 12, color: Color(0xFF3D1800)),
                    ]),
                  ),
                ),
              ]),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _ebooks.length,
                itemBuilder: (context, i) {
                  final e = _ebooks[i] as Map;
                  return _buildCarouselEbookCard(
                      e, surfaceColor, textPrimary, isDark);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaudhuiCtaBanner() {
    return Container(
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
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ongeza Kozi au Kitabu cha Kidijitali',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    Text(
                      'Unda kozi mpya au pakia kitabu cha kidijitali',
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ]),
          ),
        ),
      ),
    );
  }

  /// Compact vertical course card for the horizontal carousel (fixed width 160).
  Widget _buildCarouselCourseCard(Map course, Color surfaceColor,
      Color textPrimary, Color textSecondary, bool isDark) {
    final title = course['title'] as String? ?? '';
    final thumbnail = course['cover_photo'] as String?;
    final students = course['student_count'] as int? ?? 0;
    final rating = (course['average_rating'] as num? ?? 0).toDouble();
    final price = course['price'];
    final courseId = course['id'] as int? ?? 0;
    final statusStr = course['status'] as String? ?? 'draft';
    final isPublished = statusStr == 'published';
    final statusColor = isPublished
        ? const Color(0xFF2E7D32)
        : statusStr == 'pending_review'
            ? const Color(0xFFE87722)
            : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: () => context.push('/trainer/course/$courseId/sections',
          extra: {'title': title}),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE87722).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // thumbnail
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(children: [
              thumbnail != null && thumbnail.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumbnail,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 100,
                        color: isDark
                            ? const Color(0xFF3A2010)
                            : const Color(0xFFF5E6D8),
                        child: const Center(
                            child: KarakanaWaveLoader(
                                strokeWidth: 2, color: Color(0xFFE87722))),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 100,
                        color: isDark
                            ? const Color(0xFF3A2010)
                            : const Color(0xFFF5E6D8),
                        child: const Icon(Icons.school_outlined,
                            color: Color(0xFFE87722), size: 32),
                      ),
                    )
                  : Container(
                      height: 100,
                      color: isDark
                          ? const Color(0xFF3A2010)
                          : const Color(0xFFF5E6D8),
                      child: const Center(
                          child: Icon(Icons.school_outlined,
                              color: Color(0xFFE87722), size: 32)),
                    ),
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPublished ? '✓' : statusStr == 'pending_review' ? '⏳' : '✎',
                    style: const TextStyle(fontSize: 9, color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
          // details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(children: [
                      const Icon(Icons.people_outline,
                          size: 11, color: Color(0xFF7B3A10)),
                      const SizedBox(width: 3),
                      Text('$students',
                          style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7B3A10))),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          size: 11, color: Color(0xFFFFA726)),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7B3A10))),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      'TZS ${_formatPrice(price)}',
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE87722)),
                    ),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }

  /// Compact vertical ebook card for the horizontal carousel (fixed width 130).
  Widget _buildCarouselEbookCard(
      Map e, Color surfaceColor, Color textPrimary, bool isDark) {
    final title = (e['title'] ?? '').toString();
    final cover = e['cover_image']?.toString();
    final buyers = e['buyers_count'] as int? ?? 0;
    final price =
        (double.tryParse((e['price'] ?? '0').toString()) ?? 0).toInt();
    final ebookId = e['id'] as int? ?? 0;
    final statusStr = (e['status'] as String? ?? 'draft');
    final isPublished = statusStr == 'published';
    final statusColor = isPublished
        ? const Color(0xFF2E7D32)
        : statusStr == 'pending_review'
            ? const Color(0xFFE87722)
            : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: () async {
        await context.push('/trainer/ebooks/$ebookId');
        await _loadAll();
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE87722).withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // cover
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(children: [
              Container(
                height: 110,
                width: double.infinity,
                color: isDark
                    ? const Color(0xFF2A1A0A)
                    : const Color(0xFFF5E6D8),
                child: cover != null && cover.isNotEmpty
                    ? Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.menu_book_outlined,
                            color: Color(0xFFE87722),
                            size: 34),
                      )
                    : const Icon(Icons.menu_book_outlined,
                        color: Color(0xFFE87722), size: 34),
              ),
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ]),
          ),
          // details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(children: [
                      const Icon(Icons.people_outline,
                          size: 11, color: Color(0xFF7B3A10)),
                      const SizedBox(width: 3),
                      Text('$buyers',
                          style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7B3A10))),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      'TZS ${_formatPrice(price)}',
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE87722)),
                    ),
                  ]),
            ),
          ),
        ]),
      ),
    );
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

  Widget _buildCourseCard(
      Map course, Color surfaceColor, Color textPrimary, Color textSecondary,
      {bool compact = false}) {
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
            : 'Tuma kwa Ukaguzi';
    final title = course['title'] as String? ?? '';
    final thumbnail = course['cover_photo'] as String?;
    final students = course['student_count'] as int? ?? 0;
    final rating = (course['average_rating'] as num? ?? 0).toDouble();
    final price = course['price'];
    final courseId = course['id'] as int? ?? 0;

    return GestureDetector(
      onTap: () => context
          .push('/trainer/course/$courseId/sections', extra: {'title': title}),
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
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              child: Stack(children: [
                thumbnail != null && thumbnail.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumbnail,
                        height: compact ? 110 : 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            height: compact ? 110 : 130,
                            color: isDark
                                ? const Color(0xFF2A1A0A)
                                : const Color(0xFFF5E6D8),
                            child: const Center(
                                child: KarakanaWaveLoader(
                                    strokeWidth: 2, color: Color(0xFFE87722)))),
                        errorWidget: (_, __, ___) => Container(
                            height: compact ? 110 : 130,
                            color: isDark
                                ? const Color(0xFF2A1A0A)
                                : const Color(0xFFF5E6D8),
                            child: const Icon(Icons.school_outlined,
                                color: Color(0xFFE87722), size: 44)))
                    : Container(
                        height: compact ? 110 : 130,
                        color: isDark
                            ? const Color(0xFF2A1A0A)
                            : const Color(0xFFF5E6D8),
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
                            gradient: LinearGradient(
                                colors: [
                              Colors.transparent,
                              const Color(0xFF1A0A00).withValues(alpha: 0.55)
                            ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter)))),
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
                    Divider(
                        height: 1,
                        color:
                            isDark ? Colors.white10 : const Color(0xFFF5E6D8)),
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
                                  color:
                                      statusTextColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: statusTextColor.withValues(
                                          alpha: 0.35))),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                        _buildSmallAction(
                            'Ongeza Somo',
                            Icons.post_add_rounded,
                            () => context.push(
                                '/trainer/course/$courseId/sections',
                                extra: {'title': title})),
                        _buildSmallAction('Majaribio', Icons.quiz_outlined,
                            () => context.push('/trainer/quiz/$courseId')),
                        _buildSmallAction(
                            'Tathmini',
                            Icons.rate_review_outlined,
                            () => context.push('/course/$courseId/reviews')),
                        _buildSmallAction(
                            'Hariri',
                            Icons.edit_outlined,
                            () => context.push(
                                '/trainer/course-builder?courseId=$courseId')),
                        _buildSmallAction('Futa', Icons.delete_outline_rounded,
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
                    : (isDark
                        ? const Color(0xFF2A1A0A)
                        : const Color(0xFFF5E6D8)),
                border: Border.all(
                  color: isDanger
                      ? const Color(0xFFB71C1C).withValues(alpha: 0.25)
                      : Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  size: 12,
                  color: isDanger
                      ? const Color(0xFFB71C1C)
                      : const Color(0xFF7B3A10)),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDanger
                          ? const Color(0xFFB71C1C)
                          : const Color(0xFF7B3A10))),
            ])));
  }

  void _showPublishConfirm(Map course) {
    final isPublished = course['status'] == 'published';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text(
                    isPublished ? 'Ficha Kozi?' : 'Tuma Kozi kwa Ukaguzi?',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A0A00))),
                content: Text(
                    isPublished
                        ? 'Kozi itafichwa na wanafunzi hawataweza kuiona tena.'
                        : 'Kozi haitachapishwa moja kwa moja. Timu ya Kreative Karakana itaipitia kwanza kabla haijaonekana kwa wanafunzi.',
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
                          isPublished ? 'Ndiyo, Ficha' : 'Tuma kwa Ukaguzi',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              color: Colors.white))),
                ]));
  }

  // ── STUDENTS TAB ──────────────────────────────────────────────────────────

  Widget _buildStudentsTab(Color bgColor, Color surfaceColor, Color textPrimary,
      Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalStudents = _stats['total_students'] as int? ?? 0;

    return RefreshIndicator(
      color: const Color(0xFFE87722),
      onRefresh: () async => _loadAll(),
      child: _courses.isEmpty
          ? _buildEmptyState(
              'Huna wanafunzi bado.\nTuma kozi kwa ukaguzi ili iweze kuchapishwa baada ya kupitishwa.',
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
                                  color: const Color(0xFF3D1800)
                                      .withValues(alpha: 0.3),
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
                                        color: Colors.white
                                            .withValues(alpha: 0.7))),
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
                                        color: Colors.white
                                            .withValues(alpha: 0.6))),
                              ])),
                          Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.school_outlined,
                                        color: Colors.white, size: 26)),
                                const SizedBox(height: 4),
                                Text('Kozi Zote',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white
                                            .withValues(alpha: 0.6))),
                              ]),
                        ])),

                    const SizedBox(height: 24),

                    // ── MINI STATS ROW ──
                    Row(children: [
                      _buildMiniStat(
                          '$totalStudents', 'Wote', const Color(0xFF3D1800)),
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
                      final courseStatus =
                          (course['status'] as String? ?? 'draft');
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: thumbnail != null &&
                                                  thumbnail.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: thumbnail,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) => Container(
                                                      width: 56,
                                                      height: 56,
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF2A1A0A)
                                                          : const Color(
                                                              0xFFF5E6D8),
                                                      child: const Icon(
                                                          Icons.school_outlined,
                                                          color:
                                                              Color(0xFFE87722),
                                                          size: 26)))
                                              : Container(
                                                  width: 56,
                                                  height: 56,
                                                  color: isDark
                                                      ? const Color(0xFF2A1A0A)
                                                      : const Color(0xFFF5E6D8),
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
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            const SizedBox(height: 6),
                                            Row(children: [
                                              const Icon(Icons.people_outline,
                                                  size: 12,
                                                  color: Color(0xFF7B3A10)),
                                              const SizedBox(width: 4),
                                              Text('$students wanafunzi',
                                                  style: GoogleFonts.montserrat(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: const Color(
                                                          0xFF7B3A10))),
                                              const SizedBox(width: 10),
                                              const Icon(Icons.star_rounded,
                                                  size: 12,
                                                  color: Color(0xFFFFA726)),
                                              const SizedBox(width: 3),
                                              Text(rating.toStringAsFixed(1),
                                                  style: GoogleFonts.montserrat(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: const Color(
                                                          0xFF7B3A10))),
                                            ]),
                                          ])),
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                  alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Text(statusLabel,
                                              style: GoogleFonts.montserrat(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: statusColor))),
                                    ]),
                                const SizedBox(height: 16),
                                Divider(
                                    height: 1,
                                    color: isDark
                                        ? Colors.white10
                                        : const Color(0xFFF5E6D8)),
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
                                            foregroundColor:
                                                const Color(0xFFE87722),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(28)),
                                            padding:
                                                const EdgeInsets.symmetric(vertical: 10)))),
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
                      fontSize: 20, fontWeight: FontWeight.w700, color: color)),
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
    final pending =
        _certs.where((c) => (c as Map)['is_approved'] != true).length;
    final approved =
        _certs.where((c) => (c as Map)['is_approved'] == true).length;

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
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.workspace_premium_outlined,
                    color: Color(0xFFE87722), size: 22),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Uthibitishaji wa Vyeti',
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3D1800))),
                      const SizedBox(height: 4),
                      Text(
                          'Kagua ukamilishaji wa mwanafunzi kisha '
                          'thibitisha ili apate cheti rasmi cha Karakana.',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF7B3A10),
                              height: 1.5)),
                    ])),
              ])),

          const SizedBox(height: 16),

          // ── SUMMARY STATS ROW ──
          Row(children: [
            _buildMiniStat('$pending', 'Zinasubiri', const Color(0xFFFFA726)),
            const SizedBox(width: 10),
            _buildMiniStat(
                '$approved', 'Zilizoidhinishwa', const Color(0xFFE87722)),
            const SizedBox(width: 10),
            _buildMiniStat('${_certs.length}', 'Zote', const Color(0xFF3D1800)),
          ]),

          const SizedBox(height: 24),

          Text('Maombi ya Vyeti',
              style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary)),

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
                      boxShadow: [
                        BoxShadow(
                            color:
                                const Color(0xFFE87722).withValues(alpha: 0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ]),
                  child: Column(children: [
                    // ── STUDENT INFO ──
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF3D1800),
                                            Color(0xFFE87722)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight),
                                      shape: BoxShape.circle),
                                  child: Center(
                                      child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'M',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(name,
                                        style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary)),
                                    const SizedBox(height: 3),
                                    Text(course,
                                        style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF7B3A10)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 5),
                                    Row(children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 11, color: Color(0xFFBDA99C)),
                                      const SizedBox(width: 4),
                                      Text(date,
                                          style: GoogleFonts.montserrat(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFFBDA99C))),
                                    ]),
                                  ])),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: isApproved
                                          ? const Color(0xFFE87722)
                                              .withValues(alpha: 0.1)
                                          : const Color(0xFFFFA726)
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(
                                      isApproved
                                          ? '✓ Imethibitishwa'
                                          : '⏳ Inasubiri',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isApproved
                                              ? const Color(0xFFE87722)
                                              : const Color(0xFFFFA726)))),
                            ])),

                    // ── PROGRESS BAR ──
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Ukamilishaji wa Kozi',
                                        style: GoogleFonts.montserrat(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF7B3A10))),
                                    Text('$progress%',
                                        style: GoogleFonts.montserrat(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFE87722))),
                                  ]),
                              const SizedBox(height: 6),
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                      value: progress / 100,
                                      backgroundColor: isDark
                                          ? const Color(0xFF2A1A0A)
                                          : const Color(0xFFF5E6D8),
                                      valueColor: const AlwaysStoppedAnimation(
                                          Color(0xFFE87722)),
                                      minHeight: 8)),
                            ])),

                    const SizedBox(height: 14),

                    // ── ACTION BUTTONS ──
                    Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: !isApproved
                            ? Row(children: [
                                Expanded(
                                    child: OutlinedButton(
                                        onPressed: () =>
                                            _showRejectConfirm(cert),
                                        style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: const Color(0xFF3D1800)
                                                    .withValues(alpha: 0.4)),
                                            foregroundColor:
                                                const Color(0xFF3D1800),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(28)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10)),
                                        child: Text('Kataa',
                                            style: GoogleFonts.montserrat(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700)))),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _showApproveConfirm(cert),
                                        icon: const Icon(
                                            Icons.workspace_premium_outlined,
                                            size: 15),
                                        label: Text('Thibitisha Cheti',
                                            style: GoogleFonts.montserrat(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700)),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFE87722),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFE87722)
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(28)),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Row(children: [
                  const Icon(Icons.workspace_premium_outlined,
                      color: Color(0xFFE87722)),
                  const SizedBox(width: 8),
                  Text('Thibitisha Cheti',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A0A00))),
                ]),
                content: Text(
                    'Unathibitisha kwamba ${_certStudentName(cert)} amekamilisha '
                    '"${_certCourseName(cert)}" kwa mafanikio na anastahili cheti rasmi?',
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
                  ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _approveCert(cert);
                      },
                      icon: const Icon(Icons.workspace_premium_outlined,
                          size: 16),
                      label: Text('Thibitisha',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE87722),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)))),
                ]));
  }

  void _showRejectConfirm(Map cert) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text('Kataa Ombi?',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A0A00))),
                content: Text(
                    'Ombi la cheti la ${_certStudentName(cert)} litakataliwa. '
                    'Mwanafunzi ataarifiwa.',
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
                        _rejectCertApi(cert);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D1800),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text('Ndiyo, Kataa',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700))),
                ]));
  }

  // ── HERO APP BAR ──────────────────────────────────────────────────────────

  Widget _buildHeroAppBar(BuildContext context, bool innerBoxIsScrolled) {
    final bool isAccountTab = _tabController.index == 4;
    final bool isCoursesTab = _tabController.index == 1;
    final bool isCertificatesTab = _tabController.index == 3;
    if (isAccountTab || isCoursesTab || isCertificatesTab) {
      final tabTitle = isAccountTab
          ? 'Akaunti'
          : isCertificatesTab
              ? 'Vyeti'
              : 'Maudhui';
      final tabSubtitle = isAccountTab
          ? 'Mipangilio ya akaunti'
          : isCertificatesTab
              ? 'Maombi ya uthibitishaji'
              : 'Kozi na vitabu vyako';
      return SliverAppBar(
        toolbarHeight: 56,
        expandedHeight: 148,
        pinned: true,
        floating: false,
        forceElevated: innerBoxIsScrolled,
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        backgroundColor: const Color(0xFF201008),

        // ── Collapsed state: consistent Karakana brand bar ──
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Image.asset(
                  'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text('K',
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE87722))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'Karakana',
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
          ]),
        ),
        actions: [
          _buildHeaderIconButton(
            Icons.notifications_outlined,
            () => context.push('/notifications'),
            veryCompact: false,
          ),
          const SizedBox(width: 6),
          _buildHeaderIconButton(
            Icons.settings_outlined,
            _openAccountTab,
            veryCompact: false,
          ),
          const SizedBox(width: 14),
        ],

        // ── Flexible space: gradient + large page title (fades on scroll) ──
        flexibleSpace: LayoutBuilder(builder: (ctx, constraints) {
          final h = constraints.maxHeight;
          final statusBarH = MediaQuery.of(ctx).padding.top;
          final baseH = statusBarH + 56.0;
          // Start fading when just 28px of extra space remains
          final titleOpacity = ((h - baseH - 4) / 26.0).clamp(0.0, 1.0);

          return Stack(fit: StackFit.expand, children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF201008),
                    Color(0xFF4B2412),
                    Color(0xFF9A4E1D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.48, 1.0],
                ),
              ),
            ),
            // Subtle warm glow bottom-right
            Positioned(
              right: -30,
              bottom: -20,
              child: _buildHeroGlow(
                  140, const Color(0xFFFFD1A1).withValues(alpha: 0.05)),
            ),
            // Large page title — fades away as bar collapses
            if (titleOpacity > 0.01)
              ClipRect(
                child: Opacity(
                  opacity: titleOpacity,
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    maxHeight: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, baseH + 10, 20, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tabTitle,
                            style: GoogleFonts.montserrat(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            tabSubtitle,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.50),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ]);
        }),
      );
    }
    // ── Main overview / students tab — industry-standard collapsing hero ──
    // The SliverAppBar's own title+actions are ALWAYS visible (no fading).
    // The flexibleSpace contains only greeting+name+tagline+stats, which fades
    // out smoothly as the user scrolls. No duplicate branding.
    return SliverAppBar(
      toolbarHeight: 56,
      expandedHeight: 268,
      pinned: true,
      floating: false,
      forceElevated: innerBoxIsScrolled,
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      backgroundColor: const Color(0xFF201008),

      // ── ALWAYS-VISIBLE top bar (logo + Karakana + actions) ──
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset(
                'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Text('K',
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE87722))),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'Karakana',
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.1,
            ),
          ),
        ]),
      ),
      actions: [
        _buildHeaderIconButton(
          Icons.notifications_outlined,
          () => context.push('/notifications'),
          veryCompact: false,
        ),
        const SizedBox(width: 6),
        _buildHeaderIconButton(
          Icons.settings_outlined,
          _openAccountTab,
          veryCompact: false,
        ),
        const SizedBox(width: 14),
      ],

      // ── FLEXIBLE SPACE: greeting+name+tagline+stats (fades on scroll) ──
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF201008), Color(0xFF4B2412), Color(0xFF9A4E1D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final h = constraints.maxHeight;
            // Starts fading at 190px, fully gone at 100px
            final heroOpacity =
                ((h - 100.0) / (190.0 - 100.0)).clamp(0.0, 1.0);

            return Stack(fit: StackFit.expand, children: [
              // Decorative glows
              Positioned(
                top: -36,
                left: -18,
                child: _buildHeroGlow(
                    130, Colors.white.withValues(alpha: 0.08)),
              ),
              Positioned(
                right: -36,
                bottom: -44,
                child: _buildHeroGlow(
                    170, const Color(0xFFFFD1A1).withValues(alpha: 0.06)),
              ),
              Positioned(
                right: 22,
                top: 76,
                child: Opacity(
                  opacity: 0.04,
                  child: Image.asset(
                    'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                    width: 110,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Greeting+name+tagline+stats — fades out cleanly
              if (heroOpacity > 0)
                ClipRect(
                  child: Opacity(
                    opacity: heroOpacity,
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: double.infinity,
                      child: Builder(builder: (ctx2) {
                        final statusBarH =
                            MediaQuery.of(ctx2).padding.top;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                              18, statusBarH + 56 + 8, 18, 0),
                          child: _buildHeroGreetingContent(),
                        );
                      }),
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _buildCollapsedDashboardChrome({
    required bool veryCompact,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: veryCompact ? 11 : 12,
            vertical: veryCompact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: veryCompact ? 28 : 30,
                height: veryCompact ? 28 : 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(
                    'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        'K',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: veryCompact ? 8 : 10),
              Text(
                'Karakana',
                style: GoogleFonts.montserrat(
                  fontSize: veryCompact ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              _buildHeaderIconButton(
                Icons.notifications_outlined,
                () => context.push('/notifications'),
                veryCompact: veryCompact,
              ),
              const SizedBox(width: 4),
              _buildHeaderIconButton(
                Icons.settings_outlined,
                _openAccountTab,
                veryCompact: veryCompact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeaderChrome({required String title}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(
                    'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        'K',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              _buildHeaderIconButton(
                Icons.notifications_outlined,
                () => context.push('/notifications'),
                veryCompact: false,
              ),
              const SizedBox(width: 4),
              _buildHeaderIconButton(
                Icons.settings_outlined,
                _openAccountTab,
                veryCompact: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardHero({
    required bool compact,
    bool dense = false,
    bool veryCompact = false,
    bool tight = false,
  }) {
    final firstName = _getFirstName(context.read<AuthProvider>());
    if (compact) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: veryCompact ? 12 : 14,
          vertical: veryCompact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A1106), Color(0xFF5C2208), Color(0xFFB5540A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.48, 1.0],
          ),
          borderRadius: BorderRadius.circular(veryCompact ? 22 : 26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3D1800).withValues(alpha: 0.16),
              blurRadius: veryCompact ? 12 : 18,
              offset: Offset(0, veryCompact ? 6 : 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: veryCompact ? 28 : 30,
              height: veryCompact ? 28 : 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Image.asset(
                  'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      'K',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: veryCompact ? 8 : 10),
            Text(
              'Karakana',
              style: GoogleFonts.montserrat(
                fontSize: veryCompact ? 15 : 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            Container(
              width: veryCompact ? 36 : 40,
              height: veryCompact ? 36 : 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(veryCompact ? 12 : 14),
              ),
              child: Icon(
                _getTimeIcon(),
                color: Colors.white,
                size: veryCompact ? 18 : 20,
              ),
            ),
          ],
        ),
      );
    }
    if (dense) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'Dashibodi ya Mkufunzi',
                  style: GoogleFonts.montserrat(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              _buildHeaderIconButton(
                Icons.notifications_outlined,
                () => context.push('/notifications'),
                veryCompact: false,
              ),
              const SizedBox(width: 4),
              _buildHeaderIconButton(
                Icons.settings_outlined,
                _openAccountTab,
                veryCompact: false,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_getGreeting()}, $firstName',
            style: GoogleFonts.montserrat(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Endelea kusukuma mafanikio yako leo',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.0,
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── TOP BAR: logo + branding + action buttons ──
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Image.asset(
                  'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      'K',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE87722),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'Karakana',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
            const Spacer(),
            _buildHeaderIconButton(
              Icons.notifications_outlined,
              () => context.push('/notifications'),
              veryCompact: false,
            ),
            const SizedBox(width: 8),
            _buildHeaderIconButton(
              Icons.settings_outlined,
              _openAccountTab,
              veryCompact: false,
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ── GREETING + NAME + TAGLINE ──
        Row(
          children: [
            Icon(
              _getTimeIcon(),
              size: 13,
              color: Colors.white.withValues(alpha: 0.50),
            ),
            const SizedBox(width: 6),
            Text(
              _getGreeting(),
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.55),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          firstName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.05,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _getTagline(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.42),
            letterSpacing: 0.1,
          ),
        ),

        const SizedBox(height: 16),

        // ── STATS RAIL ──
        _buildHeroSummaryRail(compact: false),
      ],
    );
  }

  Widget _buildHeaderIconButton(
    IconData icon,
    VoidCallback onTap, {
    required bool veryCompact,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: veryCompact ? 32 : 38,
          height: veryCompact ? 32 : 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: veryCompact ? 18 : 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── HERO GREETING: greeting + name + tagline + stats rail ────────────────
  // Used inside the fading flexible space — no logo row here.
  Widget _buildHeroGreetingContent() {
    final firstName = _getFirstName(context.read<AuthProvider>());
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(_getTimeIcon(),
              size: 13, color: Colors.white.withValues(alpha: 0.50)),
          const SizedBox(width: 6),
          Text(
            _getGreeting(),
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 0.2,
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          firstName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.05,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _getTagline(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.42),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 16),
        _buildHeroSummaryRail(compact: false),
      ],
    );
  }

  Widget _buildHeroSummaryRail({required bool compact}) {
    final avgRating =
        (_stats['avg_rating'] as double? ?? 0.0).toStringAsFixed(1);
    final borderRadius = compact ? 16.0 : 20.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: compact ? 14 : 18, sigmaY: compact ? 14 : 18),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 9 : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: compact ? 0.11 : 0.13),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: compact ? 0.16 : 0.20),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: compact ? 0.08 : 0.14),
                blurRadius: compact ? 14 : 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildHeroSummaryItem(
                  'Kozi',
                  '${_stats['total_courses'] ?? 0}',
                  compact: compact,
                ),
              ),
              _buildHeroSummaryDivider(compact: compact),
              Expanded(
                child: _buildHeroSummaryItem(
                  'Vitabu',
                  '${_stats['total_ebooks'] ?? 0}',
                  compact: compact,
                ),
              ),
              _buildHeroSummaryDivider(compact: compact),
              Expanded(
                child: _buildHeroSummaryItem(
                  'Wanafunzi',
                  '${_stats['total_students'] ?? 0}',
                  compact: compact,
                ),
              ),
              _buildHeroSummaryDivider(compact: compact),
              Expanded(
                child: _buildHeroSummaryItem(
                  'Ukadiriaji',
                  avgRating,
                  compact: compact,
                  isStar: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSummaryItem(
    String label,
    String value, {
    required bool compact,
    bool isStar = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Value row — for rating, inline star icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (isStar && !compact) ...[
              Icon(Icons.star_rounded,
                  size: 13,
                  color: const Color(0xFFFFD569).withValues(alpha: 0.9)),
              const SizedBox(width: 2),
            ],
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: compact ? 13 : 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: compact ? 7.5 : 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: compact ? 0.72 : 0.75),
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSummaryDivider({bool compact = false}) {
    return Container(
      width: 1,
      height: compact ? 26 : 34,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _ebookStatChip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: const Color(0xFF7B3A10)),
      const SizedBox(width: 3),
      Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF7B3A10),
        ),
      ),
    ]);
  }

  // ── EBOOK OVERVIEW CARD (home tab preview) ────────────────────────────────

  Widget _buildEbookOverviewCard(
      Map e, Color surfaceColor, Color textPrimary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = (e['title'] ?? '').toString();
    final cover = e['cover_image']?.toString();
    final buyers = e['buyers_count'] as int? ?? 0;
    final purchases = e['successful_purchases_count'] as int? ?? 0;
    final revenue =
        double.tryParse((e['total_revenue'] ?? '0').toString()) ?? 0.0;
    final price = (double.tryParse((e['price'] ?? '0').toString()) ?? 0).toInt();
    final status = (e['status'] as String? ?? 'draft');
    final statusColor = status == 'published'
        ? const Color(0xFF2E7D32)
        : status == 'pending_review'
            ? const Color(0xFFE87722)
            : const Color(0xFF6B7280);
    final statusLabel = status == 'published'
        ? 'Imechapishwa'
        : status == 'pending_review'
            ? 'Inasubiri'
            : 'Rasimu';
    final ebookId = e['id'] as int? ?? 0;

    return GestureDetector(
      onTap: () async {
        await context.push('/trainer/ebooks/$ebookId');
        await _loadAll();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE87722).withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 54,
              height: 72,
              color: isDark
                  ? const Color(0xFF2A1A0A)
                  : const Color(0xFFF5E6D8),
              child: cover != null && cover.isNotEmpty
                  ? Image.network(cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.menu_book_outlined,
                          color: Color(0xFFE87722),
                          size: 24))
                  : const Icon(Icons.menu_book_outlined,
                      color: Color(0xFFE87722), size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  'TZS ${_formatPrice(price)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE87722),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$buyers wasomaji  •  $purchases mauzo  •  TZS ${_formatPrice(revenue)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7B3A10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFE87722), size: 20),
        ]),
      ),
    );
  }

  Widget _buildHeroGlow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
