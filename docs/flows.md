# Karakana V2 Product Flows

> Reader note: This file summarizes user-facing and trainer-facing app flows. It should be updated whenever screens, routes, permissions, payments, or notifications change.

## Auth and Onboarding

Relevant files:

- `lib/features/splash/screens/splash_screen.dart`
- `lib/features/onboarding/screens/onboarding_screen.dart`
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/auth/screens/signup_screen.dart`
- `lib/features/auth/screens/verify_email_screen.dart`
- `lib/features/auth/screens/forgot_password_screen.dart`
- `lib/features/auth/screens/biometric_screen.dart`
- `lib/features/auth/providers/auth_provider.dart`

Flow summary:

1. Splash initializes local onboarding/session state.
2. Users complete onboarding before protected routes.
3. Users log in with email/password or supported social providers.
4. Signup requires email verification.
5. Device token registration is attempted during login/verification for push notifications.
6. Trainers with forced password change are routed to `/profile/change-password` before proceeding.

## Navigation

`go_router` controls all app routes in `lib/core/router/app_router.dart`.

Normal users land on `/home`. Trainers land on `/trainer/dashboard`. Public Zana/Fursa routes are allowed without auth where configured.

## Courses

Relevant screens:

- Course discovery/listing: `course_list_screen.dart`, `explore_screen.dart`
- Detail: `course_detail_screen.dart`
- Learning: `classroom_screen.dart`, `video_lesson_screen.dart`
- Completion: `course_complete_screen.dart`
- Reviews: `course_reviews_screen.dart`
- Saved courses: `wishlist_screen.dart`
- Owned courses: `my_courses_screen.dart`

Expected documentation behavior:

- Course access rules should distinguish free, paid, enrolled, and completed states.
- Payment requirements should be documented before changing course access.
- Certificate generation uses `certificate_pdf_generator.dart`.

## eBooks

Relevant screens:

- Store: `ebook_store_screen.dart`
- Detail: `ebook_detail_screen.dart`
- Library: `ebook_library_screen.dart`
- Reader: `secure_ebook_reader_screen.dart`
- Trainer management: `trainer_ebooks_screen.dart`, `trainer_ebook_detail_screen.dart`, `add_edit_ebook_screen.dart`

Expected behavior:

- Published eBooks appear in the store.
- Purchased or free eBooks appear in the library.
- Reader access should require ownership/access confirmation.
- Trainer destructive actions should eventually use a staff-reviewed operations queue.

## Payments, Wallet, and Transactions

Relevant screens:

- `payment_screen.dart`
- `payment_success_screen.dart`
- `payment_history_screen.dart`
- `wallet_screen.dart`

Expected behavior:

- Checkout should create/track a payment reference.
- User transaction history should show amount, date, method/type, status, and related course/eBook context where available.
- Wallet and trainer earnings/withdrawals are separate concerns and should not leak trainer language into normal-user transaction screens.

## Trainer Flows

Relevant screens:

- Dashboard: `trainer_dashboard_screen.dart`
- Account: `trainer_account_screen.dart`
- Courses: `trainer_courses_list_screen.dart`, `course_builder_screen.dart`
- Lessons: `lesson_manager_screen.dart`
- Quizzes: `quiz_manager_screen.dart`
- Students: `student_progress_screen.dart`
- Trainer application: `trainer_application_screen.dart`

Expected behavior:

- Trainers should receive role-specific dashboards and notifications.
- Imported trainers may be forced to change password after first login.
- Trainer course/eBook deletion should move toward staff approval before becoming irreversible.

## Notifications

Relevant files:

- `lib/features/notifications/models/notification_model.dart`
- `lib/features/notifications/providers/notification_provider.dart`
- `lib/features/notifications/screens/notifications_screen.dart`

Expected behavior:

- Users and trainers should receive notifications relevant to their role.
- Read/unread status should be stable and should not reappear as unread after being marked read.
- Device token registration happens during auth and uses the communications API.

## Support Tickets

Relevant screens:

- `support_screen.dart`
- `new_ticket_screen.dart`
- `ticket_detail_screen.dart`

Expected behavior:

- Normal users and trainers can submit support tickets.
- Ticket detail should show messages and resolution state.
- Backend/admin resolution flow should eventually connect to the operations queue.

## Profile and Account

Relevant screens:

- `profile_screen.dart`
- `edit_profile_screen.dart`
- `change_password_screen.dart`
- `terms_screen.dart`
- `trainer_application_screen.dart`

Expected behavior:

- Users can update profile data after account creation/import.
- Password changes call the backend change-password endpoint.
- Account deletion behavior must align with backend retention/privacy rules.

## Zana and Business Tools

Relevant screens:

- `zana_screen.dart`
- `biz_manager_screen.dart`
- `insurance_screen.dart`
- `pos_screen.dart`
- `kikoba_screen.dart`

Expected behavior:

- Zana tools are product utilities separate from the core learning flow.
- Business-management entries should map to the backend `businesses` app.
