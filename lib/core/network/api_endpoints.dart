/// API endpoint paths for Karakana by Kreative Karakana.
///
/// All paths are relative to [AppConstants.baseUrl].
/// No logic lives here — only static string constants.
class ApiEndpoints {
  ApiEndpoints._(); // Prevent instantiation

  // ─────────────────────────────────────────────
  // Authentication  (no /api/v1/ prefix)
  // ─────────────────────────────────────────────

  static const String login = '/api/auth/signin/';
  static const String signup = '/api/auth/signup/';
  static const String forgotPassword = '/api/request-password-reset/';
  static const String verifyEmail = '/api/auth/verify/';
  static const String resendVerification = '/api/auth/verify/resend/';

  // ─────────────────────────────────────────────
  // Courses  (/api/v1/)
  // ─────────────────────────────────────────────

  /// List / search courses. Supports: q, categories__name, recommend,
  /// popular, free, weekly_choice, enrolled, page_size.
  static const String courses = '/api/v1/courses/';

  static const String categories = '/api/v1/categories/';
  static const String enrollFree = '/api/v1/courses/enroll/';
  static const String wishlist = '/api/v1/wishlist/';

  /// Sections: GET /api/v1/courses/{courseId}/sections/
  static const String sections = '/api/v1/courses/';

  /// Lessons: GET /api/v1/sections/{sectionId}/lessons/
  static const String lessons = '/api/v1/sections/';

  /// Lesson detail: GET /api/v1/lessons/{lessonId}/
  static const String lessonDetail = '/api/v1/lessons/';

  /// Lesson progress: POST /api/v1/lessons/{lessonId}/progress/
  static const String lessonProgress = '/api/v1/lessons/';

  /// Reviews: GET/POST /api/v1/courses/{courseId}/reviews/
  static const String reviews = '/api/v1/courses/';

  /// Review reply: POST /api/v1/courses/{courseId}/reviews/{reviewId}/reply/
  static const String reviewReply = '/api/v1/courses/';

  // ─────────────────────────────────────────────
  // Profile  (/api/v1/)
  // ─────────────────────────────────────────────

  static const String profileMe = '/api/v1/profiles/me/';

  /// Profile detail: GET /api/v1/profiles/{userId}/
  static const String profileDetail = '/api/v1/profiles/';

  static const String masterCardData = '/api/v1/master-card/';
  static const String trainerApplication = '/api/v1/trainer-application/';
  static const String ambassadorCode = '/api/v1/ambassador-codes/';

  // ─────────────────────────────────────────────
  // Payments  (/api/v1/)
  // ─────────────────────────────────────────────

  static const String paymentsCheckout = '/api/v1/payments/checkout/';

  /// Payment status: GET /api/v1/payments/{externalId}/
  static const String paymentStatus = '/api/v1/payments/';

  static const String wallet = '/api/v1/wallet/me/';
  static const String walletCheckout = '/api/v1/wallet/checkouts/';

  // ─────────────────────────────────────────────
  // Communications  (/api/v1/)
  // ─────────────────────────────────────────────

  static const String banners = '/api/v1/communications/banners/';
  static const String notifications =
      '/api/v1/communications/notifications/me/';
  static const String supportTickets = '/api/v1/communications/tickets/';

  /// Support messages: GET/POST /api/v1/communications/tickets/{ticketId}/messages/
  static const String supportMessages = '/api/v1/communications/tickets/';

  static const String deviceToken = '/api/v1/communications/device-token/';
}
