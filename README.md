# Karakana App V2

Karakana App V2 is the Flutter mobile app for the Kreative Karakana learning, eBook, trainer, wallet, support, and business-tool experience.

## Documentation

Start with the V2 documentation index:

- `docs/index.md`
- `docs/architecture.md`
- `docs/setup.md`
- `docs/flows.md`
- `docs/release.md`
- `docs/documentation-checklist.md`

These docs describe the current V2 implementation and should not be replaced with old V1 app documentation unless the behavior has been verified against this codebase.

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

## Working Standard

Follow `docs/karakana-workflow.md` for V2-only development, release tracking, verification, and secret-handling expectations.
