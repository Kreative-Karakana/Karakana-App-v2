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
  // ignore: unused_field
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

  // ignore: unused_element
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
                      Center(
                          child: Text('Muhtasari - inajengwa',
                              style: GoogleFonts.montserrat())),
                      Center(
                          child: Text('Kozi - inajengwa',
                              style: GoogleFonts.montserrat())),
                      Center(
                          child: Text('Wanafunzi - inajengwa',
                              style: GoogleFonts.montserrat())),
                      Center(
                          child: Text('Vyeti - inajengwa',
                              style: GoogleFonts.montserrat())),
                    ])));
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
