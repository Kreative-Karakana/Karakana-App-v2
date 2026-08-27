# Swahili UX copy audit

This is the first audit deliverable for issue #146. It records the wording
rules and the areas that need review. It does not change user-facing copy.

## Simple-Swahili style guide

- Use short, direct sentences. Prefer everyday words over formal or technical
  language.
- Use sentence case for messages and buttons. Use title case only for proper
  names and approved product names.
- Use one consistent spelling for the same action. For example, use `Jaribu
  tena` for retry everywhere.
- Explain what the user can do next. Error messages should say what went wrong
  and offer a next step where possible.
- Keep payment messages clear about whether money is pending, successful,
  cancelled, or failed.
- Keep approved product names such as Karakana, Fursa, eBook, Face ID, and
  TalkBack unchanged. These are product terms, not translation mistakes.
- Do not mix English and Swahili in the same message unless the English word is
  an approved product or platform term.
- Accessibility labels must describe the control and its result, not only its
  icon or visual position.

## Canonical glossary (proposed for review)

| Meaning | Use this wording | Avoid or review |
| --- | --- | --- |
| Retry | Jaribu tena | Jaribu Tena, Jaribu tena tena |
| Help/support | Msaada | Support, Msaada wa Karakana (unless it is the named service) |
| Course | Kozi | Course |
| eBook | eBook | ebook, Kitabu cha kielektroniki in short buttons |
| Read | Soma | Read |
| Buy | Nunua | Purchase, Nunua Sasa when a shorter action is enough |
| Sign in | Ingia | Login, Log in |
| Sign out | Toka | Logout, Log out |
| Sign up | Jisajili | Register, Sign up |
| Save | Hifadhi | Save |
| Cancel | Ghairi | Cancel |
| Continue | Endelea | Continue |
| Delete | Futa | Delete |
| Loading | Inapakia… | Loading |
| Error | Hitilafu | Error |
| Success | Imefanikiwa | Success |
| Pending payment | Malipo yanasubiri uthibitisho. | Payment pending |
| Payment failed | Malipo yameshindwa. Jaribu tena. | Payment error |
| Screen capture | Kunasa skrini hakuruhusiwi wakati wa kusoma eBook. | Screen capture is not allowed |
| Trainer | Mkufunzi | Trainer, Mwalimu (unless product approval chooses one) |
| Student/learner | Mwanafunzi | Student, Learner (unless product approval chooses one) |
| Notification | Arifa | Notification |
| Account | Akaunti | Account |

The glossary is proposed, not final. A native/target-user reviewer must approve
it before broad copy changes are made.

## Surface inventory

The following directories contain user-facing text and are included in the
review. The listed files are starting points, not the complete list of strings.

| Area | Files to review first |
| --- | --- |
| Authentication and account | `lib/features/auth/screens/`, `lib/features/profile/screens/` |
| Navigation and home | `lib/features/home/`, `lib/core/router/`, `lib/main.dart` |
| Courses | `lib/features/courses/screens/`, `lib/features/courses/widgets/` |
| eBooks | `lib/features/ebooks/screens/`, `lib/features/ebooks/trainer/` |
| Payments and subscriptions | `lib/features/payments/screens/`, `lib/features/subscriptions/screens/` |
| Notifications | `lib/features/notifications/screens/` |
| Trainer tools | `lib/features/trainer/screens/` |
| Business Management and Zana | `lib/features/zana/` |
| Support | `lib/features/support/screens/` |
| Fursa and onboarding | `lib/features/fursa/`, `lib/features/onboarding/` |
| Shared dialogs and messages | `lib/widgets/common/`, `lib/widgets/buttons/` |

## Initial inconsistencies to verify

- Retry text appears as both `Jaribu tena` and `Jaribu Tena` in different
  screens.
- The secure reader still has an English capture warning while most of its
  surrounding messages are Swahili (`secure_ebook_reader_screen.dart`).
- Payment and subscription messages use several different descriptions for
  verification, pending, and failure states (`iap_provider.dart`, payment and
  subscription screens).
- Support and trainer screens contain both direct Swahili copy and raw backend
  error text; each user-visible path should be checked for a helpful Swahili
  fallback.
- The localization pilot covers only payment success; most app copy remains
  hardcoded and is outside that pilot.

## Bounded implementation batches

1. **Shared actions and navigation** — retry, save, cancel, continue, sign in,
   sign out, and common empty/loading labels. Owner: frontend lead.
2. **Authentication and account** — login, registration, password, verification,
   and profile messages. Owner: auth reviewer.
3. **Courses and eBooks** — titles, enrollment, reading, trainer/student terms,
   and reader warnings. Owner: learning-product reviewer.
4. **Payments and subscriptions** — initiation, pending, success, cancellation,
   verification, and failure wording. Owner: payments reviewer.
5. **Trainer, support, notifications, and Business Management** — forms,
   validation, backend errors, and accessibility labels. Owner: feature owners.

Each batch should have a separate issue/PR, a native/target-user review, and
focused tests for changed user-visible states. No localization framework
migration is required to complete these batches.

## Review and closure requirements

- Product owner approves the glossary.
- A native or target-user reviewer records approval for each batch.
- Every changed message is checked in its normal, loading, empty, error, and
  success states.
- Accessibility labels and notification text are included in the same review.
- Issue #104 remains the owner of the consolidated empty/error-state work;
  issue #96/#106 remain the owners of future localization architecture.
