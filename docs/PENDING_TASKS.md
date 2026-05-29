# Karakana App V2 — Pending Tasks & Blockers

##  No Current Blockers

Both platforms are now deployed and being tested.

---

##  Active — TestFlight Testing (iOS)

Testing Karakana V2 on iPhone via TestFlight (Build 4+).
White screen bug fixed — app now launches and runs on iPhone.

**Test checklist:**
- Authentication (email, Google, biometric)
- Course browsing and enrollment
- IAP purchase flow (Vicoba na Maendeleo)
- Video playback
- Zana tab features
- Profile and edit profile
- Push notifications
- Dark mode
- Trainer dashboard

**After testing passes:**
1. Go to App Store Connect → Distribution
2. Create new version submission
3. Select the passing TestFlight build
4. Attach IAP product (com.kreativekarakana.karakana.course.vicoba)
5. Add review notes with test account credentials
6. Submit for Apple Review

---

##  Post-TestFlight — App Store Submission

When TestFlight testing passes:
1. App Store Connect → Distribution → Create new version
2. Select build → attach IAP → add review notes → submit

Review notes to include:
- Test account email and password
- "To test IAP, find Vicoba na Maendeleo course and tap Nunua Kozi"
- "Use sandbox Apple ID for IAP testing"

---

##  Post-Launch Tasks

### App Quality Roadmap
- Use `docs/APP_QUALITY_ROADMAP.md` as the living todo list for frontend/backend audit work, UI consistency, API logic review, testing, and release-readiness improvements.
- Update the roadmap after each relevant fix so discovered issues and completed work stay traceable.

### Courses
- Add remaining 18 courses with apple_iap_product_id values
- Format: com.kreativekarakana.karakana.course.{slug}

### Features
- Fursa page placeholder content (Instagram links in old task list)
- Mkoba wangu card gradient — match Zana card dark gradient
- Trainer video upload directly to Mux from app
- Drop shadow after next card in trainer kozi tab
- Trainer requests course deletion flow
- Sign in with Apple (required — app has Google Sign-In)

### UI Fixes (Trainer Dashboard)
- Fix missing trainer name in "Habari, !" greeting
- Fix "Rasimu" badge — should say "Inasubiri Ukaguzi" for pending_review courses
- Remove "Chapisha Sasa" button from pending_review courses
- Fix Ongeza Kozi subtitle text

---

##  Key Credentials & Files

### HoneyPot Location
C:\Users\victo\OneDrive\Documentos\Kreative Karakana\System Documentations\Tech Dept\HoneyPot\

### iOS Signing
- Certificate: ios_distribution_v2.p12 (password: Lawrence17)
- Profile: App_store_connect_distribution_profile_new.mobileprovision
- Profile UUID: 5f2b04b1-a388-46ca-8d3d-92f196819293
- Team ID: J3M8G9NBLH
- Bundle ID: com.kreativekarakana.karakana

### Android Signing
- Keystore: karakana-release.jks (password: Karakana@2026!)
- Key alias: karakana
- SHA-1: F0:CD:AF:2F:85:54:17:90:97:8B:28:7C:9C:DD:83:87:3A:07:B9:EC

### App Store Connect
- App ID: 6755680070
- IAP Product: com.kreativekarakana.karakana.course.vicoba
- IAP Status: Ready to Submit

### GitHub Secrets (V2 Repo)
- IOS_CERTIFICATE_BASE64: from certificate_base64_new.txt
- IOS_CERTIFICATE_PASSWORD: Lawrence17
- KEYCHAIN_PASSWORD: set
- IOS_PROVISIONING_PROFILE_BASE64: from profile_base64_new.txt
- IOS_PROVISIONING_PROFILE_UUID: 5f2b04b1-a388-46ca-8d3d-92f196819293
- APP_STORE_CONNECT_USERNAME: set
- APP_STORE_CONNECT_APP_PASSWORD: set

### Play Store
- Package: com.kreativekarakana.karakana
- Status: In Review
- Version: 2.0.1 (build 2)
