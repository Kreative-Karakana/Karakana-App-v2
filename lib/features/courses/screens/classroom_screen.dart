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
        if (provider.isLoadingDetail) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFF8F4),
            appBar: _ClassroomAppBarPlaceholder(),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFC4620A),
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

        if (course == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFFFF8F4),
            appBar: AppBar(
              backgroundColor: const Color(0xFF3B1A08),
              leading: const BackButton(color: Colors.white),
              title: Text(
                'Darasani',
                style: GoogleFonts.poppins(
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
                      color: Color(0xFFC4620A),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      provider.errorMessage ?? 'Hatukuweza kufungua darasa hili.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF5C3D2E),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => provider.loadCourseDetail(widget.courseId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4620A),
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
                        style: GoogleFonts.poppins(
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
          backgroundColor: const Color(0xFFFFF8F4),
          appBar: AppBar(
            backgroundColor: const Color(0xFF3B1A08),
            leading: const BackButton(color: Colors.white),
            title: Text(
              course.title.isNotEmpty ? course.title : 'Darasani',
              style: GoogleFonts.poppins(
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
                valueColor: const AlwaysStoppedAnimation(Color(0xFFC4620A)),
                minHeight: 4,
              ),
            ),
          ),
          body: Column(
            children: [
              Container(
                color: Colors.white,
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
                              Color(0xFFC4620A),
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFC4620A),
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
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF9E8070),
                            ),
                          ),
                          Text(
                            '$completedLessons / $totalLessons Masomo',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3B1A08),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            progress >= 1.0
                                ? 'Kozi imekamilika!'
                                : 'Endelea vizuri!',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: progress >= 1.0
                                  ? const Color(0xFF2E7D32)
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
                          side: const BorderSide(color: Color(0xFF2E7D32)),
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
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                color: Color(0xFFF0E4DA),
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
                                  color: const Color(0xFFF5E6D8),
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
                                          color: Color(0xFFC4620A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${sectionIndex + 1}',
                                            style: GoogleFonts.poppins(
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
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF3B1A08),
                                              ),
                                            ),
                                            Text(
                                              '$completedInSection/${section.lessons.length} masomo',
                                              style: GoogleFonts.inter(
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
                                        color: const Color(0xFFC4620A),
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
                                          ? const Color(0xFFE8F5E9)
                                          : Colors.white,
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
                                              ? const Color(0xFF2E7D32)
                                                  .withValues(alpha: 0.1)
                                              : const Color(0xFFF5E6D8),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: lesson.isRead
                                              ? const Icon(
                                                  Icons.check,
                                                  color: Color(0xFF2E7D32),
                                                  size: 20,
                                                )
                                              : Text(
                                                  '${lessonIndex + 1}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xFFC4620A),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      title: Text(
                                        lesson.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: lesson.isRead
                                              ? FontWeight.w400
                                              : FontWeight.w600,
                                          color: lesson.isRead
                                              ? const Color(0xFF5C3D2E)
                                              : const Color(0xFF3B1A08),
                                        ),
                                      ),
                                      trailing: lesson.hasVideo
                                          ? const Icon(
                                              Icons.play_circle_outline,
                                              color: Color(0xFFC4620A),
                                              size: 22,
                                            )
                                          : const Icon(
                                              Icons.article_outlined,
                                              color: Color(0xFF9E8070),
                                              size: 22,
                                            ),
                                      onTap: () =>
                                          context.push('/lesson/${lesson.id}'),
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
}

class _ClassroomAppBarPlaceholder extends StatelessWidget
    implements PreferredSizeWidget {
  const _ClassroomAppBarPlaceholder();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF3B1A08),
      leading: const BackButton(color: Colors.white),
      title: Text(
        'Darasani',
        style: GoogleFonts.poppins(
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
          valueColor: const AlwaysStoppedAnimation(Color(0xFFC4620A)),
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
              color: const Color(0xFFC4620A),
            ),
            const SizedBox(height: 14),
            Text(
              hasError
                  ? 'Hatukuweza kufungua masomo ya darasa hili'
                  : 'Masomo bado hayajaonekana hapa',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B1A08),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasError
                  ? sectionsErrorMessage!
                  : 'Rudi baadae au jaribu tena baada ya data ya kozi kupakiwa.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF5C3D2E),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC4620A),
                side: const BorderSide(
                  color: Color(0xFFE8D5C8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'Jaribu tena',
                style: GoogleFonts.poppins(
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
