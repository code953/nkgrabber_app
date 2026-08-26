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
    grabber/        # GrabberEngine, AccountWorker, RetryClassifier,
                    #   GrabberController, GrabberPage
    settings/       # SettingsPage
  infrastructure/
    campus/         # CampusAdapter + impl, RSA, encoding, response envelope,
                    #   portal SSO, models, clock sync
    database/       # AppDatabase (Drift), 4 tables, 4 DAOs, connection
    providers.dart  # DB/storage/DAO providers + AppSettingsNotifier
  l10n/             # app_zh.arb (primary), app_en.arb (placeholder)
```

`main.dart` installs `FlutterError.onError` + `runZonedGuarded`; both write sanitized messages to the local log and send nothing over the network. It also calls `markInterrupted()` once after the first frame, so tasks left `running` by a crash are not mistaken for live ones.

## Riverpod Wiring

Every page reads its data through providers; there are no stubs left.

| Provider | Kind | Notes |
|---|---|---|
| `appDatabaseProvider`, `secureStorageProvider` | `Provider` | Overridden in widget tests with an in-memory DB + fake storage |
| `accountDaoProvider` … `settingsDaoProvider` | `Provider` | Thin accessors; inherit the database's lifecycle |
| `appSettingsProvider` | `AsyncNotifier` | **Not** a `StreamProvider` — see below |
| `accountsProvider` | `StateNotifier` | Loads on construction; owns the `CampusClient` map |
| `selectedAccountIdProvider` | `StateProvider` | Which account the course page is configuring |
| `courseTargetsProvider` | `StateNotifier.family(accountId)` | Family-keyed so switching accounts cannot leak targets |
| `batchesProvider`, `coursesProvider` | `FutureProvider.family` | The only network reads outside the engine |
| `grabbableAccountsProvider` | `FutureProvider` | Enabled accounts that have ≥1 enabled target |
| `grabberProvider` | `StateNotifier` | `GrabberController` mirrors the engine's broadcast stream |

- **`appSettingsProvider` must not be a `StreamProvider` over `SettingsDao.watch()`.** Drift schedules a zero-duration cleanup timer when a query stream is cancelled. That timer is created during `finalizeTree`, after the framework's end-of-test pump has drained its queue, so it is still pending when `_verifyInvariants` runs and *every* widget test fails with "A Timer is still pending even after the widget tree was disposed". Teardowns run after that check, so they cannot fix it. Reading once and re-reading after each write keeps reactivity, since the row only changes through `AppSettingsNotifier`.
- **Adapters are memory-only.** After a restart an account has a stored cookie but no `CampusClient`. Use `AccountsNotifier.ensureAdapter()` (async) rather than `getAdapter()` — it rebuilds from secure storage, and marks the account `expired` and returns null if the cookie is rejected. `GrabberEngine.AdapterResolver` is async for exactly this reason.
- **The engine reads its limits at construction.** `grabberProvider` watches `appSettingsProvider`, so changing a limit rebuilds the engine — which would orphan running workers. The settings page therefore disables those controls while `grabberProvider` reports `isRunning`.

## Key Technical Constraints

- **One HTTP target only**: the campus system (`http://campus.nks.edu.cn`, form POST). There is no business backend — do not add one.
- **The campus wire format is not guessable — it was measured.** Every field name, body format, and envelope rule in `lib/infrastructure/campus/` came from probing the live deployment, and several are counter-intuitive:
  - `status` in the response envelope is an **HTTP-like int** (200), not a boolean. `status == true` is never satisfied.
  - The payload is under `result`, never under `data`. Reading `data` yields a silent empty list, not an error.
  - A **missing** `result` key means "response we don't understand"; `result: null` means "legitimately empty". Do not conflate them.
  - The portal's `.jsmeb` endpoints take a **JSON** body under a form-encoded Content-Type. A genuinely form-encoded `params=[...]` is rejected with 参数格式非法.
  - The same field is typed inconsistently across endpoints (`zdxk` is the string `"2"`, `xkms` is the number `0`) — always go through `campusInt` / `campusString`.
  - Reaching the course-selection app needs the full `ssolx=5` SSO handshake (`token` + `apiUrl` + `userid`); a bare `GET /njs_3033/xsxk2` answers 403.
- **Two transport-level workarounds exist because the school's server is broken, not because we prefer them.** Both were diagnosed by capturing raw response bytes; both are pinned by an end-to-end test against a loopback server.
  - Every post-login response carries a bare `Set-Cookie: HttpOnly=` next to the real one. The portal meant to append the `HttpOnly` *attribute* to `JSESSIONID` and emitted a separate header line instead. `dart:io` refuses to parse it, and `CookieManager` forces the whole map with `.toList()`, so that single throw discards the **valid** `JSESSIONID` on the same response and dio reports `DioException [unknown]: null`. Hence `CookieManager(_cookieJar, ignoreInvalidCookies: true)` — dropping just the bad fragment is what browsers do. Do not remove it, and keep `dio_cookie_manager >=3.4.0`.
  - The SSO chain is followed **by hand**, one hop per request (`_followSsoRedirects`). Dio's `followRedirects` lives in the HTTP adapter, *below* the interceptor chain, so `CookieManager` never sees intermediate responses — and `gdpk` is set on hop 0 only. With automatic following the final hop arrives cookie-less and the server answers 403.

  All of this is pinned by verbatim fixtures in `test/campus_parsing_test.dart`. Before changing a parser, read the fixture — if a change contradicts one, the change is wrong unless the school actually changed. `campus_envelope.dart` is the single unwrap layer; do not re-implement envelope checks at a call site.
- **The submit path is the one link never verified against the live server.** `saveStudentXkJs`'s `kmhDtoList` shape was derived from the school's own page script, not from a response: the only batch on this deployment closed 2026-04-18, and submitting would have mutated a real student's registration. The `UNVERIFIED` comment at that call site stays until someone confirms it during an open batch.
- **Per-account isolation**: each campus account gets its own `Dio` + in-memory `CookieJar`. Cookies never touch disk. `AccountsNotifier` owns these clients and disposes them on account removal, failed login, and its own disposal.
- **Secure storage only**: passwords and cookies live in platform secure storage (Android Keystore / iOS Keychain / Windows DPAPI / Linux Secret Service). Drift only stores reference keys.
- **Log sanitization**: all log output passes through `LogSanitizer` before emission. Passwords, cookies, Bearer tokens, activation codes, `deviceToken`, `licenseCode` are replaced with `[REDACTED]`. The last three patterns are kept even though the online business is gone — removing a redaction rule is never an improvement. Student names, student numbers, and course names are never logged either: log the opaque UUID instead. `mycenter_token` is a live session credential and must never be logged.
- **Grabber state machine**: `idle → preparing → running → success/paused/stopped/interrupted/captchaRequired/failed`. No auto-recovery after `interrupted`. 30-minute hard timeout.
- **effectiveIntervalMs = max(userIntervalMs, settings.minRequestIntervalMs)** — jitter is upward only, never below the floor. Both values come from `app_settings`.
- **xkms classification** lives in `Xkms` (`xkms_enum.dart`), which distinguishes three cases, because two of them need different words for the user:
  - `"1"|"2"|"3"` → submittable (抢选 / 正选 / 补退选).
  - `"0"` → the batch's selection window has **closed**. This is a real documented state, not a parsing failure. Telling the user to wait for a client upgrade here sends them chasing a bug that does not exist.
  - anything else → genuinely unknown; mark the target `failed` and ask for an upgrade.

  Never submit with a defaulted `xkms`. The batch picker refuses to select any non-submittable batch.
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

Tests live in `test/widget_test.dart` and `test/campus_parsing_test.dart`.

`widget_test.dart` covers:
- `AppException` hierarchy
- `LogSanitizer` (all redaction patterns)
- `AppConstants` (campus URL, timeouts, default-limit consistency)
- Extensions (`maskExcept`, `toIso8601Utc`, `toHms`)
- Enums (`AccountStatus`, `GrabTaskStatus`, `LoginType`, `XkmsMode`)
- `GrabberState` state machine (`isRunning`, `isTerminal`, `copyWith`)
- `RetryClassifier` (decision cases)
- `ClockSyncStatus` (`campusNow` offset in both directions)
- Interval calculation (`max(userIntervalMs, minRequestIntervalMs)`)

`campus_parsing_test.dart` (38 cases) covers the response-parsing layer:
`RsaEncryptor.extractFromHtml`, the `campus_envelope` unwrappers,
`campusInt`/`campusString`, portal SSO (`parsePortalSession`,
`findCourseSelectionApp`, `buildSsoUrl`), `Xkms` classification, the submit
payload shape, and the two transport-level workarounds the school's server
forces on us (malformed `Set-Cookie`, manual SSO redirect following). The last
group runs a loopback `HttpServer` that reproduces the portal's behaviour and
drives the real `CampusClient` + `CampusAdapterImpl` through it — asserting on
a hand-built `CookieManager` would have passed even with the fix reverted.

**Every fixture in that file is a verbatim excerpt of a real response** captured
from the live deployment, with sensitive values (RSA modulus, session ids,
student name and number) replaced by structurally-identical placeholders. Field
names, nesting, and value *types* are preserved exactly, because those are what
the parsers depend on — hand-written approximations are what let the original
defects through. Do not "tidy" a fixture into something that looks more regular
than the server actually is.

Widget tests (14 cases) pump the real `NKGrabberApp` with `appDatabaseProvider`
overridden to `NativeDatabase.memory()` and `secureStorageProvider` to a fake —
the production providers open a file under the application support directory,
which does not resolve in a test, so the page would spin forever and
`pumpAndSettle` would time out. Use the `_pumpApp` / `_seedAccount` /
`_seedTarget` helpers rather than repeating the override block.

- `NKGrabberApp`: reaches the accounts page, `MaterialLocalizations` / `S`
  resolve under the forced `zh` locale, empty state, list rendering
- `CourseConfigPage`: no-account prompt, empty target state, priority ordering
- `GrabberPage`: the start button stays disabled with no account, with an
  account but no targets, and with only disabled targets; enabled otherwise
- `SettingsPage`: renders the stored row, persists a slider release, warns
  when the user interval is below the floor

Run with `flutter test`. All 94 tests must pass before committing.

New tests must be checked negatively — break the wiring under test and
confirm the case goes red. A green test proves nothing on its own; several of
these were written after a page was already wired, and only the negative check
distinguishes "asserts the behaviour" from "asserts a coincidence".

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

Log the opaque account/target UUID instead — it is meaningless outside the local
database. Displaying these in the UI is fine (the user owns the data); writing
them to the log file is not.

`.env.example` documents no required variables — the client needs no build-time secrets.
