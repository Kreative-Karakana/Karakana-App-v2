# Karakana V2 Flutter Testing

This document defines how automated tests are structured, written, and run for the Karakana V2 Flutter app. It covers unit and provider-level tests only; see `flows.md` for manual QA flows and `ci-cd.md` for how tests run in CI.

## Goals And Non-Goals

The test suite exists to catch regressions in business logic, state management, and API-shaping code without a running backend or device. It intentionally does **not** try to:

- Cover every screen with widget tests.
- Replace manual QA of full user journeys (see `docs/flows.md`).
- Exercise real network calls, platform channels (secure storage, biometrics, Firebase, Google/Apple sign-in), or the real backend.

Add tests as part of implementing a feature, not as a follow-up task — a provider or service change without a corresponding test update should be treated as incomplete.

## Where Tests Live

All tests live under `test/`, one file per feature/behavior, named `<feature>_<behavior>_test.dart`:

```text
test/
  auth_provider_test.dart
  business_edit_test.dart
  business_transaction_create_test.dart
  business_transaction_delete_test.dart
  business_transaction_edit_test.dart
  business_transaction_pagination_test.dart
  course_pagination_test.dart
  trainer_course_contract_test.dart
  trainer_course_filters_test.dart
  widget_test.dart
```

Prefer several small, single-purpose files over one large file per feature — it keeps fake setup local to the behavior under test and keeps failures easy to locate.

## What Gets Tested

In priority order, favor tests for:

1. **Pure business logic** — validation, payload building, status/label mapping (e.g. `lib/features/trainer/utils/course_contract.dart`, `lib/features/trainer/utils/trainer_course_filters.dart`). These need no mocking at all: call the function, assert the result.
2. **Providers (state management)** — pagination, filters, create/edit/delete flows, error handling, loading-state flags. This is the bulk of the suite today (`BusinessManagementProvider`, `CourseProvider`, `AuthProvider`).
3. **Model/service parsing** — `fromJson` factories and paginated-response wrappers (e.g. `PaginatedCourses.fromJson`, `BusinessDashboardSummary.fromJson`), especially where the backend response shape has previously changed or has optional/nullable fields.
4. **Widget tests** — added only when a screen has meaningful conditional logic in its `build` method that isn't already covered by testing the provider it reads from. `widget_test.dart` is currently a placeholder; do not treat it as a template to copy.

## Testing Convention: Constructor-Injected Services

Every provider that talks to the network takes its service as an optional named constructor argument, defaulting to the real implementation:

```dart
class BusinessManagementProvider extends ChangeNotifier {
  BusinessManagementProvider({BusinessManagementApi? service})
      : _service = service ?? BusinessManagementService();

  final BusinessManagementApi _service;
  ...
}
```

The service itself is defined as an abstract interface (`BusinessManagementApi`, `CourseCatalogService`, `AuthApi`) with a concrete implementation that wraps `ApiClient().dio`. Production code always uses the default (no test-only code paths ship in `lib/`); tests pass a fake implementation of the interface instead.

This is the only mocking approach used in this codebase — no mocking framework (`mockito`/`mocktail`) is installed or required. Hand-written fakes are preferred because:

- They keep test intent readable (a fake with a `Map<Request, Response>` fixture reads like a spec).
- They avoid codegen (`build_runner`) in the test loop.
- They compile-check against the interface, so an interface change that isn't reflected in production code fails at the call site, not silently.

If a provider currently calls a network/platform dependency directly (no injected interface), and you need to test it, extract the dependency behind an interface the same way — see `lib/features/auth/services/auth_service.dart` (`AuthApi`) and `lib/features/auth/services/auth_session_store.dart` (`AuthSessionStore`, which `SecureStorage` implements) for the pattern applied to a provider that previously called `ApiClient().dio` and `SecureStorage()` directly.

### Anatomy of a fake service

```dart
class _FakeCourseService implements CourseCatalogService {
  _FakeCourseService(this.pages);

  final Map<_PageRequest, PaginatedCourses> pages;
  final List<_PageRequest> requests = [];
  final Set<_PageRequest> _failOnce = {};

  void failOnceFor(_PageRequest request) => _failOnce.add(request);

  @override
  Future<PaginatedCourses> getCoursesPage({...}) async {
    final request = _PageRequest(...);
    requests.add(request);
    if (_failOnce.remove(request)) throw Exception('Network failed');
    final response = pages[request];
    if (response == null) throw StateError('Unexpected request: $request');
    return response;
  }

  // Every other interface method throws UnimplementedError() unless the
  // test under it actually exercises that call.
  @override
  Future<List<BannerModel>> getBanners() => throw UnimplementedError();
  ...
}
```

Conventions worth keeping:

- Record every call the provider makes (`requests`/`updateCalls`/`createCalls`) so assertions can check *what* was sent, not just the resulting state — this is what catches a provider silently dropping a filter or sending the wrong page number.
- Use a value-equatable request key (like `_PageRequest` above, with `==`/`hashCode`/`toString`) keyed to a `Map` of canned responses, so each test only wires up the exact requests it expects and any unexpected call fails loudly (`StateError: Unexpected request`) instead of returning null/garbage.
- Implement every interface method (throwing `UnimplementedError()` for the ones a given test doesn't use) rather than making the fake `implements` a subset — this keeps the fake in sync with the real interface at compile time.
- To test a failure path, throw a real `DioException` with a realistic `response.data` shape so `ApiClient().parseError()` (the actual production error-mapping code) runs unmodified — do not hand-roll a fake error string.

### Session/storage fakes

`AuthSessionStore` fakes should be simple in-memory field holders (see `test/auth_provider_test.dart`) — no need for the request-log pattern above, since session storage has no filters/pagination to get wrong, just state to inspect after the fact (`storage.token`, `storage.cleared`, etc).

## Running Tests Locally

```sh
flutter pub get
flutter test                     # whole suite
flutter test test/auth_provider_test.dart   # a single file
flutter analyze                  # static analysis, run alongside tests
dart format --set-exit-if-changed .          # formatting, same check CI runs
```

All four commands must pass before opening a PR — they are exactly what `flutter-ci.yml` runs (see `docs/ci-cd.md`).

## CI Integration

Tests run automatically on every pull request targeting `main` via `.github/workflows/flutter-ci.yml`, with no additional setup required — the suite has no external dependencies (no backend, no emulator/simulator, no platform channels), so it runs the same way locally and on the `ubuntu-24.04` CI runner. See `docs/ci-cd.md` for the full workflow list and required status checks.
