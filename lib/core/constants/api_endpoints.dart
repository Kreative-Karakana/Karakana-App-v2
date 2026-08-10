class ApiEndpoints {
  // Auth
  static const String login = '/api/auth/signin/';
  static const String signup = '/api/auth/signup/';
  static const String forgotPassword = '/api/request-password-reset/';
  static const String verifyEmail = '/api/auth/verify/';
  static const String resendOTP = '/api/auth/verify/resend/';
  static const String googleAuth = '/api/oauth/';
  static const String appleAuth = '/api/apple-oauth/';
  static const String changePassword = '/api/auth/change-password/';

  // Profile
  static const String profileMe = '/api/v1/profiles/me/';
  static const String profileDetail = '/api/v1/profiles/';
  static const String trainerApplication = '/api/v1/trainer-application/';
  static const String masterCard = '/api/v1/master-card/';
  static const String ambassadorCode = '/api/v1/ambassador-codes/';
  static const String deleteAccount = '/api/v1/accounts/me/delete/';

  // Courses
  static const String courses = '/api/v1/courses/';
  static const String categories = '/api/v1/categories/';
  static const String enrollFree = '/api/v1/courses/enroll/';
  static const String wishlist = '/api/v1/wishlist/';
  static const String lessonProgress = '/api/v1/lessons/';
  static const String reviews = '/api/v1/courses/';

  // Payments
  static const String paymentsCheckout = '/api/v1/payments/checkout/';
  static const String paymentStatus = '/api/v1/payments/';
  static const String wallet = '/api/v1/wallet/me/';
  static const String walletCheckout = '/api/v1/wallet/checkouts/';

  // Subscriptions
  static const String subscriptionsMe = '/api/v1/subscriptions/me/';
  static const String subscriptionPlans = '/api/v1/subscriptions/plans/';
  static const String subscriptionTrialActivate =
      '/api/v1/subscriptions/trial/activate/';
  static const String subscriptionCheckout = '/api/v1/subscriptions/checkout/';

  // Communications
  static const String banners = '/api/v1/communications/banners/';
  static const String notifications =
      '/api/v1/communications/notifications/me/';
  static const String supportTickets = '/api/v1/communications/tickets/';
  static const String zanaLeads = '/api/v1/communications/leads/';
  static const String deviceToken = '/api/v1/communications/device-token/';
  static const String versions = '/api/v1/versions/';
}
