import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/courses/screens/course_detail_screen.dart';
import '../../features/courses/screens/enrolled_courses_screen.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/payments/screens/payment_screen.dart';
import '../../features/payments/screens/payment_success_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/support/screens/support_screen.dart';

// ─────────────────────────────────────────────
// Route path constants
// ─────────────────────────────────────────────

/// Named path constants for every route in the app.
///
/// Always use these constants instead of raw strings when navigating
/// (e.g. `context.go(AppRoutes.home)`) so typos are caught at compile time.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String home = '/home';
  static const String courseDetail = '/courses/:id';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String notifications = '/notifications';
  static const String payment = '/payment/:courseId';
  static const String paymentSuccess = '/payment-success';
  static const String enrolledCourses = '/enrolled-courses';
  static const String support = '/support';
}

// ─────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────

/// Builds and configures the [GoRouter] for the entire Karakana app.
///
/// Call [AppRouter.createRouter] once at the root of the widget tree,
/// passing in the live [AuthProvider] so the router re-evaluates its
/// redirect logic whenever authentication state changes.
class AppRouter {
  AppRouter._();

  /// Creates and returns the configured [GoRouter].
  ///
  /// [authProvider] must be the same instance registered with
  /// [ChangeNotifierProvider] at the app root so that [GoRouter.refreshListenable]
  /// triggers a redirect check on every [notifyListeners] call.
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.splash,

      // Re-evaluates the redirect whenever AuthProvider notifies listeners
      // (e.g. after login, logout, or onboarding completion).
      refreshListenable: authProvider,

      // ── Global redirect logic ──────────────────
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isOnboardingComplete = authProvider.isOnboardingComplete;
        final location = state.matchedLocation;

        // Allow the splash screen to render without any redirect so it can
        // run its own initialization check before navigating.
        if (location == AppRoutes.splash) return null;

        // Onboarding must be completed before anything else, regardless of
        // authentication status.
        if (!isOnboardingComplete) {
          return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
        }

        // Authenticated users have no business on the auth screens.
        final isOnAuthScreen =
            location == AppRoutes.login ||
            location == AppRoutes.signup ||
            location == AppRoutes.forgotPassword ||
            location == AppRoutes.verifyEmail ||
            location == AppRoutes.onboarding;

        if (isAuthenticated && isOnAuthScreen) {
          return AppRoutes.home;
        }

        // Unauthenticated users may not access protected screens.
        if (!isAuthenticated && location == AppRoutes.home) {
          return AppRoutes.login;
        }

        // No redirect needed — let the navigation proceed as requested.
        return null;
      },

      // ── Route definitions ──────────────────────
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: AppRoutes.verifyEmail,
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const MainScreen(),
        ),
        GoRoute(
          path: AppRoutes.courseDetail,
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return CourseDetailScreen(courseId: id);
          },
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileEdit,
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.payment,
          builder: (context, state) {
            final courseId =
                int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0;
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return PaymentScreen(
              courseId: courseId,
              courseTitle: extra['title']?.toString() ?? '',
              price: (extra['price'] as num?)?.toDouble() ?? 0.0,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.paymentSuccess,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return PaymentSuccessScreen(
              courseTitle: extra['courseTitle']?.toString() ?? '',
            );
          },
        ),
        GoRoute(
          path: AppRoutes.enrolledCourses,
          builder: (context, state) => const EnrolledCoursesScreen(),
        ),
        GoRoute(
          path: AppRoutes.support,
          builder: (context, state) => const SupportScreen(),
        ),
      ],
    );
  }
}
