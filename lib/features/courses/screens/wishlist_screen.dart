import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_client.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final res = await ApiClient().dio.get('/api/v1/wishlist/');
      final data = res.data;
      final results = data is Map
          ? (data['results'] as List? ?? [])
          : (data as List? ?? []);
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

  Future<void> _removeFromWishlist(int courseId) async {
    try {
      await ApiClient()
          .dio
          .post('/api/v1/wishlist/', data: {'course_id': courseId});
      if (!mounted) return;
      setState(() {
        _courses.removeWhere((c) => (c as Map)['id'] == courseId);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Vipendwa Vyangu',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: KarakanaWaveLoader(color: Color(0xFFE87722)),
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
                          onTap: () => context.push('/course/$courseId'),
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
                                          errorWidget: (_, __, ___) =>
                                              _coverFallback(),
                                        )
                                      : _coverFallback(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3D1800),
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
                                            Expanded(
                                              child: Text(
                                                'Fungua maelezo ya kozi',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 11,
                                                  color:
                                                      const Color(0xFFBDA99C),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _removeFromWishlist(courseId),
                                              icon: const Icon(
                                                Icons.bookmark_remove,
                                                color: Color(0xFFE87722),
                                                size: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        );
                      },
                    )),
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
              Icons.bookmark_border_rounded,
              size: 48,
              color: Color(0xFFE87722),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hujaweka Kozi Yoyote Kwenye Vipendwa',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A0A00),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tafuta kozi nzuri na uziweke hapa.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF9E8070),
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
        Icons.bookmark_border,
        color: Color(0xFFE87722),
        size: 32,
      ),
    );
  }
}
