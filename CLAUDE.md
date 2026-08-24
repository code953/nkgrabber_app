# NKgrabber — CLAUDE.md

## Project Overview

NKgrabber is a Flutter course-grabbing client for Chinese university students. It supports 5 platforms: Android, Windows, Linux, macOS, and iOS. The core flow is: license activation → account management → course target configuration → scheduled submission → version updates.

## Build & Run

```bash
# Install dependencies
flutter pub get

# Generate Drift/freezed code (required after schema changes)
dart run build_runner build --delete-conflicting-outputs

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
  app/              # Router, shell, theme, startup page
  core/
    errors/         # AppException sealed hierarchy, CrashReporter
    logging/        # AppLogger (logging package), LogSanitizer
    network/        # BackendApiClient + 6 interceptors
    security/       # SecureStorage interface + FlutterSecureStorage impl
    utils/          # AppConstants, extensions, DiagnosticsExporter
  features/
    accounts/       # AccountsNotifier, AccountsPage, AddAccountSheet
    courses/        # CourseTargetsNotifier, CourseConfigPage
    grabber/        # GrabberEngine, AccountWorker, RetryClassifier, GrabberPage
    license/        # LicenseNotifier, StartupChecker, ActivationPage
    settings/       # ConsentPage, SettingsPage
    updater/        # UpdateChecker, UpdateVerifier, UpdatePage
  infrastructure/
    backend/        # BackendRepository + impl, DTOs
    campus/         # CampusAdapter + impl, RSA, GBK, models, clock sync
    database/       # AppDatabase (Drift), 5 tables, 5 DAOs, connection
  l10n/             # app_zh.arb (primary), app_en.arb (placeholder)
```

## Key Technical Constraints

- **Two completely isolated HTTP clients**: campus (`http://campus.nks.edu.cn`, GBK, form POST) and backend (`https://nkgrabber.code953.top/api/v1`, JSON). Never mix cookies or sessions.
- **Per-account isolation**: each campus account gets its own `Dio` + in-memory `CookieJar`. Cookies never touch disk.
- **Secure storage only**: passwords, cookies, `deviceToken` live in platform secure storage (Android Keystore / iOS Keychain / Windows DPAPI / Linux Secret Service). Drift only stores reference keys.
- **Log sanitization**: all log output passes through `LogSanitizer` before emission. Passwords, cookies, Bearer tokens, activation codes, `deviceToken`, `licenseCode` are replaced with `[REDACTED]`.
- **Grabber state machine**: `idle → preparing → running → success/paused/stopped/interrupted/authExpired/captchaRequired/failed`. No auto-recovery after `interrupted`. 30-minute hard timeout.
- **effectiveIntervalMs = max(userIntervalMs, plan.minRequestIntervalMs)** — jitter is upward only, never below the floor.
- **xkms validation**: unknown values (`!= "1"|"2"|"3"`) → mark target `failed`, never submit with a default.

## Database Schema (Drift, schemaVersion=1)

| Table | PK | Notes |
|---|---|---|
| `accounts` | UUID TEXT | `cascade` FK owner of CourseTarget and GrabTask |
| `course_targets` | UUID TEXT | FK → accounts(id) ON DELETE CASCADE |
| `grab_tasks` | UUID TEXT | FK → accounts(id) ON DELETE CASCADE |
| `license_snapshots` | id=1 (singleton) | upsert only, cleared on deactivate |
| `app_settings` | id=1 (singleton) | created with defaults on first read |

Indexes: `idx_course_target_account_xkid`, `idx_grab_task_account_status`.

After any schema change, bump `schemaVersion` and add a migration case in `AppDatabase.migration.onUpgrade`.

## Code Generation

This project uses `drift_dev`, `freezed`, and `json_serializable`. Run `build_runner` after:
- Modifying any Drift table or DAO
- Adding/changing `@freezed` or `@JsonSerializable` classes

Generated files (`*.g.dart`, `*.freezed.dart`) are committed to the repo and excluded from analysis.

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
- `AppConstants` (regex, URLs, timeouts)
- Extensions (`maskExcept`, `toIso8601Utc`, `toHms`)
- Enums (`AccountStatus`, `GrabTaskStatus`, `LoginType`, `XkmsMode`)
- `GrabberState` state machine (`isRunning`, `isTerminal`, `copyWith`)
- `RetryClassifier` (7 decision cases)
- `ClockSyncStatus` (drift thresholds, `campusNow`)
- DTOs (`fromJson`, `toJson`, defaults)
- Interval calculation logic

Run with `flutter test`. All 51 tests must pass before committing.

## CI/CD

- `.github/workflows/ci.yml` — runs on every PR: format check, analyze, test, generated-file consistency check.
- `.github/workflows/release.yml` — runs on `v*` tags: builds all 5 platforms and creates a GitHub Release with SHA256SUMS.

## Commit Convention

Each phase of work gets its own commit. Use `feat: Phase N - description` format.

## Sensitive Data Rules

Never commit or log:
- Passwords, cookies, `gdpk`, `JSESSIONID`
- `deviceToken`, activation codes, `licenseCode`
- Student numbers, real names
- Course IDs or names in crash reports

The `.env.example` file documents the Ed25519 public key slot — put the actual key in `assets/keys/` (gitignored in production).
