# Karakana App V2 — Claude Context

## Project
Flutter app for Kreative Karakana — Tanzanian Edutech platform for entrepreneurship training.
Version 2.0 — complete rebuild from design spec.

## Tech Stack
- Flutter (latest stable), Dart
- Provider (state management)
- GoRouter (navigation)
- Dio (HTTP)
- Flutter Secure Storage (tokens)
- Google Fonts (Poppins + Inter)
- firebase_messaging (push notifications)

## Backend
- Base URL: https://beta.kreativekarakana.co.tz
- Auth: Knox Token — Authorization: Token <token>
- Signup returns HTTP 306 on success (treat as success)
- Profile update: PATCH /api/v1/profiles/{userId}/ (NOT /profiles/me/)

## Brand Colors (AppColors)
- primary: #C4620A (orange)
- primaryDark: #3B1A08 (dark brown)
- primaryLight: #F5E6D8 (warm cream)
- background: #FFF8F4 (warm off-white)
- textPrimary: #1A0A00

## Design System
- Min border radius for inputs: 14px (AppRadius.input)
- Card border radius: 16px (AppRadius.card)
- Buttons: fully rounded 28px (AppRadius.button)
- Fonts: Poppins (headings) + Inter (body)
- All classes in lib/core/theme/

## Navigation (GoRouter)
- Bottom nav: 4 tabs — Nyumbani (/home), Tafuta (/explore), Zana (/zana), Akaunti (/account)
- Auth guard: unauthenticated → /login
- Onboarding guard: first launch → /onboarding

## Key Patterns
- Never use const with AppColors
- Router created ONCE in StatefulWidget initState
- Signup returns 306 = success
- Profile update uses /profiles/{id}/ not /profiles/me/
- All API calls via ApiClient().dio
- All errors via ApiClient().parseError(e)
- Token stored in FlutterSecureStorage

## Zana Section
- 4 tools: POS (live), Business Manager (live), Insurance (live), e-VICOBA (coming soon)
- Zana is the 3rd tab: /zana
- Model: lib/features/zana/models/zana_model.dart
- No backend API yet — static data

## Video Player
- Use video_player package (already in pubspec)
- Mux playback URL format: https://stream.mux.com/{playbackId}.m3u8
- Signed tokens from: GET /api/v1/lessons/{id}/

## Remaining Screens Status
- Notifications: lib/features/notifications/screens/notifications_screen.dart
- Support: lib/features/support/screens/support_screen.dart
- Trainer Dashboard: lib/features/trainer/screens/trainer_dashboard_screen.dart
- Course Builder: lib/features/trainer/screens/course_builder_screen.dart
