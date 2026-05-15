# Apple First-Submission Execution Checklist (Karakana App)

Purpose: pass App Review on first submission by verifying policy-critical areas with evidence.

How to use:
1. Execute each check in order.
2. Mark status as `PASS`, `FAIL`, or `BLOCKED`.
3. Attach proof (screenshot, video, log line, or file reference).

## 1) Build & Version Gate
- Check: iOS build/version is incremented for new submission.
- Why: App Store rejects duplicate build numbers.
- Execute:
1. Open `pubspec.yaml` and confirm `version` is higher than last submitted build.
2. In App Store Connect, confirm the last processed build number.
3. Ensure new build number (`+X`) is strictly greater before archive.
- Pass criteria:
1. New build number is unique and higher than previous App Store Connect build.
- Fail examples:
1. Same build number as previous submission.
2. Version changed but build number not incremented.
- Status: IN PROGRESS (version bumped to `1.0.20+28`; pending App Store Connect check)
- Evidence:

## 2) Sign in with Apple Compliance
- Check: Sign in with Apple is present and works whenever third-party login is present.
- Why: Required by Apple when social login is offered.
- Current code signal: Apple sign-in action exists in `lib/custom_code/actions/apple_sign_in_with_token.dart` and login wiring exists in `lib/pages/auth/login/login_widget.dart`.
- Execute:
1. Install TestFlight/release build on real iPhone.
2. Open login screen and confirm Apple sign-in button is visible.
3. Tap Apple sign-in and complete auth with a test Apple ID.
4. Verify user lands inside authenticated app session.
5. Logout and repeat once to confirm idempotent behavior.
- Pass criteria:
1. Apple sign-in button is present where other social login exists.
2. Auth succeeds end-to-end without crash.
3. Re-login works on second attempt.
- Fail examples:
1. Apple button hidden on iOS while Google is shown.
2. Apple sign-in opens then returns to login with no session.
- Status: TODO
- Evidence:

## 3) Account Deletion In-App
- Check: User can delete account from inside app without contacting support externally.
- Why: Apple requires in-app account deletion capability.
- Current code signal: Delete account flow exists in `lib/pages/main/account/account_widget.dart` and endpoint call in `lib/backend/api_requests/api_calls.dart` (`/accounts/me/delete/`).
- Execute:
1. Login with dedicated test account.
2. Navigate to Account screen and locate delete-account action.
3. Trigger deletion and confirm warning dialog copy is clear.
4. Confirm deletion completes (success message + forced logout or blocked re-login).
5. Attempt login again with deleted account.
- Pass criteria:
1. Deletion can be initiated and completed fully inside app.
2. Post-delete behavior proves account is removed/deactivated as designed.
- Fail examples:
1. App redirects user to website/email to delete.
2. Delete button exists but API fails consistently.
- Status: TODO
- Evidence:

## 4) Digital Payments Policy (IAP for iOS)
- Check: Paid digital course purchases on iOS use Apple IAP, not external checkout.
- Why: Apple requires IAP for digital content consumed in app.
- Current code signal: IAP service exists in `lib/services/iap_service.dart`; course detail uses iOS/IAP logic in `lib/pages/course/course_details/course_details_widget.dart`.
- Execute:
1. On iPhone, open a paid digital course detail.
2. Tap purchase CTA and confirm Apple IAP sheet appears.
3. Complete a sandbox purchase and verify backend verification succeeds.
4. Confirm user gets course access after purchase.
- Pass criteria:
1. iOS purchase path uses Apple purchase sheet only.
2. Access is granted after successful Apple transaction verification.
- Fail examples:
1. iOS opens external web checkout for digital course.
2. Apple purchase succeeds but backend verification fails and access is not granted.
- Status: TODO
- Evidence:

## 5) External Payment Surface Isolation
- Check: iOS build does not expose external payment CTA for digital content paths.
- Why: Even with IAP present, external purchase paths can trigger rejection.
- Execute:
1. Search iOS app screens that sell digital content (course details, checkout, promos).
2. Verify no button/link opens external web/mobile-money checkout for those digital items.
3. Verify only IAP CTA is displayed for paid digital courses.
- Pass criteria:
1. No external checkout option is visible for digital content purchases on iOS.
- Fail examples:
1. “Pay with mobile money” appears on iOS course purchase flow.
2. Hidden deeplink/route still opens external checkout from digital content page.
- Status: TODO
- Evidence:

## 6) Privacy Policy & Terms Accessibility
- Check: Privacy Policy and Terms are reachable in-app and consistent with App Store Connect metadata.
- Why: Reviewers verify policy links and content accessibility.
- Current code signal: Terms/Privacy screen exists in `lib/pages/auth/terms_and_conditions/terms_and_conditions_widget.dart`.
- Status: TODO
- Evidence:

## 7) Info.plist Permission Strings
- Check: Every requested permission has clear user-facing purpose text.
- Why: Vague text can trigger rejection.
- Current code signal: `ios/Runner/Info.plist` includes camera and photo library usage descriptions.
- Status: TODO
- Evidence:

## 8) App Privacy Declaration Alignment
- Check: Data collection in app matches App Store Connect privacy answers.
- Why: Mismatch leads to rejection and follow-up questions.
- Current code signal: Firebase Analytics/Messaging/Performance are included in `pubspec.yaml`.
- Status: TODO
- Evidence:

## 9) Real Device Functional Sweep (iPhone + iPad)
- Check: Run full smoke flow on both form factors.
- Why: Apple reviews on iPad frequently; layout/flow issues can reject build.
- Required flows:
  - Signup/Login
  - Sign in with Apple
  - Google sign-in (if enabled)
  - Paid course purchase via IAP (iOS)
  - Account deletion
- Status: TODO
- Evidence:

## 10) Reviewer Access Package
- Check: App Review notes include test account, OTP guidance, and exact test steps.
- Why: Missing reviewer instructions is a common avoidable rejection.
- Status: TODO
- Evidence:

## 11) Final Submission Readiness Gate
- Check: No `FAIL` items remain.
- Why: Prevent avoidable rejection on first submission.
- Status: TODO
- Evidence:

---

## Evidence Template (Use For Every Item)
- Date/Time:
- Device:
- Build:
- Step executed:
- Result: PASS/FAIL/BLOCKED
- Notes:
- Screenshot/Video file:
