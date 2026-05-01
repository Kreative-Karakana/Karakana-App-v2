import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/biometric_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/courses/screens/classroom_screen.dart';
import '../../features/courses/screens/course_complete_screen.dart';
import '../../features/courses/screens/course_detail_screen.dart';
import '../../features/courses/screens/course_reviews_screen.dart';
import '../../features/courses/screens/course_list_screen.dart';
import '../../features/courses/screens/my_courses_screen.dart';
import '../../features/courses/screens/video_lesson_screen.dart';
import '../../features/courses/screens/wishlist_screen.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/payments/screens/payment_history_screen.dart';
import '../../features/payments/screens/payment_screen.dart';
import '../../features/payments/screens/payment_success_screen.dart';
import '../../features/payments/screens/wallet_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/mastercard_form_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/terms_screen.dart';
import '../../features/profile/screens/trainer_application_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/support/screens/new_ticket_screen.dart';
import '../../features/support/screens/support_screen.dart';
import '../../features/support/screens/ticket_detail_screen.dart';
import '../../features/trainer/screens/course_builder_screen.dart';
import '../../features/trainer/screens/lesson_manager_screen.dart';
import '../../features/trainer/screens/quiz_manager_screen.dart';
import '../../features/trainer/screens/student_progress_screen.dart';
import '../../features/trainer/screens/trainer_dashboard_screen.dart';
import '../../features/fursa/screens/fursa_screen.dart';
import '../../features/zana/screens/biz_manager_screen.dart';
import '../../features/zana/screens/insurance_screen.dart';
import '../../features/zana/screens/pos_screen.dart';
import '../../features/zana/screens/ebooks_screen.dart';
import '../../features/zana/screens/kikoba_screen.dart';
import '../../features/zana/screens/zana_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String biometric = '/biometric';
  static const String home = '/home';
  static const String explore = '/explore';
  static const String zana = '/zana';
  static const String account = '/account';
  static const String courseDetail = '/course/:id';
  static const String classroom = '/course/:id/classroom';
  static const String courseComplete = '/course/:id/complete';
  static const String lesson = '/lesson/:id';
  static const String payment = '/payment/:courseId';
  static const String paymentSuccess = '/payment/success';
  static const String paymentHistory = '/payment/history';
  static const String wallet = '/wallet';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String myCourses = '/my-courses';
  static const String wishlist = '/wishlist';
  static const String trainerApply = '/trainer/apply';
  static const String trainerDashboard = '/trainer/dashboard';
  static const String courseBuilder = '/trainer/course-builder';
  static const String notifications = '/notifications';
  static const String support = '/support';
  static const String supportNew = '/support/new';
  static const String supportDetail = '/support/:ticketId';
  static const String trainerStudents = '/trainer/students';
  static const String lessonManager = '/trainer/course/:courseId/sections';
  static const String mastercardForm = '/mastercard-form';
  static const String terms = '/terms';
}

Widget _placeholder(String routeName) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Text(
        routeName,
        style: const TextStyle(fontSize: 18, color: Colors.black54),
      ),
    ),
  );
}

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuth = authProvider.isAuthenticated;
        final isOnboarded = authProvider.isOnboardingComplete;
        final location = state.matchedLocation;

        const authRoutes = [
          AppRoutes.login,
          AppRoutes.signup,
          AppRoutes.verifyEmail,
          AppRoutes.forgotPassword,
          AppRoutes.biometric,
        ];
        const publicRoutes = [
          AppRoutes.zana,
          '/zana/kikoba',
          '/zana/pos',
          '/zana/biz-manager',
          '/zana/insurance',
          '/fursa',
        ];

        // Splash handles its own navigation
        if (location == AppRoutes.splash) return null;

        // Onboarding guard — takes full priority, skip auth guard entirely
        if (!isOnboarded) {
          return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
        }

        // Auth guard: redirect unauthenticated to login
        if (!isAuth &&
            !authRoutes.contains(location) &&
            !publicRoutes.contains(location)) {
          return AppRoutes.login;
        }

        // Already logged in: redirect away from auth screens
        if (isAuth && authRoutes.contains(location)) {
          return authProvider.isTrainer ? AppRoutes.trainerDashboard : AppRoutes.home;
        }

        return null;
      },
      routes: [
        // ── Splash ──────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),

        // ── Onboarding ──────────────────────────────────────────
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),

        // ── Auth ────────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: AppRoutes.verifyEmail,
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: AppRoutes.biometric,
          builder: (context, state) => const BiometricScreen(),
        ),

        // ── Main shell ───────────────────────────────────────────
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const MainScreen(),
        ),
        GoRoute(
          path: AppRoutes.explore,
          builder: (context, state) => const MainScreen(initialIndex: 1),
        ),
        GoRoute(
          path: AppRoutes.zana,
          builder: (context, state) => const ZanaScreen(),
        ),
        GoRoute(
          path: '/fursa',
          builder: (context, state) => const FursaScreen(),
        ),
        GoRoute(
          path: '/zana/kikoba',
          builder: (context, state) => const KikobaScreen(),
        ),
        GoRoute(
          path: '/zana/pos',
          builder: (context, state) => const POSScreen(),
        ),
        GoRoute(
          path: '/zana/biz-manager',
          builder: (context, state) => const BizManagerScreen(),
        ),
        GoRoute(
          path: '/zana/insurance',
          builder: (context, state) => const InsuranceScreen(),
        ),
        GoRoute(
          path: '/zana/ebooks',
          builder: (context, state) => const EBooksScreen(),
        ),
        GoRoute(
          path: AppRoutes.account,
          builder: (context, state) => const ProfileScreen(),
        ),

        // ── Courses ─────────────────────────────────────────────
        GoRoute(
          path: '/courses/list',
          builder: (context, state) {
            final extra = state.extra is Map
                ? Map<String, dynamic>.from(state.extra as Map)
                : <String, dynamic>{};
            return CourseListScreen(
              listType: (extra['type'] as String?) ?? 'all',
              title: (extra['title'] as String?) ?? 'Kozi',
            );
          },
        ),
        GoRoute(
          path: '/course/:id',
          builder: (context, state) => CourseDetailScreen(
            courseId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: '/course/:id/classroom',
          builder: (context, state) => ClassroomScreen(
            courseId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: '/course/:id/reviews',
          builder: (context, state) => CourseReviewsScreen(
            courseId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: '/lesson/:id',
          builder: (context, state) => VideoLessonScreen(
            lessonId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: '/course/:id/complete',
          builder: (context, state) => CourseCompleteScreen(
            courseId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            courseTitle:
                (state.extra as Map?)?['courseTitle']?.toString() ?? 'Kozi',
          ),
        ),

        // ── Payments ────────────────────────────────────────────
        GoRoute(
          path: '/payment/success',
          builder: (context, state) => const PaymentSuccessScreen(),
        ),
        GoRoute(
          path: '/payment/history',
          builder: (context, state) => const PaymentHistoryScreen(),
        ),
        GoRoute(
          path: '/payment/:courseId',
          builder: (context, state) {
            final extra = state.extra is Map
                ? Map<String, dynamic>.from(state.extra as Map)
                : <String, dynamic>{};
            return PaymentScreen(
              courseId: int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0,
              courseTitle: (extra['courseTitle'] as String?) ?? 'Kozi ya Karakana',
              coursePrice: (extra['coursePrice'] as num?)?.toDouble() ?? 0,
              courseThumbnail: extra['courseThumbnail'] as String?,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.wallet,
          builder: (context, state) => const WalletScreen(),
        ),

        // ── Profile ─────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.mastercardForm,
          builder: (context, state) {
            final shouldPop = (state.extra as Map?)?['shouldPop'] as bool? ?? false;
            return MastercardFormScreen(shouldPop: shouldPop);
          },
        ),
        GoRoute(
          path: AppRoutes.terms,
          builder: (context, state) => const TermsScreen(),
        ),
        GoRoute(
          path: AppRoutes.myCourses,
          builder: (context, state) => const MyCoursesScreen(),
        ),
        GoRoute(
          path: AppRoutes.wishlist,
          builder: (context, state) => const WishlistScreen(),
        ),

        // ── Trainer ─────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.trainerApply,
          builder: (context, state) => const TrainerApplicationScreen(),
        ),
        GoRoute(
          path: AppRoutes.trainerDashboard,
          builder: (context, state) => const TrainerDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.courseBuilder,
          builder: (context, state) {
            final courseId = int.tryParse(
              state.uri.queryParameters['courseId'] ?? '',
            );
            return CourseBuilderScreen(courseId: courseId);
          },
        ),
        GoRoute(
          path: AppRoutes.trainerStudents,
          builder: (context, state) {
            final courseId = int.tryParse(
              state.uri.queryParameters['courseId'] ?? '',
            );
            return StudentProgressScreen(courseId: courseId);
          },
        ),
        GoRoute(
          path: '/trainer/quiz/:courseId',
          builder: (context, state) {
            final courseId = int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0;
            return QuizManagerScreen(courseId: courseId);
          },
        ),
        GoRoute(
          path: '/trainer/course/:courseId/sections',
          builder: (context, state) {
            final courseId = int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0;
            final extra = state.extra as Map?;
            return LessonManagerScreen(
              courseId: courseId,
              courseTitle: extra?['title'] as String? ?? 'Kozi',
            );
          },
        ),

        // ── Notifications / Support ──────────────────────────────
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.support,
          builder: (context, state) => const SupportScreen(),
        ),
        GoRoute(
          path: AppRoutes.supportNew,
          builder: (context, state) => const NewTicketScreen(),
        ),
        GoRoute(
          path: '/support/:ticketId',
          builder: (context, state) => TicketDetailScreen(
            ticketId:
                int.tryParse(state.pathParameters['ticketId'] ?? '') ?? 0,
          ),
        ),
      ],
    );
  }
}
