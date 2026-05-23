import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/cards/course_card_list.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';

/// Generic course list screen for recommended / popular / weekly / free /
/// enrolled categories. Pass [listType] and [title] via GoRouter extra:
///   context.push('/courses/list', extra: {'type': 'popular', 'title': 'Maarufu Sasa'})
class CourseListScreen extends StatelessWidget {
  final String listType;
  final String title;

  const CourseListScreen({
    super.key,
    required this.listType,
    required this.title,
  });

  List<CourseModel> _getCourses(CourseProvider provider) {
    switch (listType) {
      case 'recommended':
        return provider.recommendedCourses;
      case 'popular':
        return provider.popularCourses;
      case 'weekly':
        return provider.weeklyChoiceCourses;
      case 'free':
        return provider.freeCourses;
      case 'enrolled':
        return provider.enrolledCourses;
      default:
        return provider.allCourses;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(child: Consumer<CourseProvider>(
        builder: (context, provider, _) {
          final courses = _getCourses(provider);

          if (provider.isLoading && courses.isEmpty) {
            return const Center(
              child: KarakanaWaveLoader(color: AppColors.primary),
            );
          }

          if (courses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: Color(0xFFE8D5C8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hakuna kozi kwa sasa',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D1800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jaribu tena baadaye au tafuta kozi nyingine.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: const Color(0xFF9E8070),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: courses.length,
            itemBuilder: (_, i) => CourseListCard(
              course: courses[i],
              onTap: () => context.push('/course/${courses[i].id}'),
            ),
          );
        },
      )),
    );
  }
}
