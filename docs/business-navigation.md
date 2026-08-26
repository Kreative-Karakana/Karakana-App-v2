# Business Management navigation audit

## Route map

| Screen or flow | Expected back behavior |
| --- | --- |
| `/zana` | Root tool hub; Android back follows the app root behavior. |
| `/zana/biz-manager` | Back returns to the Zana tool hub. |
| Business setup form | Bottom sheet closes and returns to the business dashboard. |
| Transaction create/edit form | Bottom sheet closes and returns to the dashboard; save returns to the same screen. |
| Transaction filter sheet | Closing returns to the transaction list with the previous filters. |
| Debt management (embedded tab/section) | Uses the business dashboard route; it does not create a second root. |
| Confirmation dialogs | Cancel/close returns to the current screen; confirm returns the result to the caller. |

## Audit result

The business manager is a nested route, so Flutter supplies a back control in
its app bar. Forms and filters are modal bottom sheets, and their local context
closes the sheet rather than navigating away from the business route. No
unescapable route or second root was found in the static audit.

## Deliberate behavior

Forms are dismissible sheets. Saving or cancelling closes the sheet and leaves
the user on the business dashboard. Destructive actions require the existing
confirmation dialog before the data changes.

## Verification checklist

- Open `/zana/biz-manager` from the Zana hub and use the app-bar back control.
- Press Android system back from the business manager and from each form/sheet.
- Use the iOS back button and swipe-back gesture from the business manager.
- Open and dismiss setup, transaction, debt, filter, and confirmation flows.
- Repeat in light/dark mode and with larger text.
