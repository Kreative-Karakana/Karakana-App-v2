# Karakana V2 Setup

> Reader note: This file is for developers preparing a local Karakana V2 environment. It intentionally avoids secrets and points to safe commands/settings only.

## Prerequisites

- Flutter SDK compatible with Dart `>=3.0.0 <4.0.0`.
- Android Studio and Android SDK for Android builds.
- Xcode and CocoaPods for iOS builds.
- Access to the Karakana backend environment used for development/testing.
- Firebase configuration files for push notifications.

## Install Dependencies

```sh
flutter pub get
```

For iOS:

```sh
cd ios
pod install
cd ..
```

## Environment Configuration

The app uses `AppConstants.baseUrl` and supports overriding the API base URL with a Dart define.

Default backend:

```text
https://beta.kreativekarakana.co.tz
```

Run against a local backend:

```sh
flutter run --dart-define=API_BASE_URL=http://localhost
```

Android emulator local backend:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2
```

## Secrets and Local Files

Do not commit:

- `android/key.properties`
- Keystores
- Certificates
- API secrets
- `local.properties`
- Private Firebase or Apple credentials

## Validation Commands

Use these commands before handing off a code change:

```sh
flutter analyze
dart format .
flutter test
```

If a command cannot be run locally, document the reason in the implementation notes.

## Platform Notes

- Android release builds generate an `.aab` for Google Play.
- iOS release builds should be archived from Xcode using `ios/Runner.xcworkspace`.
- Version and build number are controlled from `pubspec.yaml` with the format `major.minor.patch+build`.
