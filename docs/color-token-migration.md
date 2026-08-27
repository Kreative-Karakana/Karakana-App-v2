# Color token migration

`AppColors` is the shared source for app colors. New feature code must use it
instead of adding `Color(0x...)` directly.

## Why this rule exists

Raw colors can look correct in light mode but be wrong in dark mode. They also
make a future brand-color change require editing many unrelated screens.

## What to use

- Use `AppColors.primary`, `AppColors.textPrimary`, `AppColors.surface`,
  `AppColors.error`, and the other semantic getters for normal UI.
- Use `AppColorsLight`/`AppColorsDark` only when a concrete light/dark value is
  intentionally needed in shared theme code.
- A fixed color may remain in artwork or platform-specific code only when the
  code comment explains why it must not follow the app theme.
- Do not add `const` around a widget that contains an `AppColors` getter. The
  getters can change when the app brightness changes.

## Regression check

`tool/check_feature_colors.sh` runs in pull-request CI. It checks only added
lines, so the existing migration backlog does not block unrelated work while
still preventing new raw colors from spreading.

## Migration batches

The existing literals should be migrated in reviewed batches, starting with
Home, Auth, and Courses. For each batch:

1. Map each literal to the closest semantic token.
2. Add a new token when the color has a real distinct meaning.
3. Check light and dark mode on the affected screens.
4. Run analyzer and widget tests.
5. Record any intentional fixed-artwork exceptions.
