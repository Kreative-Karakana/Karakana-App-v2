/// API endpoint paths for Karakana by Kreative Karakana.
///
/// All paths are relative to [AppConstants.baseUrl].
/// No logic lives here — only static string constants.
class ApiEndpoints {
  ApiEndpoints._(); // Prevent instantiation

  // ─────────────────────────────────────────────
  // Authentication
  // ─────────────────────────────────────────────

  /// Authenticate an existing user and receive an access token.
  static const String login = '/api/auth/signin/';

  /// Register a new user account.
  static const String signup = '/api/auth/signup/';

  /// Initiate a password-reset flow via email.
  static const String forgotPassword = '/api/request-password-reset/';

  /// Verify a user's email address using the token sent to their inbox.
  static const String verifyEmail = '/api/auth/verify/';

  /// Resend the email verification link to the current user.
  static const String resendVerification = '/api/auth/verify/resend/';

  /// Invalidate the current session / access token.
  static const String logout = '/api/v1/accounts/logout/';

  // ─────────────────────────────────────────────
  // Profile
  // ─────────────────────────────────────────────

  /// Retrieve or update the currently authenticated user's profile.
  static const String profileMe = '/api/v1/accounts/profile/me/';

  /// Access a specific user profile by ID.
  static const String profileDetail = '/api/v1/accounts/profile/';

  /// Submit or retrieve a trainer application for the current user.
  static const String trainerApplication =
      '/api/v1/accounts/trainer-application/';

  /// Retrieve or update MasterCard-related data for the current user.
  static const String masterCardData = '/api/v1/accounts/mastercard-data/';

  /// Retrieve or manage the current user's ambassador referral code.
  static const String ambassadorCode = '/api/v1/accounts/ambassador-code/';

  // ─────────────────────────────────────────────
  // Courses
  // ─────────────────────────────────────────────

  /// List or retrieve courses.
  static const String courses = '/api/v1/courses/';

  /// List or retrieve course categories.
  static const String categories = '/api/v1/categories/';

  /// List or retrieve course sections.
  static const String sections = '/api/v1/courses/sections/';

  /// List or retrieve individual lessons within a course.
  static const String lessons = '/api/v1/courses/lessons/';

  /// Track or retrieve lesson completion progress for the current user.
  static const String lessonProgress = '/api/v1/courses/progress/';

  /// Enroll the current user in a free course.
  static const String enrollFree = '/api/v1/courses/enroll/';

  /// Add or remove courses from the current user's wishlist.
  static const String wishlist = '/api/v1/courses/wishlist/';

  /// Submit or retrieve course reviews.
  static const String reviews = '/api/v1/courses/reviews/';

  // ─────────────────────────────────────────────
  // Payments
  // ─────────────────────────────────────────────

  /// List or retrieve payment records.
  static const String payments = '/api/v1/payments/';

  /// Initiate a mobile-network-operator (MNO) checkout session.
  static const String mnoCheckout = '/api/v1/payments/checkout/';

  /// Retrieve or manage the current user's in-app wallet balance.
  static const String wallet = '/api/v1/payments/wallet/';

  /// Initiate a checkout using the user's in-app wallet balance.
  static const String walletCheckout = '/api/v1/payments/wallet/checkout/';

  // ─────────────────────────────────────────────
  // Communications
  // ─────────────────────────────────────────────

  /// Retrieve in-app notifications for the current user.
  static const String notifications = '/api/v1/communications/notifications/';

  /// Retrieve promotional banners displayed in the app.
  static const String banners = '/api/v1/communications/banners/';

  /// Create or retrieve support tickets raised by the current user.
  static const String supportTickets = '/api/v1/communications/support/';

  /// Send or retrieve messages within a support ticket thread.
  static const String supportMessages =
      '/api/v1/communications/support/messages/';

  /// Register or update the current device's push-notification token.
  static const String deviceToken = '/api/v1/communications/device-token/';
}
