# Karakana V2 Architecture

> Reader note: This file explains how the Flutter app is structured. Use it before changing routes, providers, API integration, storage, or shared UI patterns.

## Overview

Karakana V2 is a Flutter app organized around feature modules. Shared concerns live under `lib/core`, reusable UI under `lib/widgets`, and product areas under `lib/features`.

## Folder Structure

| Path | Responsibility |
| --- | --- |
| `lib/core/constants` | API endpoints and app-level constants |
| `lib/core/network` | Dio API client, auth headers, error parsing |
| `lib/core/router` | `go_router` route table and route guards |
| `lib/core/theme` | Colors, spacing, typography, and theme setup |
| `lib/core/utils` | Secure storage, responsiveness, profile completeness, screenshot prevention |
| `lib/features/auth` | Login, signup, email verification, social login, biometric, forgot password |
| `lib/features/courses` | Course browsing, detail, learning, reviews, certificates, wishlist |
| `lib/features/ebooks` | Store, library, reader, trainer eBook management |
| `lib/features/fursa` | Opportunity/fursa discovery |
| `lib/features/home` | Main shell, learner home, app entry tabs |
| `lib/features/notifications` | Notification list, read/unread handling |
| `lib/features/payments` | Checkout, payment success, wallet, transactions |
| `lib/features/profile` | Profile, edit profile, password change, terms, trainer application |
| `lib/features/support` | Tickets, new ticket, ticket detail |
| `lib/features/trainer` | Trainer dashboard, courses, lessons, quizzes, student progress |
| `lib/features/zana` | Business tools, insurance, Kikoba, eBook entry points |
| `lib/widgets` | Reusable buttons, cards, loaders, logo, section headers, popups |

## Routing

Routing is centralized in `lib/core/router/app_router.dart`.

Important route behavior:

- `/` opens the splash screen.
- Onboarding must be completed before protected routes.
- Unauthenticated users are redirected to `/login` except for public Zana/Fursa routes.
- Authenticated users are redirected away from auth screens.
- Trainers are routed to `/trainer/dashboard`; normal users are routed to `/home`.
- Trainers with `password_change_required == true` are forced to `/profile/change-password` before proceeding.

## State Management

The app uses `provider`.

Current provider responsibilities include:

- `AuthProvider` stores auth state, roles, current user, onboarding state, and password-change enforcement.
- Feature providers manage domain data such as courses, eBooks, notifications, Fursa, and payments.
- Providers should expose clear loading, error, empty, and populated states so screens remain predictable.

## API Integration

`lib/core/network/api_client.dart` owns the shared Dio client.

Current behavior:

- Uses `AppConstants.baseUrl`.
- Attaches `Authorization: Token <token>` except for auth/public endpoints.
- Parses common API errors into user-friendly Swahili messages.
- Clears secure storage on `401`.
- Logs request/response details in debug builds.

Endpoint constants live in `lib/core/constants/api_endpoints.dart`.

## Secure Storage and Token Lifecycle

`lib/core/utils/secure_storage.dart` stores sensitive local session data.

Expected behavior:

- Auth token is saved after login or email verification.
- Roles are persisted because profile refresh responses may not include roles.
- Biometric tokens are scoped to the active account.
- Session data is cleared on logout or unauthorized API responses.

## Design System

Core visual decisions live in:

- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_spacing.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/core/theme/app_theme.dart`

The app is mobile-first and currently uses Swahili labels for user-facing copy. New screens should use the existing Karakana gradient, warm neutral backgrounds, rounded cards, status chips, and app topbar patterns unless a design issue explicitly changes them.

## Error and Empty States

Every screen that depends on remote data should document and implement:

- Loading state.
- Empty state.
- Error state.
- Retry action where useful.
- Offline/network failure messaging when applicable.

## Known Architecture Gaps

- More automated widget/integration tests are needed.
- Some API contracts still need documented request/response examples.
- Screenshots and flow diagrams should be added as the V2 UI stabilizes.
