# NKgrabber — CLAUDE.md

## Project Overview

NKgrabber is a Flutter course-grabbing client for Chinese university students. It supports 5 platforms: Android, Windows, Linux, macOS, and iOS. The core flow is: account management → course target configuration → scheduled submission.

The client is **fully offline** apart from the campus system itself. There is no license activation, no update check, no crash reporting, and no remote config — those were removed deliberately, so do not reintroduce a backend HTTP client.

## Build & Run

```bash
# Install dependencies
flutter pub get

# Generate Drift code (required after schema changes)
dart run build_runner build --delete-conflicting-outputs

# Regenerate localizations (required after editing lib/l10n/*.arb)
flutter gen-l10n

# Run tests
flutter test

# Static analysis (treat info as non-fatal)
flutter analyze --no-fatal-infos

# Build
flutter build apk              # Android
flutter build windows          # Windows
flutter build linux            # Linux
flutter build macos            # macOS
flutter build ios --no-codesign # iOS (build verify only)
```

## Architecture

```
lib/
  app/              # Router, shell page, theme
  core/
    errors/         # AppException sealed hierarchy
    logging/        # AppLogger (logging package), LogSanitizer
    security/       # SecureStorage interface + FlutterSecureStorage impl
    utils/          # AppConstants, extensions, DiagnosticsExporter
  features/
    accounts/       # AccountsNotifier, AccountsPage, AddAccountSheet
    courses/        # CourseTargetsNotifier, CourseConfigPage
    grabber/        # GrabberEngine, AccountWorker, RetryClassifier, GrabberPage
    settings/       # SettingsPage
  infrastructure/
    campus/         # CampusAdapter + impl, RSA, GBK, models, clock sync
    database/       # AppDatabase (Drift), 4 tables, 4 DAOs, connection
  l10n/             # app_zh.arb (primary), app_en.arb (placeholder)
```

`main.dart` installs `FlutterError.onError` + `runZonedGuarded`; both write sanitized messages to the local log and send nothing over the network.

## Key Technical Constraints

- **One HTTP target only**: the campus system (`http://campus.nks.edu.cn`, GBK, form POST). There is no business backend — do not add one.
- **Per-account isolation**: each campus account gets its own `Dio` + in-memory `CookieJar`. Cookies never touch disk.
- **Secure storage only**: passwords and cookies live in platform secure storage (Android Keystore / iOS Keychain / Windows DPAPI / Linux Secret Service). Drift only stores reference keys.
- **Log sanitization**: all log output passes through `LogSanitizer` before emission. Passwords, cookies, Bearer tokens, activation codes, `deviceToken`, `licenseCode` are replaced with `[REDACTED]`. The last three patterns are kept even though the online business is gone — removing a redaction rule is never an improvement.
- **Grabber state machine**: `idle → preparing → running → success/paused/stopped/interrupted/captchaRequired/failed`. No auto-recovery after `interrupted`. 30-minute hard timeout.
- **effectiveIntervalMs = max(userIntervalMs, settings.minRequestIntervalMs)** — jitter is upward only, never below the floor. Both values come from `app_settings`.
- **xkms validation**: unknown values (`!= "1"|"2"|"3"`) → mark target `failed`, never submit with a default.
- **Localization delegates are mandatory**: `MaterialApp.router` forces `locale: Locale('zh')`, and the implicit `DefaultMaterialLocalizations` supports `en` only. `localizationsDelegates: S.localizationsDelegates` (which bundles the three `Global*` delegates) must stay wired, or every Material widget that calls `MaterialLocalizations.of()` — `NavigationRail`, `NavigationBar`, `Scaffold` drawers — throws at build time. Keep `supportedLocales: S.supportedLocales` so it tracks the `.arb` files.

## Database Schema (Drift, schemaVersion=3)

| Table | PK | Notes |
|---|---|---|
| `accounts` | UUID TEXT | `cascade` FK owner of CourseTarget and GrabTask |
| `course_targets` | UUID TEXT | FK → accounts(id) ON DELETE CASCADE |
| `grab_tasks` | UUID TEXT | FK → accounts(id) ON DELETE CASCADE |
| `app_settings` | id=1 (singleton) | created with defaults on first read; holds `userIntervalMs`, `minRequestIntervalMs`, `maxAccounts`, `maxConcurrentAccounts` |

Indexes: `idx_course_target_account_xkid`, `idx_grab_task_account_status`.

Migration history: v1→v2 dropped `license_snapshots`; v2→v3 added the three limit columns and rebuilt `app_settings` to drop `update_channel` / `crash_reporting_enabled`.

After any schema change, bump `schemaVersion` and add a migration case in `AppDatabase.migration.onUpgrade`.

## Code Generation

This project uses `drift_dev`. Run `build_runner` after modifying any Drift table or DAO.

Generated files (`*.g.dart`) are committed to the repo and excluded from analysis. l10n output (`lib/l10n/app_localizations*.dart`) is also committed — run `flutter gen-l10n` after editing an `.arb` file.

## Import Convention

Always use package imports — never relative:
```dart
// ✅ correct
import 'package:nkgrabber/core/errors/app_exception.dart';

// ❌ wrong
import '../../core/errors/app_exception.dart';
```

## Testing

Tests live in `test/widget_test.dart`. The suite covers:
- `AppException` hierarchy
- `LogSanitizer` (all redaction patterns)
- `AppConstants` (campus URL, timeouts, default-limit consistency)
- Extensions (`maskExcept`, `toIso8601Utc`, `toHms`)
- Enums (`AccountStatus`, `GrabTaskStatus`, `LoginType`, `XkmsMode`)
- `GrabberState` state machine (`isRunning`, `isTerminal`, `copyWith`)
- `RetryClassifier` (decision cases)
- `ClockSyncStatus` (`campusNow` offset in both directions)
- Interval calculation (`max(userIntervalMs, minRequestIntervalMs)`)
- `NKGrabberApp` boot (widget test): the app reaches the accounts page and
  `MaterialLocalizations` / `S` resolve under the forced `zh` locale

Run with `flutter test`. All 44 tests must pass before committing. The two
`NKGrabberApp` cases are the only widget tests; every page is still a stub, so
there is no coverage of user interaction.

## CI/CD

- `.github/workflows/ci.yml` — runs on every PR: format check, analyze, test, generated-file consistency check.
- `.github/workflows/release.yml` — runs on `v*` tags: builds all 5 platforms and creates a GitHub Release with SHA256SUMS.

## Commit Convention

Each phase of work gets its own commit. Use `feat: Phase N - description` format. Write commit messages in Simplified Chinese.

## Sensitive Data Rules

Never commit or log:
- Passwords, cookies, `gdpk`, `JSESSIONID`
- Student numbers, real names
- Course IDs or names

`.env.example` documents no required variables — the client needs no build-time secrets.
