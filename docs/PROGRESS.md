# Karakana App V2 — Progress Summary
**Last updated:** 2026-05-16

## App Overview
Flutter rebuild of Karakana mobile app targeting both
Google Play Store and Apple App Store.

## Screens Complete (47 total)
- Auth: login, signup, verify email, forgot password, biometric
- Courses: explore, course detail, classroom, video lesson,
  course complete, course reviews, my courses, wishlist, course list
- eBooks: ebook store, ebook library, ebook detail,
  secure reader, trainer ebooks, add/edit ebook
- Fursa: fursa screen (placeholder content pending)
- Home: home screen, main screen
- Notifications: notifications screen
- Onboarding: onboarding screen
- Payments: payment screen, payment history,
  payment success, wallet
- Profile: account, edit profile, mastercard form,
  profile screen, terms, trainer application
- Splash: splash screen
- Support: support, new ticket, ticket detail
- Trainer: course builder, lesson manager, quiz manager,
  student progress, trainer dashboard
- Zana: zana screen, biz manager, ebooks, insurance, kikoba, pos

## Key Integrations
- AzamPay/EVPay: Android payment flow (tested and working)
- Apple IAP: iOS payment flow (implemented, pending TestFlight test)
- Firebase FCM: Push notifications
- Google Sign-In: Authentication
- Sign in with Apple: Authentication
- Mux: Video streaming
- GoRouter: Navigation

## Deployment Status
| Platform | Status | Blocker |
|---|---|---|
| App Store (iOS) | Waiting for dry-run | Provisioning profile (Lameck) |
| Play Store (Android) | Ready to submit | None |

## GitHub Actions Workflows
| Workflow | Trigger | Purpose |
|---|---|---|
| ios-build-check.yml | Manual | Dry-run build validation |
| ios-release.yml | Manual | Build + upload to App Store Connect |