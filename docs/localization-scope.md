# Karakana localization scope

## What exists today

The app is currently Swahili-only. Text is written directly in about 150 Dart
files. Before this pilot there were no translation files, supported locales, or
Flutter localization delegates.

## Pilot completed by issue #96

The payment-success screen is the pilot because it is small, self-contained, and
does not require server changes. The app now has Swahili and English ARB files,
Flutter localization setup, and the screen reads its visible text from those
resources.

## Suggested full rollout

1. Confirm that a second language is a product requirement and choose the first
   release target.
2. Translate shared labels and navigation first.
3. Migrate one feature area at a time: authentication, courses, payments,
   profile, support, trainer tools, then business tools.
4. Add a language selector and remember the user’s choice.
5. Have a Swahili and English reviewer check every migrated feature.
6. Remove remaining hardcoded user-facing text and add a check to prevent new
   strings from bypassing localization.

## Rough effort estimate

This is a medium-to-large project rather than a configuration change. A small
team should plan roughly 6–10 developer-weeks for extraction, translation
review, testing, and language-selector work. The estimate should be refined
after counting strings in each feature area; the pilot provides the pattern for
that follow-up estimate.

## Decision needed

Leadership should decide whether English (or another language) is required, the
target release, who will approve translations, and whether to fund the full
Q-02 migration. Until then, new screens should keep the localization pattern
from this pilot where practical.
