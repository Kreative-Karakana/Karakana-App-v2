# Android Release Guide

This project uses a Flutter Android build with a release signing config that reads `android/key.properties`.
Do not commit signing material.

## 1) `key.properties`

Create `android/key.properties` locally with values like:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=app/keystore/<release-keystore>.jks
```

Notes:
- `storeFile` is resolved relative to the `android/` directory in this project.
- Keep the keystore in a local-only path under `android/app/keystore/` or another private folder on your machine.
- The repository `.gitignore` excludes `android/key.properties`, `*.jks`, and `*.keystore`.

## 2) Keystore placement

Recommended local path:
- `android/app/keystore/<release-keystore>.jks`

Alternative:
- any secure local path referenced from `android/key.properties`

Do not commit the keystore file.

### Generate an upload keystore

Use `keytool` locally to create a new upload keystore:

```bash
keytool -genkeypair -v \
  -keystore android/app/keystore/<release-keystore>.jks \
  -alias <upload-alias> \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Choose strong passwords and store them only in `android/key.properties`.

## 3) Build APK

Debug APK:

```bash
flutter build apk --debug
```

Release APK:

```bash
flutter build apk --release
```

The release APK requires a valid keystore and `android/key.properties`.

## 4) Build AAB

Preferred production release path:

```text
.github/workflows/android-release.yml
```

The protected workflow creates `android/key.properties` and the decoded keystore only on the GitHub runner from production secrets, then removes them during cleanup.

Local fallback:

```bash
flutter build appbundle --release
```

This is the format required for Google Play Store release uploads.

## 5) What not to commit

Do not commit:
- `android/key.properties`
- any `*.jks` / `*.keystore`
- `android/local.properties`
- generated build outputs under `build/`
- CI signing secrets or decoded CI signing files

## 6) Firebase config cleanup to review

`android/app/google-services.json` currently contains the correct Android package entry:
- `com.kreativekarakana.karakana`

It also contains legacy typo entries:
- `com.kreativekarkana.karakana`

Recommended cleanup:
1. Verify in Firebase Console which Android app entry is authoritative.
2. Remove/retire any stale typo package registrations if they are no longer used.
3. Regenerate `google-services.json` from Firebase only after the console configuration is corrected.

Do not hand-edit Firebase JSON unless you are intentionally applying a verified config update from Firebase Console.

## 7) Release checklist

- `flutter clean`
- `flutter pub get`
- `flutter analyze`
- `flutter build apk --debug`
- `flutter build apk --release` only after signing is configured through the protected workflow or local-only signing files
- `flutter build appbundle --release` for Play Store submission
