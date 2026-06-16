# Karakana V2 Release Process

> Reader note: This file is the operational checklist for preparing Android and iOS releases. Always confirm the current version/build number in `pubspec.yaml` before releasing.

## Versioning

Version is controlled in `pubspec.yaml`:

```text
version: major.minor.patch+build
```

Use:

- `major` for breaking or very large product changes.
- `minor` for meaningful feature updates.
- `patch` for small fixes.
- `build` for every store upload attempt.

Example:

```text
2.1.0+38
```

## Pre-Release Checks

```sh
flutter clean
flutter pub get
dart format .
flutter analyze
flutter test
```

Document any skipped command and why it was skipped.

## Android Release

Build the app bundle:

```sh
flutter build appbundle --release
```

Expected output:

```text
build/app/outputs/bundle/release/app-release.aab
```

Before upload:

- Confirm package name.
- Confirm signing config.
- Confirm version/build number.
- Confirm release notes.
- Upload the `.aab` to Google Play Console.

## iOS Release

Prepare dependencies:

```sh
flutter clean
flutter pub get
flutter analyze
cd ios
pod install
cd ..
open ios/Runner.xcworkspace
```

In Xcode:

1. Select `Runner`.
2. Confirm bundle identifier, signing team, version, and build number.
3. Select a generic iOS device target.
4. Run `Product > Archive`.
5. Use Organizer to distribute to App Store Connect.

## Release Notes

Release notes should be user-facing, concise, and written in Swahili for app-store users.

## Rollback

Mobile rollback usually means:

- Stop rollout or pause phased release in the store.
- Submit a fixed build with an incremented build number.
- Use backend feature flags or server-side mitigation where available.

Do not reuse the same build number for a corrected store upload.
