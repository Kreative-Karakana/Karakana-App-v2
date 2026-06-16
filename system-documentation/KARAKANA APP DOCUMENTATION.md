# Karakana App V2 Documentation

> Reader note: This file is the polished, export-friendly Karakana V2 mobile documentation baseline. The live technical source of truth remains `dev/Karakana-App-v2/docs/` and the Flutter source code under `dev/Karakana-App-v2/lib/`. When app behavior changes, update the V2 docs first, then refresh this baseline before exporting a new PDF.

## 1. Purpose

Karakana App V2 is the Flutter mobile application for learners, trainers, eBooks, payments, notifications, support, profile management, and Zana business tools.

This documentation baseline is used to:

- Explain the V2 app structure to engineers, designers, testers, and operators.
- Separate current V2 behavior from old V1 assumptions.
- Provide a comparison metric for future documentation quality.
- Act as the maintainable source for future app documentation exports.

## 2. Documentation Sources

| Source | Path | Purpose |
| --- | --- | --- |
| V2 docs index | `dev/Karakana-App-v2/docs/index.md` | Main entry point |
| Architecture docs | `dev/Karakana-App-v2/docs/architecture.md` | Folder structure, routing, providers, API, storage, UI conventions |
| Setup docs | `dev/Karakana-App-v2/docs/setup.md` | Local setup, environment, validation commands |
| Flow docs | `dev/Karakana-App-v2/docs/flows.md` | Product/user/trainer/payment/support/notification flows |
| Release docs | `dev/Karakana-App-v2/docs/release.md` | Android and iOS release process |
| Checklist | `dev/Karakana-App-v2/docs/documentation-checklist.md` | Reusable V2 documentation quality bar |
| V2 source code | `dev/Karakana-App-v2/lib/` | Implementation source of truth |
| Old app docs | `old-dev/Karakana-App/docs/` | Reference only; do not copy blindly |

## 3. V2 Scope

The current V2 app includes:

- Splash and onboarding.
- Email/password login.
- Google and Apple login.
- Biometric login.
- Signup, email verification, and forgot-password flow.
- Normal user home and navigation.
- Course browsing, search, detail, enrollment, classroom, video lessons, completion, reviews, wishlist, and my-courses.
- eBook store, detail, library, and secure reader.
- Trainer dashboard, account, course builder, lesson manager, quiz manager, student progress, and trainer eBook management.
- Payments, payment success, user transactions, and wallet surfaces.
- Notifications and device-token registration.
- Support tickets and ticket detail.
- Profile editing, password change, terms, account deletion, and trainer application.
- Zana tools including business management, eBooks, insurance, POS, and Kikoba.

## 4. App Architecture

The app is organized around feature modules.

| Path | Responsibility |
| --- | --- |
| `lib/core/constants` | API endpoints and app constants |
| `lib/core/network` | Dio client, auth headers, error handling |
| `lib/core/router` | `go_router` route table and guards |
| `lib/core/theme` | Colors, spacing, typography, theme setup |
| `lib/core/utils` | Secure storage, responsiveness, screenshot prevention, profile completeness |
| `lib/features/auth` | Authentication screens and provider |
| `lib/features/courses` | Learner course experience |
| `lib/features/ebooks` | eBook store, reader, library, trainer eBook management |
| `lib/features/home` | Main shell and learner home |
| `lib/features/notifications` | Notifications list and state |
| `lib/features/payments` | Payment, transaction, wallet screens and services |
| `lib/features/profile` | Account/profile screens |
| `lib/features/support` | Support tickets |
| `lib/features/trainer` | Trainer dashboard and content management |
| `lib/features/zana` | Zana tools |
| `lib/widgets` | Reusable UI components |

## 5. Routing and Guards

Routing is centralized in:

- `lib/core/router/app_router.dart`

Current route behavior:

- `/` opens the splash screen.
- Onboarding is required before protected routes.
- Unauthenticated users are redirected to `/login`, except configured public Zana/Fursa routes.
- Authenticated users are redirected away from auth screens.
- Trainers land on `/trainer/dashboard`.
- Normal users land on `/home`.
- Trainers with `password_change_required == true` are forced to `/profile/change-password` before proceeding.

## 6. State Management

Karakana V2 uses `provider`.

Important provider responsibilities:

- `AuthProvider` manages auth state, roles, current user, onboarding state, and password-change enforcement.
- Course/eBook/payment/notification providers manage remote data and UI state for their features.
- Providers should expose stable loading, error, empty, retry, and populated states.

## 7. API Integration

The shared API client lives in:

- `lib/core/network/api_client.dart`

Endpoint constants live in:

- `lib/core/constants/api_endpoints.dart`

Current behavior:

- Uses `AppConstants.baseUrl`.
- Supports local backend override through `--dart-define=API_BASE_URL=...`.
- Adds `Authorization: Token <token>` for protected endpoints.
- Avoids token attachment for auth/public endpoints.
- Parses common backend errors into user-friendly Swahili messages.
- Clears local session on `401`.
- Logs API request/response information in debug mode.

## 8. Auth Flow

Auth files:

- `lib/features/auth/providers/auth_provider.dart`
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/auth/screens/signup_screen.dart`
- `lib/features/auth/screens/verify_email_screen.dart`
- `lib/features/auth/screens/forgot_password_screen.dart`
- `lib/features/auth/screens/biometric_screen.dart`

Flow summary:

1. Splash initializes onboarding/session state.
2. User completes onboarding.
3. User logs in or signs up.
4. Signup proceeds through email verification.
5. Device token registration is attempted during login/verification.
6. Trainer roles are preserved locally because profile refresh may not include roles.
7. Imported/new trainers can be forced to change password before continuing.

## 9. Course Flow

Course files live under:

- `lib/features/courses/`

The course experience covers:

- Browsing and search.
- Course listing and detail.
- Enrollment and payment entry.
- Classroom and video lessons.
- Progress/completion.
- Reviews.
- Wishlist.
- My courses.
- Certificate generation.

Documentation rule:

- Any change to course access, enrollment, or payment gates must be reflected in both app docs and backend API/payment docs.

## 10. eBook Flow

eBook files live under:

- `lib/features/ebooks/`

The eBook experience covers:

- Store browsing.
- eBook detail.
- Library access.
- Secure reader.
- Trainer eBook listing/detail/create/edit.

Documentation rule:

- Reader access must be documented against backend ownership/purchase behavior.
- Trainer eBook deletion should be documented as staff-reviewed once the operations queue exists.

## 11. Payments, Wallet, and Transactions

Payment files live under:

- `lib/features/payments/`

The payment experience covers:

- Checkout.
- Payment success.
- User transactions.
- Wallet surfaces.

Documentation rule:

- Normal-user transaction pages must use user-facing language only.
- Trainer earnings, withdrawals, disbursements, and payouts must be documented separately from normal-user transactions.

## 12. Trainer Experience

Trainer files live under:

- `lib/features/trainer/`

Trainer experience includes:

- Dashboard.
- Account.
- Course builder.
- Course list.
- Lesson manager.
- Quiz manager.
- Student progress.
- Trainer eBook management.

Important behavior:

- Trainers should receive trainer-specific notifications.
- Trainer password-change prompts must block access until resolved when required.
- Destructive content actions should move toward backend staff approval.

## 13. Notifications

Notification files live under:

- `lib/features/notifications/`

Expected behavior:

- Normal users and trainers receive role-appropriate notifications.
- Read/unread status is stable.
- Notifications do not auto-recreate as unread after being marked read.
- Device token behavior is tied to login/verification.

## 14. Support and Profile

Support files live under:

- `lib/features/support/`

Profile files live under:

- `lib/features/profile/`

Current coverage:

- Support tickets.
- Ticket detail.
- New support ticket.
- Profile view/edit.
- Password change.
- Terms.
- Trainer application.
- Account deletion entry point.

## 15. Zana and Business Tools

Zana files live under:

- `lib/features/zana/`

Current tools include:

- Business management.
- eBooks entry point.
- Insurance.
- POS.
- Kikoba.

Documentation rule:

- Zana tools should be documented separately from the core learning flow, especially where backend business-data APIs are involved.

## 16. Release Process

Release documentation lives in:

- `dev/Karakana-App-v2/docs/release.md`

Versioning format:

```text
major.minor.patch+build
```

Current example:

```text
2.1.0+38
```

Android release output:

```text
build/app/outputs/bundle/release/app-release.aab
```

iOS release is archived through:

```text
ios/Runner.xcworkspace
```

## 17. Documentation Gaps

Current gaps to close next:

- Add screenshots for major V2 flows.
- Add diagrams for auth, forced password change, payment checkout, and notifications.
- Add API request/response examples for critical screens.
- Add accessibility and localization review notes.
- Add widget/integration test strategy once test coverage expands.

## 18. Documentation Maintenance Rule

For every V2 mobile feature:

1. Update the relevant source docs in `dev/Karakana-App-v2/docs/`.
2. Confirm role-specific behavior for normal users and trainers.
3. Document API dependencies and missing fields.
4. Refresh this `documentation-by-jeho` baseline if stakeholder-facing docs are affected.
5. Export a new PDF only after the Markdown source is current.

