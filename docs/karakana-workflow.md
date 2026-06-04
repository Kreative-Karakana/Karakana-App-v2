# Karakana Workflow

## 1. English-only technical communication
- Documentation, TODOs, audits, reports, commits, PRs, and code comments must be in English.
- Swahili is allowed only for user-facing Karakana app content.

## 2. V2-only development
- Always work inside `Karakana-App-V2`.
- Do not use Karakana-App v1 files, builds, assets, or configs unless explicitly requested and documented.

## 3. Audit before fix
- Inspect first.
- Identify the root cause.
- Report findings.
- Then apply fixes.

## 4. Small safe changes
- Prefer small verified changes over large unverified changes.
- After each fix, test and document the result.
- After every successful verification, update `todo/active.md` and `todo/done.md`.
- Do not proceed to release builds until debug builds pass.

## 5. Platform parity
- Any iOS-related change should consider Android.
- Any Android-related change should consider iOS.
- Document platform-specific exceptions.
- Whenever Firebase app identifiers, package names, bundle IDs, or OAuth configuration change, regenerate platform configuration files (`google-services.json`, `GoogleService-Info.plist`) and verify no legacy entries remain.

## 6. Version tracking
- Release-related work must record `versionName` / `versionCode` or iOS version / build number where relevant.

## 7. TODO discipline
- Current work goes in `todo/active.md`.
- Completed work goes in `todo/done.md`.
- Future work goes in `todo/backlog.md`.

## 8. Verification before done
- Do not mark work as done unless verification commands have been run or the reason for not running them is documented.

## 9. No secrets in Git
Never commit:
- `key.properties`
- keystore files
- certificates
- private keys
- API secrets
- `local.properties`
