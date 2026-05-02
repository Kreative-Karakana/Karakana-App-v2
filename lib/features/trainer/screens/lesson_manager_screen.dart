import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../widgets/common/top_popup.dart';

class LessonManagerScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const LessonManagerScreen({
    super.key,
    required this.courseId,
    this.courseTitle = 'Kozi',
  });

  @override
  State<LessonManagerScreen> createState() => _LessonManagerScreenState();
}

class _LessonManagerScreenState extends State<LessonManagerScreen> {
  List _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.get(
          '/api/v1/courses/${widget.courseId}/sections/');
      final data = res.data;
      final sections = data is Map
          ? (data['results'] as List? ?? [])
          : (data as List? ?? []);
      if (!mounted) return;
      setState(() {
        _sections = sections;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddSectionSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE8D5C8),
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text('Ongeza Sehemu',
                  style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D1800))),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Jina la Sehemu *',
                  hintText: 'Mfano: Utangulizi, Sehemu ya 1',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8D5C8))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFE87722), width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE87722),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28))),
                  onPressed: () async {
                    if (ctrl.text.trim().isEmpty) return;
                    final nav = Navigator.of(ctx);
                    try {
                      try {
                        await ApiClient().dio.post(
                            '/api/v1/courses/${widget.courseId}/sections/',
                            data: {
                              'title': ctrl.text.trim(),
                              'order': _sections.length + 1,
                            });
                      } on DioException catch (e) {
                        // Some environments expose course-sections as read-only.
                        if (e.response?.statusCode == 405) {
                          await ApiClient().dio.post('/api/v1/sections/', data: {
                            'course': widget.courseId,
                            'title': ctrl.text.trim(),
                            'order': _sections.length + 1,
                          });
                        } else {
                          rethrow;
                        }
                      }
                      if (!mounted) return;
                      nav.pop();
                      _loadSections();
                    } catch (e) {
                      if (!mounted) return;
                      showTopPopup(context, ApiClient().parseError(e));
                    }
                  },
                  child: Text('Hifadhi Sehemu',
                      style: GoogleFonts.montserrat(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLessonSheet(Map section) {
    final titleCtrl = TextEditingController();
    final muxCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final sectionId = section['id'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE8D5C8),
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text('Ongeza Somo',
                  style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D1800))),
              const SizedBox(height: 4),
              Text('Katika: ${section['title'] ?? ''}',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: const Color(0xFF9E8070))),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Jina la Somo *',
                  hintText: 'Mfano: Somo la 1 - Utangulizi',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8D5C8))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFE87722), width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: muxCtrl,
                decoration: InputDecoration(
                  labelText: 'Mux Playback ID (hiari)',
                  hintText: 'Mfano: abc123xyz',
                  prefixIcon: const Icon(Icons.play_circle_outline,
                      color: Color(0xFFE87722)),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8D5C8))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFE87722), width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Muda (dakika, hiari)',
                  hintText: 'Mfano: 15',
                  prefixIcon: const Icon(Icons.timer_outlined,
                      color: Color(0xFFE87722)),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8D5C8))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFE87722), width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE87722),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28))),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final nav = Navigator.of(ctx);
                    try {
                      final body = <String, dynamic>{
                        'title': titleCtrl.text.trim(),
                        if (muxCtrl.text.trim().isNotEmpty)
                          'mux_playback_id': muxCtrl.text.trim(),
                        if (durationCtrl.text.trim().isNotEmpty)
                          'duration': int.tryParse(durationCtrl.text.trim()),
                      };
                      await ApiClient().dio.post(
                          '/api/v1/sections/$sectionId/lessons/', data: body);
                      if (!mounted) return;
                      nav.pop();
                      _loadSections();
                    } catch (e) {
                      if (!mounted) return;
                      showTopPopup(context, ApiClient().parseError(e));
                    }
                  },
                  child: Text('Hifadhi Somo',
                      style: GoogleFonts.montserrat(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSection(Map section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Futa Sehemu?',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A0A00))),
        content: Text(
            'Sehemu "${section['title']}" itafutwa pamoja na masomo yake yote.',
            style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF7B3A10),
                height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hapana',
                  style: GoogleFonts.montserrat(
                      color: const Color(0xFF7B3A10)))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D1800),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('Futa',
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient().dio.delete('/api/v1/sections/${section['id']}/');
      _loadSections();
    } catch (_) {
      if (!mounted) return;
      showTopPopup(context, 'Hitilafu. Jaribu tena.');
    }
  }

  Future<void> _deleteLesson(Map lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Futa Somo?',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A0A00))),
        content: Text('Somo "${lesson['title']}" litafutwa kabisa.',
            style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF7B3A10),
                height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hapana',
                  style: GoogleFonts.montserrat(
                      color: const Color(0xFF7B3A10)))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D1800),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('Futa',
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient().dio.delete('/api/v1/lessons/${lesson['id']}/');
      _loadSections();
    } catch (_) {
      if (!mounted) return;
      showTopPopup(context, 'Hitilafu. Jaribu tena.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sehemu na Masomo',
                style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            Text(widget.courseTitle,
                style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSectionSheet,
        backgroundColor: const Color(0xFFE87722),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Ongeza Sehemu',
            style:
                GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE87722)))
          : RefreshIndicator(
              color: const Color(0xFFE87722),
              onRefresh: _loadSections,
              child: _sections.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      itemCount: _sections.length,
                      itemBuilder: (_, i) =>
                          _buildSectionCard(_sections[i] as Map, i),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8), shape: BoxShape.circle),
            child: const Icon(Icons.view_agenda_outlined,
                size: 44, color: Color(0xFFE87722)),
          ),
          const SizedBox(height: 20),
          Text(
              'Hakuna sehemu bado.\nBonyeza + kuongeza sehemu ya kwanza!',
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7B3A10),
                  height: 1.5),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Map section, int idx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = section['title'] as String? ?? 'Sehemu ${idx + 1}';
    final lessons = (section['lessons'] as List? ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFE87722).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                    color: Color(0xFF3D1800), shape: BoxShape.circle),
                child: Center(
                    child: Text('${idx + 1}',
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white))),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(title,
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1A0A00)))),
              Text('${lessons.length} masomo',
                  style: GoogleFonts.montserrat(
                      fontSize: 11, color: const Color(0xFF9E8070))),
              const SizedBox(width: 8),
              GestureDetector(
                  onTap: () => _deleteSection(section),
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: Color(0xFF9E8070))),
            ]),
          ),

          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF5E6D8)),

          // Lessons list
          if (lessons.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                  'Hakuna masomo. Bonyeza + kuongeza somo.',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: const Color(0xFF9E8070))),
            )
          else
            ...lessons.asMap().entries.map((e) =>
                _buildLessonRow(e.value as Map, e.key)),

          // Add lesson button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: OutlinedButton.icon(
              onPressed: () => _showAddLessonSheet(section),
              icon: const Icon(Icons.add, size: 15),
              label: Text('Ongeza Somo',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: const Color(0xFFE87722).withValues(alpha: 0.5)),
                  foregroundColor: const Color(0xFFE87722),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  padding: const EdgeInsets.symmetric(vertical: 8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonRow(Map lesson, int idx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = lesson['title'] as String? ?? 'Somo ${idx + 1}';
    final hasMux =
        (lesson['mux_playback_id'] as String? ?? '').isNotEmpty;
    final duration = lesson['duration'] as int?;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF5E6D8)))),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: hasMux
                  ? (isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8))
                  : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0EFEF)),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(
              hasMux
                  ? Icons.play_circle_outline
                  : Icons.article_outlined,
              size: 17,
              color: hasMux
                  ? const Color(0xFFE87722)
                  : const Color(0xFF9E8070)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1A0A00))),
                if (duration != null)
                  Text('$duration dak',
                      style: GoogleFonts.montserrat(
                          fontSize: 10,
                          color: const Color(0xFF9E8070))),
              ]),
        ),
        GestureDetector(
            onTap: () => _deleteLesson(lesson),
            child: const Icon(Icons.delete_outline,
                size: 16, color: Color(0xFFBDA99C))),
      ]),
    );
  }
}
