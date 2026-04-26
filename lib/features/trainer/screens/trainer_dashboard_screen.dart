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
  late final TabController _tabController;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _certificates = [];
  bool _isLoading = true;
  bool _isTogglingPublish = false;
  Map<String, dynamic> _stats = {
    'total_courses': 0,
    'total_students': 0,
    'avg_rating': 0.0,
    'total_views': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final coursesRes = await ApiClient().dio.get(
            '/api/v1/courses/?is_creator=true&page_size=50',
          );
      final rawData = coursesRes.data;
      final rawList = rawData is Map
          ? (rawData['results'] as List? ?? const [])
          : (rawData as List? ?? const []);
      final courses = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final totalStudents = courses.fold<int>(
        0,
        (s, c) => s + ((c['student_count'] as int?) ?? 0),
      );
      final avgRating = courses.isEmpty
          ? 0.0
          : courses.fold<double>(
                0,
                (s, c) =>
                    s + ((c['average_rating'] as num?)?.toDouble() ?? 0.0),
              ) /
              courses.length;

      List<Map<String, dynamic>> students = [];
      List<Map<String, dynamic>> certs = [];
      try {
        final studRes = await ApiClient().dio.get(
              '/api/v1/enrollments/?trainer=true&page_size=50',
            );
        final studData = studRes.data;
        final studList = studData is Map
            ? (studData['results'] as List? ?? const [])
            : (studData as List? ?? const []);
        students =
            studList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}

      try {
        final certRes = await ApiClient().dio.get(
              '/api/v1/certificates/?trainer=true&page_size=50',
            );
        final certData = certRes.data;
        final certList = certData is Map
            ? (certData['results'] as List? ?? const [])
            : (certData as List? ?? const []);
        certs = certList
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _courses = courses;
        _students = students;
        _certificates = certs;
        _stats = {
          'total_courses': courses.length,
          'total_students': totalStudents,
          'avg_rating': avgRating,
          'total_views': 0,
        };
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePublish(Map<String, dynamic> course) async {
    final courseId = course['id'];
    final isPublished = (course['status'] as String? ?? 'draft') == 'published';
    final newStatus = isPublished ? 'draft' : 'published';

    setState(() => _isTogglingPublish = true);
    try {
      await ApiClient().dio.patch(
        '/api/v1/courses/$courseId/',
        data: {'status': newStatus},
      );
      final idx = _courses.indexWhere((c) => c['id'] == courseId);
      if (idx != -1 && mounted) {
        setState(() {
          _courses[idx]['status'] = newStatus;
          _isTogglingPublish = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTogglingPublish = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient().parseError(e)),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  Future<void> _approveCertificate(Map<String, dynamic> cert) async {
    final certId = cert['id'];
    try {
      await ApiClient().dio.patch(
        '/api/v1/certificates/$certId/',
        data: {'is_approved': true},
      );
      final idx = _certificates.indexWhere((c) => c['id'] == certId);
      if (idx != -1 && mounted) {
        setState(() {
          _certificates[idx]['is_approved'] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cheti kimeidhinishwa!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient().parseError(e)),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF3D1800),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_outlined,
                    color: Colors.white, size: 22),
                onPressed: _loadDashboard,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: Colors.white, size: 26),
                tooltip: 'Unda Kozi',
                onPressed: () => context.push('/trainer/course-builder'),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Dashibodi ya Mwalimu',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: _buildHeader(),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelStyle: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 12),
                labelColor: const Color(0xFFE87722),
                unselectedLabelColor: const Color(0xFF9E8070),
                indicatorColor: const Color(0xFFE87722),
                indicatorWeight: 2.5,
                tabs: const [
                  Tab(text: 'Muhtasari'),
                  Tab(text: 'Kozi'),
                  Tab(text: 'Wanafunzi'),
                  Tab(text: 'Vyeti'),
                ],
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE87722)),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildCoursesTab(),
                  _buildStudentsTab(),
                  _buildCertificatesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A00), Color(0xFF3D1800), Color(0xFF7B3A10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<AuthProvider>(
                builder: (_, auth, __) => Text(
                  'Karibu, ${auth.userFullName}! 👋',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildQuickStat(
                    '${_stats['total_courses']}',
                    'Kozi',
                    Icons.school_outlined,
                  ),
                  const SizedBox(width: 24),
                  _buildQuickStat(
                    '${_stats['total_students']}',
                    'Wanafunzi',
                    Icons.people_outlined,
                  ),
                  const SizedBox(width: 24),
                  _buildQuickStat(
                    (_stats['avg_rating'] as double).toStringAsFixed(1),
                    'Ukadiriaji',
                    Icons.star_outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // ─── OVERVIEW TAB ────────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final published =
        _courses.where((c) => c['status'] == 'published').length;
    final drafts = _courses.length - published;
    final pending =
        _certificates.where((c) => c['is_approved'] != true).length;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: const Color(0xFFE87722),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Zilizochapishwa',
                  '$published',
                  Icons.public_outlined,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rasimu',
                  '$drafts',
                  Icons.edit_note_outlined,
                  const Color(0xFF7B3A10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Wanafunzi',
                  '${_stats['total_students']}',
                  Icons.people_outlined,
                  const Color(0xFF3D1800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Vyeti Vinavyosubiri',
                  '$pending',
                  Icons.workspace_premium_outlined,
                  const Color(0xFFE87722),
                ),
              ),
            ],
          ),
          if (_courses.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Kozi za Hivi Karibuni',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A0A00),
              ),
            ),
            const SizedBox(height: 12),
            ..._courses.take(3).map((c) => _buildCourseCard(c)),
          ],
          if (pending > 0) ...[
            const SizedBox(height: 24),
            Text(
              'Vyeti Vinavyosubiri Idhini',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A0A00),
              ),
            ),
            const SizedBox(height: 12),
            ..._certificates
                .where((c) => c['is_approved'] != true)
                .take(3)
                .map((c) => _buildCertificateCard(c)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FC4620A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D1800),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: const Color(0xFF9E8070),
            ),
          ),
        ],
      ),
    );
  }

  // ─── COURSES TAB ─────────────────────────────────────────────────────────────

  Widget _buildCoursesTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: const Color(0xFFE87722),
      child: _courses.isEmpty
          ? _buildEmptyState(
              icon: Icons.school_outlined,
              title: 'Huna Kozi Bado',
              subtitle: 'Unda kozi yako ya kwanza leo!',
              actionLabel: 'Unda Kozi',
              onAction: () => context.push('/trainer/course-builder'),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
              itemCount: _courses.length,
              itemBuilder: (_, i) => _buildCourseCard(_courses[i]),
            ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final title = course['title'] as String? ?? 'Kozi';
    final status = course['status'] as String? ?? 'draft';
    final isPublished = status == 'published';
    final studentCount = course['student_count'] as int? ?? 0;
    final rating = (course['average_rating'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FC4620A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3D1800), Color(0xFF7B3A10)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.play_circle_outline,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A0A00),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _metaChip(
                              Icons.people_outline, '$studentCount wanafunzi'),
                          const SizedBox(width: 10),
                          _metaChip(Icons.star_outline,
                              rating.toStringAsFixed(1)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(isPublished),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0E4DA)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.edit_outlined,
                    label: 'Hariri',
                    onTap: () =>
                        context.push('/trainer/course-builder'),
                    outlined: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    icon: isPublished
                        ? Icons.unpublished_outlined
                        : Icons.publish_outlined,
                    label: isPublished ? 'Futa Kuchapisha' : 'Chapisha',
                    onTap: _isTogglingPublish
                        ? null
                        : () => _togglePublish(course),
                    outlined: false,
                    color: isPublished
                        ? const Color(0xFF9E8070)
                        : const Color(0xFFE87722),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool isPublished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPublished
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE87722),
        ),
      ),
      child: Text(
        isPublished ? 'Imechapishwa' : 'Rasimu',
        style: GoogleFonts.montserrat(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isPublished
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE87722),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool outlined,
    Color color = const Color(0xFFE87722),
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF9E8070),
          side: const BorderSide(color: Color(0xFFE8D5C8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 8),
        elevation: 0,
      ),
    );
  }

  // ─── STUDENTS TAB ────────────────────────────────────────────────────────────

  Widget _buildStudentsTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: const Color(0xFFE87722),
      child: _students.isEmpty
          ? _buildEmptyState(
              icon: Icons.people_outline,
              title: 'Bado Hakuna Wanafunzi',
              subtitle: 'Wanafunzi watajiunga baada ya kozi kuchapishwa.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
              itemCount: _students.length,
              itemBuilder: (_, i) => _buildStudentCard(_students[i]),
            ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> enrollment) {
    final user = enrollment['user'] as Map? ?? {};
    final fullName =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final displayName = fullName.isEmpty ? 'Mwanafunzi' : fullName;
    final course = enrollment['course'] as Map? ?? {};
    final courseTitle = course['title'] as String? ?? 'Kozi';
    final progress = (enrollment['progress'] as num?)?.toDouble() ?? 0;
    final completedAt = enrollment['completed_at'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF5E6D8),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7B3A10),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A0A00),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  courseTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF9E8070),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFF0E4DA),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFE87722)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${progress.toStringAsFixed(0)}% imekamilika',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF9E8070),
                  ),
                ),
              ],
            ),
          ),
          if (completedAt != null)
            const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
        ],
      ),
    );
  }

  // ─── CERTIFICATES TAB ────────────────────────────────────────────────────────

  Widget _buildCertificatesTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: const Color(0xFFE87722),
      child: _certificates.isEmpty
          ? _buildEmptyState(
              icon: Icons.workspace_premium_outlined,
              title: 'Hakuna Vyeti',
              subtitle: 'Vyeti vya wanafunzi vitaonekana hapa.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
              itemCount: _certificates.length,
              itemBuilder: (_, i) => _buildCertificateCard(_certificates[i]),
            ),
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> cert) {
    final user = cert['user'] as Map? ?? {};
    final fullName =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final displayName = fullName.isEmpty ? 'Mwanafunzi' : fullName;
    final course = cert['course'] as Map? ?? {};
    final courseTitle = course['title'] as String? ?? 'Kozi';
    final isApproved = cert['is_approved'] == true;
    final issuedAt = cert['issued_at'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isApproved
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFFFF3E0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FC4620A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isApproved
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: isApproved
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE87722),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A0A00),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        courseTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF9E8070),
                        ),
                      ),
                      if (issuedAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          issuedAt.split('T').first,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFFBDA99C),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _certStatusBadge(isApproved),
              ],
            ),
          ),
          if (!isApproved) ...[
            const Divider(height: 1, color: Color(0xFFF0E4DA)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _approveCertificate(cert),
                  icon: const Icon(Icons.verified_outlined, size: 16),
                  label: Text(
                    'Idhinisha Cheti',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _certStatusBadge(bool isApproved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isApproved
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isApproved
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE87722),
        ),
      ),
      child: Text(
        isApproved ? 'Imeidhinishwa' : 'Inasubiri',
        style: GoogleFonts.montserrat(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isApproved
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE87722),
        ),
      ),
    );
  }

  // ─── SHARED HELPERS ──────────────────────────────────────────────────────────

  Widget _metaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9E8070)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF9E8070),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: const Color(0xFFE8D5C8)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D1800),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9E8070),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE87722),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── TAB BAR DELEGATE ────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
