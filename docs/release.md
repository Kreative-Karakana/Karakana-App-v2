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

Protected release workflows also accept a `version_name` input. The workflow run number is used as the store build number for Android and iOS release artifacts. Do not reuse a build number for a corrected upload.

## Pre-Release Checks

```sh
flutter clean
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Document any skipped command and why it was skipped.

Pull requests and protected-branch pushes are validated by `.github/workflows/flutter-ci.yml`. See `docs/ci-cd.md` for the full CI/CD policy, pinned Flutter version, required secrets, and protected release workflow details.

## Android Release

Use the protected manual workflow:

```text
.github/workflows/android-release.yml
```

The workflow builds both a release APK and Play Store app bundle:

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

Use the protected manual workflow:

```text
.github/workflows/ios-release.yml
```

The workflow builds and exports an IPA, then uploads it to App Store Connect. Use Xcode manual archive only as a fallback when the protected workflow is unavailable, and document the reason.

## Release Notes

Release notes should be user-facing, concise, and written in Swahili for app-store users.

## Rollback

Mobile rollback usually means:

- Stop rollout or pause phased release in the store.
- Submit a fixed build with an incremented build number.
- Use backend feature flags or server-side mitigation where available.

Do not reuse the same build number for a corrected store upload.
