# Karakana App Quality Roadmap

**Last updated:** 2026-05-29
**Purpose:** Living todo list for improving frontend quality, backend/API logic, release readiness, and long-term maintainability.

## How We Use This List

- Update this file whenever we discover, fix, or reprioritize app issues.
- Keep completed items checked with the commit or note that resolved them when useful.
- Add new issues under the relevant section instead of tracking them only in chat.
- Use this roadmap before release builds so repeated UI/backend inconsistencies are not missed.

## Active Priority

- [ ] Run a full app codebase quality audit.
- [ ] Convert audit findings into grouped frontend, backend/API, state, navigation, performance, and release tasks.
- [ ] Fix high-impact user-facing bugs first, especially issues visible during onboarding, course playback, purchases, and profile/account flows.
- [ ] Keep GitHub commits detailed so each fix explains the problem, approach, and verification.

## For Testing

Use this list as the QA queue. We are building and fixing now; later we will test these items one by one and check them off only after device/API verification.

- [ ] Login screen remains intact when the keyboard opens.
- [ ] Registration screen remains intact when the keyboard opens.
- [ ] Tafuta navbar backdrop matches the transparent/smooth home navbar.
- [ ] Classroom landscape video opens fullscreen with nothing blocking it.
- [ ] Classroom progress area no longer shows the unintended loader.
- [ ] Trainer Akaunti page matches the improved student Akaunti UI.
- [ ] Trainer Akaunti page no longer shows `Historia ya Malipo`.
- [ ] Trainer course publish action sends course to `pending_review`, not directly to production.
- [ ] Edited trainer course content is submitted for Kreative Karakana review before students see it.
- [ ] New sections and lessons show Swahili review messaging and stay under review until approved.
- [ ] Trainer course deletion opens a Swahili request popup instead of deleting immediately.
- [ ] Trainer course deletion request reaches the backend admin review section.
- [ ] Backend admin can approve a course deletion request and delete the course.
- [ ] Backend admin can reject a course deletion request without deleting the course.
- [ ] Profile, classroom, and notifications `ListTile` Material assertions no longer appear.

## Full App Codebase Quality Audit

Goal: review the whole Flutter app against consistent industry-standard patterns for UI, state, API logic, responsiveness, accessibility, performance, and release safety.

### Audit Checklist

- [ ] Define the app standards we expect every feature to follow.
- [ ] Review screen structure across login, registration, home, tafuta/search, course detail, classroom, profile, account, trainer dashboard, and purchase flows.
- [ ] Identify screens using fragile layout patterns such as unnecessary `FittedBox`, hardcoded heights, unsafe keyboard handling, nested scroll conflicts, or inconsistent safe-area behavior.
- [ ] Check every primary screen in small phone, large phone, tablet, portrait, landscape, keyboard-open, loading, empty, error, and offline states.
- [ ] Review navigation behavior for back button handling, deep links, route guards, auth redirects, and post-login redirects.
- [ ] Review provider/state ownership so loading, errors, refreshes, and cached data are handled consistently.
- [ ] Review API services for consistent request logging, token handling, retries, response parsing, pagination, and error mapping.
- [ ] Review forms for validation, keyboard type, autofill hints, password visibility, disabled states, and submit behavior.
- [ ] Review media/video playback for orientation, fullscreen behavior, controls, progress tracking, and resume states.
- [ ] Review purchase flows for platform-specific behavior, failure handling, receipt state, and user messaging.
- [ ] Review accessibility basics: tap target size, text scaling, semantic labels, contrast, and screen-reader labels for icon-only controls.
- [ ] Review performance hotspots: expensive rebuilds, uncached network images, list rendering, video resources, and startup work.
- [ ] Review release configuration for Android/iOS versioning, signing, permissions, entitlements, app icons, splash, and CI/CD behavior.
- [ ] Produce a prioritized audit report with severity, affected files/screens, recommended fix, and verification plan.

## Frontend Roadmap

### Layout and Responsiveness

- [x] Fix login keyboard-open layout so the screen remains intact and scrollable.
- [x] Fix registration keyboard-open layout with the same stable behavior as login.
- [x] Match Tafuta navbar backdrop behavior to the transparent home navbar.
- [x] Fix classroom landscape video so fullscreen playback is unobstructed.
- [x] Remove unintended loading animation from classroom progress area.
- [x] Refine signup screen spacing and density.
- [x] Tighten profile/account header spacing.
- [x] Align trainer account page UI with the improved student account page.
- [x] Require trainer course publishing and edited course content to go through Kreative Karakana review.
- [x] Add trainer course deletion request flow with backend team approval.
- [ ] Audit every screen for keyboard-open behavior.
- [ ] Audit every screen for safe-area and bottom navigation spacing.
- [ ] Audit every screen for portrait/landscape layout failures.
- [ ] Standardize repeated screen shells, page padding, loading states, empty states, and error states.

### Component Consistency

- [x] Fix profile menu `ListTile` Material assertion.
- [x] Fix classroom lesson `ListTile` Material assertion.
- [x] Fix notifications unread row `ListTile` Material assertion.
- [ ] Create or document standard patterns for cards, list rows, buttons, form fields, app bars, and bottom nav surfaces.
- [ ] Replace one-off fragile widgets with shared components where duplication causes inconsistent behavior.
- [ ] Review icon buttons and tappable controls for clear hit areas and disabled/loading states.

### Visual QA

- [ ] Build a screenshot checklist for the main app flows.
- [ ] Add screenshot references for known issues under the work-week folders to the relevant roadmap items.
- [ ] Compare auth, home, tafuta, classroom, profile, and trainer flows across devices before each release build.

## Backend and API Logic Roadmap

### Authentication and Account

- [ ] Review email/password login, Google login, Apple login, biometric login, logout, and token refresh behavior.
- [ ] Standardize auth errors so user-facing messages are clear and consistent.
- [ ] Confirm role-based redirects for students, trainers, ambassadors, and admins.
- [ ] Review profile fetch/update flows for loading, error, retry, and cached state behavior.

### Courses and Classroom

- [ ] Review course detail loading, section loading, lesson progress, reviews, enrollment, and owned-course states.
- [ ] Confirm progress calculations and displayed lesson counts are consistent with API responses.
- [ ] Review classroom state refresh after video completion, lesson navigation, and app resume.

### Purchases

- [ ] Review iOS in-app purchase flow for product loading, purchase start, success, cancellation, failure, restore, and backend confirmation.
- [ ] Review Android purchase behavior if applicable.
- [ ] Confirm purchase UI never leaves users stuck in loading states.

### Communications

- [ ] Review banners, notifications, unread state, and failure handling.
- [ ] Confirm communication API errors do not break primary app navigation.

## State, Navigation, and Architecture

- [ ] Map current feature folders, providers, models, services, and widgets.
- [ ] Identify duplicated API calls and duplicated loading/error state handling.
- [ ] Standardize when screens fetch data and when providers cache or refresh data.
- [ ] Review route definitions, guarded routes, and navigation after auth state changes.
- [ ] Document recommended patterns for adding new screens and services.

## Testing and Verification

- [ ] Keep running `flutter analyze` after code changes.
- [ ] Add focused widget tests for auth forms and critical shared components.
- [ ] Add integration tests for login, course viewing, purchase entry points, and profile flows.
- [ ] Add manual QA checklist for TestFlight/App Store release builds.
- [ ] Track any known analyzer warnings or plugin warnings that should become release blockers later.

## Release Readiness

- [x] Bump iOS release build number after Apple Store Connect build 32.
- [ ] Keep CI/CD versioning aligned with Apple Store Connect and Play Console.
- [ ] Verify signing, entitlements, app permissions, and store metadata before each release.
- [ ] Confirm TestFlight build passes the active QA scope before App Store submission.

## Parking Lot

- [ ] Fursa page placeholder content.
- [ ] Mkoba wangu card gradient should match Zana card dark gradient.
- [ ] Trainer video upload directly to Mux from app.
- [x] Trainer requests course deletion flow.
- [ ] Trainer dashboard text and badge polish from pending tasks.
