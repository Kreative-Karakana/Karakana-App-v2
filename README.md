# karakana_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

## Local Backend Testing

The app uses `https://beta.kreativekarakana.co.tz` by default. For local
backend testing, override the API base URL with a Dart define:

```sh
flutter run --dart-define=API_BASE_URL=http://localhost
```

For the Android emulator, use the host loopback alias instead:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2
```

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
