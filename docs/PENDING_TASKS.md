# Karakana App V2 — Pending Tasks & Blockers

##  BLOCKER — iOS Provisioning Profile Regeneration
**Status:** Waiting for Lameck
**Date identified:** 2026-05-16

**What needs to be done:**
Lameck needs to log into developer.apple.com and regenerate the
App Store Distribution provisioning profile to include the new
Apple Distribution certificate created on his Mac today.

**Steps for Lameck:**
1. Go to developer.apple.com → Certificates, Identifiers & Profiles → Profiles
2. Find "App store connect distribution profile"
3. Click Edit
4. Under Distribution Certificate → select the new certificate (created today, May 16 2026)
5. Click Save → Download
6. Send the new .mobileprovision file to Kweka

**After receiving the file, Kweka must:**
1. Run in PowerShell:
   [Convert]::ToBase64String(
     [IO.File]::ReadAllBytes("PATH_TO_NEW_FILE.mobileprovision")
   ) | Out-File -FilePath "profile_base64_new.txt" -NoNewline
2. Extract UUID:
   $content = Get-Content -Path "PATH_TO_NEW_FILE.mobileprovision" -Raw
   $match = [regex]::Match($content, '<key>UUID</key>\s*<string>(.*?)</string>')
   Write-Output "UUID: $($match.Groups[1].Value)"
3. Update IOS_PROVISIONING_PROFILE_BASE64 secret in GitHub V2 repo
4. Update IOS_PROVISIONING_PROFILE_UUID secret in GitHub V2 repo
5. Re-run ios-build-check workflow
6. If dry-run passes → run ios-release workflow

**Impact:** GitHub Actions dry-run and App Store upload blocked until resolved.

---

##  Post-Launch Tasks (safe to do after App Store approval)

### #1 — Fursa Page Placeholder Content
Populate fursa_screen.dart with placeholder content from these posts:
- https://www.instagram.com/p/DYUvXbhiuez/
- https://www.instagram.com/p/DXmaQciAC2k/
- https://www.instagram.com/p/DX_4b0IiMUh/
- https://www.instagram.com/p/DX9KewwCEyQ/
- https://instagram.com/p/DYUY3cMDI7s/
- https://www.instagram.com/p/DYMUdfOjJKt/

### #3 — Mkoba Wangu Card Gradient
Trainer's mkoba wangu card gradient should match the Zana card
gradient on the student home screen.

### #4 — Trainer Video Upload to Mux
Allow trainers to upload video directly from the app and have it
go straight to Mux for processing.

### #7 — Drop Shadow on Kozi Tab
Add a drop shadow after the next card in the kozi tab of trainer UI.

### #8 — Trainer Requests Course Deletion
Trainer should be able to request course deletion from within the
app — request goes to Kreative Karakana team for approval.

---

##  Completed Today (2026-05-16)

### Code Fixes
- Fixed phone number key mismatch in trainer application screen
- Added Tanzania phone number validation in edit profile screen
- Added pass indicator at 80% completion in classroom screen
- Confirmed certificate logic correct at 100% completion
- Trainer content now routed through pending_review before publishing
- Added content type chooser popup for Ongeza Kozi/Kitabu button
- Merged POS into Usimamizi wa Biashara
- Rearranged Zana cards: Usimamizi wa Biashara, Akiba ya Kikundi,
  Maktaba ya Kidijitali, Bima ya Biashara

### Apple IAP Implementation
- in_app_purchase: ^3.2.0 added to pubspec.yaml
- IAPService created at lib/features/payments/services/iap_service.dart
- IAPProvider created at lib/features/payments/providers/iap_provider.dart
- IAPProvider registered in main.dart
- Platform branching wired into course_detail_screen.dart
- appleIapProductId field added to CourseModel
- Runner.entitlements created with IAP, push notifications,
  and Sign in with Apple capabilities
- CODE_SIGN_ENTITLEMENTS set in Debug and Release build settings

### iOS Deployment Setup
- Bundle ID fixed to com.kreativekarakana.karakana
- ios/ExportOptions.plist created
- .github/workflows/ios-build-check.yml created
- .github/workflows/ios-release.yml created
- All 7 GitHub Secrets added to V2 repo

### App Store Connect
- IAP Product ID registered:
  com.kreativekarakana.karakana.course.vicoba
- Status: Ready to Submit
- Django Admin: apple_iap_product_id set on Vicoba na Maendeleo

### Play Store
- Pending — no blockers, can be done independently

---