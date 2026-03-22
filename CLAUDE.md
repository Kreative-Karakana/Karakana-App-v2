# Karakana App — Claude Context File

## Project Overview
Karakana is a Flutter mobile app for Kreative Karakana, a Tanzanian Edutech platform focused on entrepreneurship training. This is a clean rebuild targeting both Android and iOS from a single codebase.

## Tech Stack
- Flutter (latest stable)
- Dart
- Provider (state management)
- GoRouter (navigation)
- Dio (HTTP client)
- Flutter Secure Storage (token storage)
- Cached Network Image (image loading)
- Google Fonts (typography — Poppins for headings, Inter for body)

## Backend
- Base URL: https://beta.kreativekarakana.co.tz
- Auth: Token-based (Authorization: Token <token>)
- API version: /api/v1/ for most endpoints, /api/auth/ for authentication

## Auth Flow
1. Signup → POST /api/auth/signup/ (first_name, email, password) → returns 306 on success
2. Verify Email → POST /api/auth/verify/ (email, code) → returns token + user
3. Login → POST /api/auth/signin/ (email, password) → returns token + user
4. Token saved in FlutterSecureStorage

## Project Structure
lib/
├── core/
│   ├── constants/app_constants.dart    # App-wide constants and strings
│   ├── network/api_client.dart         # Dio HTTP client singleton
│   ├── network/api_endpoints.dart      # All API endpoint paths
│   ├── router/app_router.dart          # GoRouter navigation
│   ├── theme/app_theme.dart            # AppColors + AppTheme
│   └── utils/secure_storage.dart       # Token storage
├── features/
│   ├── auth/
│   │   ├── screens/                    # login, signup, forgot_password, verify_email
│   │   ├── services/auth_service.dart  # Auth API calls
│   │   └── providers/auth_provider.dart # Auth state
│   ├── courses/
│   │   ├── models/course_model.dart    # CourseModel, CategoryModel, etc.
│   │   ├── screens/                    # explore, course_detail
│   │   ├── services/course_service.dart # Course API calls
│   │   └── providers/course_provider.dart # Course state
│   ├── home/screens/
│   │   ├── home_screen.dart            # Main home tab
│   │   └── main_screen.dart            # Bottom nav shell
│   ├── onboarding/screens/             # Onboarding flow
│   ├── splash/                         # Splash screen
│   ├── notifications/                  # Notifications (coming soon)
│   └── profile/                        # Profile (coming soon)
└── widgets/
    └── course_card.dart                # Reusable course card

## Brand Colors
- Primary Orange: #C4620A
- Dark Brown: #3B1A08
- Light Orange: #F5E6D8
- Mid Orange: #E8A96A
- White: #FFFFFF
- Grey: #666666
- Light Grey: #F7F7F7
- Error Red: #C62828
- Success Green: #2E7D32

## Key Conventions
- All colors come from AppColors class in lib/core/theme/app_theme.dart
- Never use const with AppColors values
- All API calls go through ApiClient singleton (Dio)
- All screens use Consumer<Provider> or context.watch<Provider>()
- Navigation uses GoRouter: context.go() for replace, context.push() for stack
- All async methods wrapped in try/catch
- Loading states always set to false in finally block
- Always call notifyListeners() after state changes in providers
- Commit to GitHub after every completed feature

## API Endpoints (Real)
- Login: /api/auth/signin/
- Signup: /api/auth/signup/
- Verify Email: /api/auth/verify/
- Courses: /api/v1/courses/
- Categories: /api/v1/categories/
- Banners: /api/v1/communications/banners/
- Notifications: /api/v1/communications/notifications/me/
- Support Tickets: /api/v1/communications/tickets/

## Current Status
- Phase 1 (Auth): 100% complete
- Phase 2 (Home + Courses): 70% complete
- Phase 3 (Learning + Video): 0%
- Phase 4 (Payments): 0%
- Phase 5 (Profile): 0%
