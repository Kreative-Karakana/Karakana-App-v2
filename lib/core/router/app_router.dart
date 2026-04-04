import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/biometric_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/courses/screens/classroom_screen.dart';
import '../../features/courses/screens/course_detail_screen.dart';
import '../../features/courses/screens/video_lesson_screen.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/payments/screens/payment_screen.dart';
import '../../features/payments/screens/payment_success_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/zana/screens/biz_manager_screen.dart';
import '../../features/zana/screens/insurance_screen.dart';
import '../../features/zana/screens/pos_screen.dart';
import '../../features/zana/screens/vicoba_screen.dart';
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
  static const String supportDetail = '/support/:id';
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

Widget _comingSoonScaffold(String title) {
  return Scaffold(
    backgroundColor: const Color(0xFFFFF8F4),
    appBar: AppBar(
      backgroundColor: const Color(0xFF3B1A08),
      foregroundColor: Colors.white,
      title: Text(title),
    ),
    body: Center(
      child: Text(
        '$title - Coming Soon',
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
        ];
        const publicRoutes = [
          AppRoutes.zana,
          '/zana/vicoba',
          '/zana/pos',
          '/zana/biz-manager',
          '/zana/insurance',
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
          return AppRoutes.home;
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
          builder: (context, state) => _placeholder('Explore'),
        ),
        GoRoute(
          path: AppRoutes.zana,
          builder: (context, state) => const ZanaScreen(),
        ),
        GoRoute(
          path: '/zana/vicoba',
          builder: (context, state) => const VicobScreen(),
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
          path: AppRoutes.account,
          builder: (context, state) => const ProfileScreen(),
        ),

        // ── Courses ─────────────────────────────────────────────
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
          path: '/lesson/:id',
          builder: (context, state) => VideoLessonScreen(
            lessonId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: '/course/:id/complete',
          builder: (context, state) => _comingSoonScaffold('Hongera!'),
        ),

        // ── Payments ────────────────────────────────────────────
        GoRoute(
          path: '/payment/success',
          builder: (context, state) => const PaymentSuccessScreen(),
        ),
        GoRoute(
          path: '/payment/history',
          builder: (context, state) =>
              _comingSoonScaffold('Historia ya Malipo'),
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
          builder: (context, state) => _comingSoonScaffold('Mkoba'),
        ),

        // ── Profile ─────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          builder: (context, state) => _comingSoonScaffold('Hariri Wasifu'),
        ),
        GoRoute(
          path: AppRoutes.myCourses,
          builder: (context, state) => _comingSoonScaffold('Kozi Zangu'),
        ),
        GoRoute(
          path: AppRoutes.wishlist,
          builder: (context, state) => _comingSoonScaffold('Vipendwa'),
        ),

        // ── Trainer ─────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.trainerApply,
          builder: (context, state) =>
              _comingSoonScaffold('Ombi la Mwalimu'),
        ),
        GoRoute(
          path: AppRoutes.trainerDashboard,
          builder: (context, state) => _comingSoonScaffold('Dashibodi'),
        ),
        GoRoute(
          path: AppRoutes.courseBuilder,
          builder: (context, state) => _comingSoonScaffold('Unda Kozi'),
        ),

        // ── Notifications / Support ──────────────────────────────
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => _comingSoonScaffold('Arifa'),
        ),
        GoRoute(
          path: AppRoutes.support,
          builder: (context, state) => _comingSoonScaffold('Msaada'),
        ),
        GoRoute(
          path: AppRoutes.supportNew,
          builder: (context, state) => _placeholder('New Ticket'),
        ),
        GoRoute(
          path: '/support/:id',
          builder: (context, state) =>
              _placeholder('Support: ${state.pathParameters['id']}'),
        ),
      ],
    );
  }
}
