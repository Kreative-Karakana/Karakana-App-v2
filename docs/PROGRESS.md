# Karakana App V2 — Progress Summary
**Last updated:** 2026-05-17

## App Overview
Flutter rebuild of Karakana mobile app targeting both
Google Play Store and Apple App Store.

## Current State
- Android build submitted to Play Store and currently in review.
- iOS build uploaded to TestFlight and active testing is in progress.
- iPhone white screen launch issue has been fixed.

## iOS Release Readiness
- Bundle ID: `com.kreativekarakana.karakana`
- Team ID: `J3M8G9NBLH`
- Provisioning Profile UUID: `5f2b04b1-a388-46ca-8d3d-92f196819293`
- Runner entitlements aligned for push notifications + Sign in with Apple.
- Apple Pay entitlement removed (StoreKit IAP does not require it).
- `Info.plist` includes `ITSAppUsesNonExemptEncryption=false`.
- GitHub Actions workflows updated for Xcode selection and iOS 26 SDK requirement.
- iOS release workflow sets build number from GitHub run number.

## Payments & IAP
- Apple IAP integrated in V2 with `in_app_purchase`.
- IAP service/provider wired into course purchase flow on iOS.
- Product currently configured:
  - `com.kreativekarakana.karakana.course.vicoba`

## Active QA Scope (TestFlight)
- Authentication (email, Google, biometric)
- Course browse/enroll flow
- Apple IAP purchase flow
- Video playback
- Zana features
- Profile/edit profile
- Push notifications
- Dark mode
- Trainer dashboard

## Next Milestone
Once TestFlight passes:
1. Create App Store version in App Store Connect.
2. Select approved build.
3. Attach IAP product.
4. Add review notes with test credentials.
5. Submit for Apple Review.

## Play Store Status
- Package: `com.kreativekarakana.karakana`
- Status: In Review
- Version: `2.0.1+2`
