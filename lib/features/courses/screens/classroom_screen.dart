import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/course_provider.dart';

class ClassroomScreen extends StatefulWidget {
  final int courseId;

  const ClassroomScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  final Set<int> _expandedSections = {0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourseDetail(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (provider.isLoadingDetail) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: const _ClassroomAppBarPlaceholder(),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE87722),
              ),
            ),
          );
        }

        final course = provider.selectedCourse;
        final sections = provider.sections;
        final totalLessons =
            sections.fold<int>(0, (sum, s) => sum + s.lessons.length);
        final completedLessons = sections.fold<int>(
          0,
          (sum, s) => sum + s.lessons.where((l) => l.isRead).length,
        );
        final progress =
            totalLessons > 0 ? completedLessons / totalLessons : 0.0;
        final summaryText = _buildCourseSummaryText(
          course?.description ?? '',
          course?.excerpt ?? '',
        );

        if (course == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: const Color(0xFF3D1800),
              leading: const BackButton(color: Colors.white),
              title: Text(
                'Darasani',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Color(0xFFE87722),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      provider.errorMessage ?? 'Hatukuweza kufungua darasa hili.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: const Color(0xFF5C3D2E),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => provider.loadCourseDetail(widget.courseId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE87722),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Jaribu tena',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: const Color(0xFF3D1800),
            leading: const BackButton(color: Colors.white),
            title: Text(
              course.title.isNotEmpty ? course.title : 'Darasani',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFE87722)),
                minHeight: 4,
              ),
            ),
          ),
          body: Column(
            children: [
              Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 5,
                            backgroundColor: const Color(0xFFF5E6D8),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFFE87722),
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE87722),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Maendeleo Yako',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: const Color(0xFF9E8070),
                            ),
                          ),
                          Text(
                            '$completedLessons / $totalLessons Masomo',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3D1800),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            progress >= 1.0
                                ? 'Kozi imekamilika!'
                                : 'Endelea vizuri!',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: progress >= 1.0
                                  ? const Color(0xFFE87722)
                                  : const Color(0xFF9E8070),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (progress >= 1.0)
                      OutlinedButton(
                        onPressed: () =>
                            context.push(
                              '/course/${widget.courseId}/complete',
                              extra: {'courseTitle': course.title},
                            ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE87722)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Cheti',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE87722),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.white10 : const Color(0xFFF0E4DA),
              ),
              if (summaryText.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFFE87722),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Muhtasari wa Kozi',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3D1800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 210),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            summaryText,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              height: 1.45,
                              color: const Color(0xFF5C3D2E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (summaryText.isNotEmpty)
                Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : const Color(0xFFF0E4DA),
                ),
              Expanded(
                child: sections.isEmpty
                    ? _EmptyClassroomState(
                        sectionsErrorMessage: provider.sectionsErrorMessage,
                        onRetry: () => provider.loadCourseDetail(widget.courseId),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: sections.length,
                        itemBuilder: (context, sectionIndex) {
                          final section = sections[sectionIndex];
                          final isExpanded =
                              _expandedSections.contains(sectionIndex);
                          final completedInSection =
                              section.lessons.where((l) => l.isRead).length;

                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() {
                                  if (isExpanded) {
                                    _expandedSections.remove(sectionIndex);
                                  } else {
                                    _expandedSections.add(sectionIndex);
                                  }
                                }),
                                child: Container(
                                  color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE87722),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${sectionIndex + 1}',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              section.title,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF3D1800),
                                              ),
                                            ),
                                            Text(
                                              '$completedInSection/${section.lessons.length} masomo',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 12,
                                                color: const Color(0xFF9E8070),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isExpanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: const Color(0xFFE87722),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isExpanded)
                                ...section.lessons.asMap().entries.map((entry) {
                                  final lessonIndex = entry.key;
                                  final lesson = entry.value;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: lesson.isRead
                                          ? (isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8))
                                          : Theme.of(context).cardColor,
                                      border: const Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFF0E4DA),
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 4,
                                      ),
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: lesson.isRead
                                              ? const Color(0xFFE87722)
                                                  .withValues(alpha: 0.1)
                                              : (isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8)),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: lesson.isRead
                                              ? const Icon(
                                                  Icons.check,
                                                  color: Color(0xFFE87722),
                                                  size: 20,
                                                )
                                              : Text(
                                                  '${lessonIndex + 1}',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xFFE87722),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      title: Text(
                                        lesson.title,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: lesson.isRead
                                              ? FontWeight.w400
                                              : FontWeight.w600,
                                          color: lesson.isRead
                                              ? const Color(0xFF5C3D2E)
                                              : const Color(0xFF3D1800),
                                        ),
                                      ),
                                      trailing: lesson.hasVideo
                                          ? const Icon(
                                              Icons.play_circle_outline,
                                              color: Color(0xFFE87722),
                                              size: 22,
                                            )
                                          : const Icon(
                                              Icons.article_outlined,
                                              color: Color(0xFF9E8070),
                                              size: 22,
                                            ),
                                      onTap: () =>
                                          context.push('/lesson/${lesson.id}').then((_) {
                                            if (context.mounted) {
                                              context.read<CourseProvider>().loadCourseDetail(widget.courseId);
                                            }
                                          }),
                                    ),
                                  );
                                }),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }


  String _buildCourseSummaryText(String description, String excerpt) {
    final source = description.trim().isNotEmpty ? description : excerpt;
    if (source.trim().isEmpty) return '';
    final parsed = _tryParseDelta(source.trim());
    if (parsed != null && parsed.trim().isNotEmpty) {
      return _normalizeText(parsed);
    }
    return _normalizeText(source.trim());
  }

  String? _tryParseDelta(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map && decoded['ops'] is List) {
        return _extractDeltaOpsText(decoded['ops'] as List);
      }
      if (decoded is List) {
        return _extractDeltaOpsText(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _extractDeltaOpsText(List ops) {
    final buffer = StringBuffer();
    for (final op in ops) {
      if (op is Map && op['insert'] is String) {
        buffer.write(op['insert'] as String);
      }
    }
    return buffer.toString();
  }

  String _normalizeText(String text) {
    final lines = text
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return lines.join('\n\n');
  }

}
class _ClassroomAppBarPlaceholder extends StatelessWidget
    implements PreferredSizeWidget {
  const _ClassroomAppBarPlaceholder();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF3D1800),
      leading: const BackButton(color: Colors.white),
      title: Text(
        'Darasani',
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: 0,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation(Color(0xFFE87722)),
          minHeight: 4,
        ),
      ),
    );
  }
}

class _EmptyClassroomState extends StatelessWidget {
  final String? sectionsErrorMessage;
  final VoidCallback onRetry;

  const _EmptyClassroomState({
    required this.sectionsErrorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasError =
        sectionsErrorMessage != null && sectionsErrorMessage!.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasError ? Icons.lock_outline : Icons.menu_book_outlined,
              size: 42,
              color: const Color(0xFFE87722),
            ),
            const SizedBox(height: 14),
            Text(
              hasError
                  ? 'Hatukuweza kufungua masomo ya darasa hili'
                  : 'Masomo bado hayajaonekana hapa',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1A0A00),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasError
                  ? sectionsErrorMessage!
                  : 'Rudi baadae au jaribu tena baada ya data ya kozi kupakiwa.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF5C3D2E),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE87722),
                side: const BorderSide(
                  color: Color(0xFFE8D5C8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'Jaribu tena',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}







