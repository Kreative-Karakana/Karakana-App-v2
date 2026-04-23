import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_client.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final res =
          await ApiClient().dio.get('/api/v1/courses/?enrolled=true&page_size=50');
      final data = res.data;
      final results =
          data is Map ? (data['results'] as List? ?? []) : (data as List? ?? []);
      if (!mounted) return;
      setState(() {
        _courses = results;
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
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B1A08),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Kozi Zangu',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC4620A)),
            )
          : _courses.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _courses.length,
                  itemBuilder: (_, i) {
                    final course = _courses[i] as Map;
                    final title = course['title'] as String? ?? '';
                    final coverPhoto = course['cover_photo'] as String?;
                    final courseId = course['id'] as int? ?? 0;
                    final trainer = course['trainer'] as Map?;
                    final trainerName = trainer != null
                        ? '${trainer['first_name'] ?? ''} ${trainer['last_name'] ?? ''}'
                            .trim()
                        : '';

                    return GestureDetector(
                      onTap: () => context.push('/course/$courseId/classroom'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                              child: coverPhoto != null
                                  ? CachedNetworkImage(
                                      imageUrl: coverPhoto,
                                      width: 100,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => _coverFallback(),
                                    )
                                  : _coverFallback(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
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
                                        color: const Color(0xFF3B1A08),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      trainerName,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: const Color(0xFF9E8070),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2E7D32),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Imeandikishwa',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Color(0xFFE8D5C8),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFF5E6D8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 48,
              color: Color(0xFFC4620A),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hujajiunga Kozi Yoyote',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A0A00),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tafuta kozi na uanze kujifunza.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF9E8070),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC4620A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: Text(
              'Tafuta Kozi',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      width: 100,
      height: 90,
      color: const Color(0xFFF5E6D8),
      child: const Icon(
        Icons.play_circle_outline,
        color: Color(0xFFC4620A),
        size: 32,
      ),
    );
  }
}
