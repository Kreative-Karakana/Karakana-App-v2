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

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;
  int _totalStudents = 0;
  double _avgRating = 0;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final res = await ApiClient().dio.get('/api/v1/courses/?is_creator=true&page_size=50');
      final data = res.data;
      final rawList = data is Map
          ? (data['results'] as List? ?? const [])
          : (data as List? ?? const []);
      final courses = rawList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final totalStudents = courses.fold<int>(
        0,
        (sum, course) => sum + ((course['student_count'] as int?) ?? 0),
      );
      final avgRating = courses.isEmpty
          ? 0.0
          : courses.fold<double>(
                  0,
                  (sum, course) =>
                      sum + ((course['average_rating'] as num?)?.toDouble() ?? 0),
                ) /
              courses.length;
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _totalStudents = totalStudents;
        _avgRating = avgRating;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF3D1800),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'Mkoba',
                onPressed: () => context.push('/wallet'),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () => context.push('/trainer/course-builder'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Dashibodi',
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF3D1800),
                      Color(0xFF7B3A10),
                      Color(0xFFE87722),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashibodi ya Mwalimu',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Consumer<AuthProvider>(
                          builder: (_, auth, __) => Text(
                            'Habari, ${auth.userFullName}! 👋',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildQuickStat(
                              '${_courses.length}',
                              'Kozi',
                              Icons.school_outlined,
                            ),
                            const SizedBox(width: 20),
                            _buildQuickStat(
                              '$_totalStudents',
                              'Wanafunzi',
                              Icons.people_outlined,
                            ),
                            const SizedBox(width: 20),
                            _buildQuickStat(
                              _avgRating.toStringAsFixed(1),
                              'Ukadiriaji',
                              Icons.star_outline,
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Maoni ya Jumla',
                      '0',
                      Icons.visibility_outlined,
                      const Color(0xFF3D1800),
                      '+0%',
                      true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Wasomi Wapya',
                      '0',
                      Icons.person_add_outlined,
                      const Color(0xFF3D1800),
                      '+0%',
                      true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Ukamilishaji',
                      '0%',
                      Icons.check_circle_outline,
                      const Color(0xFFE87722),
                      '0% ya wanafunzi',
                      true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Ukadiriaji',
                      _avgRating.toStringAsFixed(1),
                      Icons.star_outline,
                      const Color(0xFFE87722),
                      '0 tathmini',
                      true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kozi Zangu',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A0A00),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/trainer/course-builder'),
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                      color: Color(0xFFE87722),
                    ),
                    label: Text(
                      'Ongeza',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE87722),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE87722)),
                ),
              ),
            )
          else if (_courses.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: Color(0xFFE8D5C8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Huna Kozi Bado',
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D1800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unda kozi yako ya kwanza leo!',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: const Color(0xFF9E8070),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.push('/trainer/course-builder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE87722),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Unda Kozi',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildCourseCard(_courses[i]),
                  childCount: _courses.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
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
            fontSize: 18,
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
    bool trendUp,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: trendUp
                      ? const Color(0xFFF5E6D8)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: trendUp
                        ? const Color(0xFFE87722)
                        : const Color(0xFFB71C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D1800),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF9E8070),
            ),
          ),
        ],
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D1800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPublished
                      ? const Color(0xFFF5E6D8)
                      : const Color(0xFFFFF8F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPublished
                        ? const Color(0xFFE87722)
                        : const Color(0xFFE87722),
                  ),
                ),
                child: Text(
                  isPublished ? 'Imechapishwa' : 'Draft',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPublished
                        ? const Color(0xFFE87722)
                        : const Color(0xFFE87722),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _courseMeta(Icons.people_outline, '$studentCount wanafunzi'),
              const SizedBox(width: 16),
              _courseMeta(Icons.star_outline, rating.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/trainer/students?courseId=${course['id']}'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE8D5C8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Wanafunzi',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9E8070),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/trainer/course-builder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE87722),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Hariri',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _courseMeta(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9E8070)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: const Color(0xFF9E8070),
          ),
        ),
      ],
    );
  }
}
