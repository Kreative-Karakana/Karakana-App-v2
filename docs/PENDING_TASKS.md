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
4. Under Distribution Certificate → select the new certificate (created today)
5. Click Save → Download
6. Send the new .mobileprovision file to Kweka

**After receiving the file, Kweka must:**
1. Base64-encode it using PowerShell
2. Update IOS_PROVISIONING_PROFILE_BASE64 secret in GitHub V2 repo
3. Extract new UUID and update IOS_PROVISIONING_PROFILE_UUID secret
4. Re-run the ios-build-check workflow

**Impact:** GitHub Actions dry-run cannot proceed until this is resolved.
