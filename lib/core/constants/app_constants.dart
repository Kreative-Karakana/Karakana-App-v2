/// Core application constants for Karakana by Kreative Karakana.
/// A Tanzanian Edutech platform empowering entrepreneurs through learning.
library;

// ─────────────────────────────────────────────
// App Constants
// ─────────────────────────────────────────────

/// General application-level constants such as name, version,
/// API base URL, and local storage keys.
class AppConstants {
  AppConstants._(); // Prevent instantiation

  /// The display name of the application.
  static const String appName = 'Karakana';

  /// The current version of the application.
  static const String appVersion = '1.0.0';

  /// The base URL for all API requests.
  static const String baseUrl = 'https://beta.kreativekarakana.co.tz';

  /// The key used to store/retrieve the authentication token in local storage.
  static const String tokenKey = 'auth_token';

  /// The key used to track whether the user has completed onboarding.
  static const String onboardingKey = 'onboarding_complete';
}

// ─────────────────────────────────────────────
// App Strings
// ─────────────────────────────────────────────

/// UI text strings used throughout the application.
/// Centralising them here makes localisation easier in the future.
class AppStrings {
  AppStrings._(); // Prevent instantiation

  // ── Branding ──────────────────────────────

  /// Short tagline displayed on splash and marketing screens.
  static const String tagline = 'Empowering Entrepreneurs';

  // ── Login screen ──────────────────────────

  /// Main heading on the login screen.
  static const String loginTitle = 'Welcome Back';

  /// Supporting text below the login heading.
  static const String loginSubtitle = 'Login to continue learning';

  // ── Sign-up screen ────────────────────────

  /// Main heading on the sign-up screen.
  static const String signupTitle = 'Create Account';

  /// Supporting text below the sign-up heading.
  static const String signupSubtitle = 'Start your entrepreneurship journey';

  // ── Onboarding – slide 1 ──────────────────

  /// Title for the first onboarding slide.
  static const String onboardingTitle1 = 'Learn Entrepreneurship';

  /// Body text for the first onboarding slide.
  static const String onboardingBody1 =
      'Access world-class entrepreneurship courses taught by experienced trainers';

  // ── Onboarding – slide 2 ──────────────────

  /// Title for the second onboarding slide.
  static const String onboardingTitle2 = 'Learn At Your Own Pace';

  /// Body text for the second onboarding slide.
  static const String onboardingBody2 =
      'Watch lessons anytime, anywhere, on your schedule';

  // ── Onboarding – slide 3 ──────────────────

  /// Title for the third onboarding slide.
  static const String onboardingTitle3 = 'Grow Your Business';

  /// Body text for the third onboarding slide.
  static const String onboardingBody3 =
      'Apply real skills and tools to build and grow your business';
}
