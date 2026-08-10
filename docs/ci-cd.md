# Karakana V2 Flutter CI/CD

This document defines the automated validation and release workflow for the Karakana V2 Flutter app.

## Flutter Version Policy

CI uses a pinned Flutter SDK for reproducible builds:

```text
Flutter 3.44.0
Dart 3.12.0
```

Do not change the workflow Flutter version casually. When the team upgrades Flutter locally, update the workflows and this document in the same PR after validating Android and iOS builds.

## Workflow Overview

The repository uses five GitHub Actions workflows:

- `.github/workflows/flutter-ci.yml`
- `.github/workflows/flutter-build-validation.yml`
- `.github/workflows/ios-build-validation.yml`
- `.github/workflows/android-release.yml`
- `.github/workflows/ios-release.yml`

`flutter-ci.yml` is the pull request quality gate. It is intentionally fast and must not require production signing secrets.

`flutter-build-validation.yml` validates that merged `main` branch code still builds for Android without requiring production signing secrets.

`ios-build-validation.yml` validates iOS when native iOS files or Flutter dependency manifests change, runs nightly as a safety net, and supports manual validation. It does not require production signing secrets.

`android-release.yml` and `ios-release.yml` are manual production release workflows. They should be protected with the GitHub `production` environment so signing credentials are available only after the required approval process.

## Pull Request Quality Gate

`flutter-ci.yml` runs on pull requests targeting `main`.

The quality job runs in fail-fast order:

```sh
dart format --set-exit-if-changed .
flutter pub get
flutter analyze
flutter test
```

This workflow is the required pre-merge feedback loop for developers. Configure branch protection so the `Format, analyze, and test` status check from `Flutter CI` is required before merging into `main`.

## Main Branch Android Build Validation

`flutter-build-validation.yml` runs on pushes to `main` and can also be started manually with `workflow_dispatch`.

The build job runs:

```sh
flutter build apk --debug
```

This job validates merged production code without slowing down every pull request. Build failures on `main` should be treated as release-blocking until fixed.

## Risk-Based iOS Build Validation

`ios-build-validation.yml` runs on pushes to `main` when `ios/**`, `pubspec.yaml`, `pubspec.lock`, Flutter project metadata, or the iOS workflow definitions change. It also runs every night at 02:17 UTC and can be started manually.

The validation build runs:

```sh
flutter build ios --release --no-codesign
```

This targeted-plus-nightly strategy retains iOS compilation coverage without paying for a macOS runner after every unrelated merge.

## Android Release Workflow

`android-release.yml` is manually triggered with a `version_name` input. The GitHub run number is used as the Android build number.

The workflow rejects dispatches from refs other than `main`, `release/*` branches, and release tags before accessing the protected production environment.

The workflow runs the same quality checks as CI, configures signing from GitHub secrets, builds:

```sh
flutter build apk --release
flutter build appbundle --release
```

The `.aab` artifact is the Play Store upload artifact. The `.apk` is retained for release validation and device testing.

Required production secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

The workflow writes `android/key.properties` and the decoded keystore only on the GitHub runner, then removes them in a cleanup step. Do not commit these files.

## iOS Release Workflow

`ios-release.yml` is manually triggered with a `version_name` input. The GitHub run number is used as the iOS build number.

The workflow rejects dispatches from refs other than `main`, `release/*` branches, and release tags before accessing the protected production environment.

The workflow installs dependencies, imports signing material into a temporary keychain, compiles the app once while creating the signed Xcode archive, exports an IPA, and uploads it to App Store Connect.

Required production secrets:

- `IOS_CERTIFICATE_BASE64`
- `IOS_CERTIFICATE_PASSWORD`
- `KEYCHAIN_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `IOS_PROVISIONING_PROFILE_UUID`
- `APP_STORE_CONNECT_USERNAME`
- `APP_STORE_CONNECT_APP_PASSWORD`

Certificates and provisioning profiles are decoded only on the GitHub runner and must never be committed or printed.

## Versioning And Build Numbers

The app version is declared in `pubspec.yaml`:

```text
version: major.minor.patch+build
```

For manual release workflows:

- `version_name` controls the store-visible version.
- `github.run_number` controls the build number.
- Each store upload attempt must use a unique build number.

Before starting a release, confirm that `pubspec.yaml`, release notes, and the workflow input agree on the intended version.

## Store Preparation

Before Play Store preparation:

- Confirm package name `com.kreativekarakana.karakana`.
- Confirm the release `.aab` was generated by the protected Android release workflow.
- Confirm release notes are user-facing and written in Swahili.
- Upload the `.aab` manually to Play Console unless a future issue explicitly automates submission.

Before TestFlight preparation:

- Confirm bundle identifier `com.kreativekarakana.karakana`.
- Confirm the protected iOS release workflow uploaded the IPA to App Store Connect.
- Confirm the App Store Connect build number matches the workflow run number.
- Add TestFlight notes manually unless a future issue explicitly automates them.

## Security Requirements

- Workflow permissions must use least privilege. Current workflows use `contents: read`.
- Do not print secret values in logs.
- Do not commit signing files, certificates, keystores, API credentials, or generated local properties.
- Keep release workflows bound to the protected `production` environment.
- Do not run signed release workflows for untrusted pull requests.
