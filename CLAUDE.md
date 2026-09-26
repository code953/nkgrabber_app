# NKgrabber — CLAUDE.md

## Project Overview

NKgrabber is a Flutter course-grabbing client for Chinese university students. It supports 5 platforms: Android, Windows, Linux, macOS, and iOS. The core flow is: account management → course target configuration → scheduled submission.

The client is **fully offline** apart from the campus system itself. There is no license activation, no update check, no crash reporting, and no remote config — those were removed deliberately, so do not reintroduce a backend HTTP client. The single exception is the **background-image downloader**, which fetches only a URL the user typed, only when they press a button, and caches the result on disk so launches stay offline.

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
flutter build ios --no-codesign # iOS (unsigned; users sign it themselves)
```

## Architecture

```
lib/
  app/              # Router, shell page, theme, AppBackground
  core/
    errors/         # AppException sealed hierarchy
    logging/        # AppLogger (logging package), LogSanitizer
    security/       # SecureStorage interface + FlutterSecureStorage impl
    utils/          # AppConstants, extensions, DiagnosticsExporter,
                    #   image_palette (theme seeds from a picture)
  features/
    accounts/       # AccountsNotifier, AccountsPage, AddAccountSheet
    courses/        # CourseTargetsNotifier, CourseConfigPage
    grabber/        # GrabberEngine, AccountWorker, RetryClassifier,
                    #   GrabberController, GrabberPage, GrabLogBus
    settings/       # SettingsPage, theme colour picker, background
                    #   image rows + BackgroundController
  infrastructure/
    background/     # BackgroundImageService (local import + image-host download)
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
| `grabLogProvider` | `StreamProvider` | The live request/response log; replays `GrabLogBus`'s backlog because the page is built after a run starts |
| `backgroundImageServiceProvider` | `Provider` | Rooted in the app support dir; overridden in tests with a temp dir |
| `backgroundImageFileProvider` | `FutureProvider` | The stored picture, or null. Returns before touching the file system when none is set |
| `backgroundSeedColorsProvider` | `FutureProvider` | Seed candidates from the current picture, offered in the colour picker |
| `backgroundControllerProvider` | `Provider` | Import / refresh / clear; writes the background and its theme seed in one settings write |

- **`appSettingsProvider` must not be a `StreamProvider` over `SettingsDao.watch()`.** Drift schedules a zero-duration cleanup timer when a query stream is cancelled. That timer is created during `finalizeTree`, after the framework's end-of-test pump has drained its queue, so it is still pending when `_verifyInvariants` runs and *every* widget test fails with "A Timer is still pending even after the widget tree was disposed". Teardowns run after that check, so they cannot fix it. Reading once and re-reading after each write keeps reactivity, since the row only changes through `AppSettingsNotifier`.
- **Adapters are memory-only.** After a restart an account has a stored cookie but no `CampusClient`. Use `AccountsNotifier.ensureAdapter()` (async) rather than `getAdapter()` — it rebuilds from secure storage, and marks the account `expired` and returns null if the cookie is rejected. `GrabberEngine.AdapterResolver` is async for exactly this reason.
- **The engine reads its limits at construction.** `grabberProvider` watches `appSettingsProvider`, so changing a limit rebuilds the engine — which would orphan running workers. The settings page therefore disables those controls while `grabberProvider` reports `isRunning`.

## Key Technical Constraints

- **One HTTPS target only**: the campus system (`https://campus.nks.edu.cn`, form POST). There is no business backend — do not add one. The background downloader (below) is user-directed and is not a backend.
- **The background image is cached, never streamed.** `BackgroundImageService` copies a local pick or downloads an image-host URL into `<app support>/background/`, and the app draws from that file. Things that look optional and are not:
  - **Only a bare file name is stored** (`app_settings.background_image_file`). iOS moves the app container on every update, so an absolute path would dangle after the first upgrade.
  - **Every import gets a fresh file name** and the previous one is pruned. Reusing a name lets `FileImage`'s cache keep serving the old picture.
  - **Dual-end image hosts** answer the same URL with a landscape picture for desktop browsers and a portrait one for phones, by User-Agent (and `Sec-CH-UA-Mobile`). `ImageHostClient` picks a desktop or mobile header set — by platform unless the user overrides it — and the choice is stored so 重新获取 asks the same way. A generic UA gets a landscape picture on a phone.
  - **Content-Type is not trusted; magic numbers are.** Hosts serve pictures as `application/octet-stream` and error pages as `image/jpeg`. A non-image reply is followed once or twice if it is JSON or a bare line naming the real URL (preferring `url` / `imgurl` / … keys over document order — a `homepage` link often comes first). HTML is **never scraped**: it is an error page or an anti-hotlinking wall, and guessing an `<img>` would import its banner.
  - **AVIF is not advertised** in `Accept`: Flutter cannot decode it on most platforms, and a host that sees it offered may pick it.
  - Log only the **host**: image-host URLs regularly carry API keys in the query.
- **A background re-seeds the theme from the picture** (`image_palette.dart` — Celebi quantisation + Material `Score`, the pipeline `ColorScheme.fromImageProvider` runs, but returning the seed, which is what gets persisted). A colourless picture yields **no** seed and leaves the theme alone; `Score`'s own fallback is Google blue, which is not in the picture. The seed is persisted with `toARGB32()` via `encodeThemeColor` — `Color.value` was what once read a saved colour back as all zeros.
- **Pages are transparent only while a background is set** (`AppTheme.translucent`): scaffold, app bar and navigation are cleared, cards stay mostly opaque. The shell tabs use `NoTransitionPage` — with transparent scaffolds a route transition draws both pages over each other.
- **The User-Agent must not name the app.** It is a stock desktop-Chrome string in `campus_client_factory.dart`. The original ended in `NKgrabber/1.0`, which signed every request in the school's access log; nothing in the campus protocol keys off the UA, so identifying ourselves bought nothing. The header set also carries `X-Requested-With: XMLHttpRequest` and `Origin`, matching a capture of the portal's own XHR — whether the server enforces them is unknown, but a difference we could cheaply avoid is one we would otherwise have to rule out first if it ever starts refusing us. Pinned by a test.
- **The campus wire format is not guessable — it was measured.** Every field name, body format, and envelope rule in `lib/infrastructure/campus/` came from probing the live deployment, and several are counter-intuitive:
  - `status` in the response envelope is an **HTTP-like int** (200), not a boolean. `status == true` is never satisfied.
  - The payload is under `result`, never under `data`. Reading `data` yields a silent empty list, not an error.
  - A **missing** `result` key means "response we don't understand"; `result: null` means "legitimately empty". Do not conflate them.
  - A **missing `result.code` is not success on the submit path.** Read endpoints omit `code`, so `unwrapCampusCommand` defaults to treating its absence as success — but `submit()` passes `requireCode: true`, because a submit response we cannot parse (an HTML error page that still decodes, a `{"result":{}}`) is not evidence the course was granted. Defaulting it to success is what made the desktop client announce 抢课成功 for a course the server never granted while the phone client kept retrying.
  - The school signals a refusal **two** ways: `result.code` and the envelope's `error` object. Both carry the same Chinese message, so `submit()` routes both through `_mapSubmitMessage`. Classifying only the first left 人数已满-via-`error` typed as `parameterError`, which `RetryClassifier` abandons the target on instead of retrying.
  - `SubmitResult.success` is asserted only where `code == "0"` was actually seen. Never infer it from the absence of an exception.
  - The portal's `.jsmeb` endpoints take a **JSON** body under a form-encoded Content-Type. A genuinely form-encoded `params=[...]` is rejected with 参数格式非法.
  - The same field is typed inconsistently across endpoints (`zdxk` is the string `"2"`, `xkms` is the number `0`) — always go through `campusInt` / `campusString`.
  - Reaching the course-selection app needs the full `ssolx=5` SSO handshake (`token` + `apiUrl` + `userid`); a bare `GET /njs_3033/xsxk2` answers 403.
- **Two transport-level workarounds exist because the school's server is broken, not because we prefer them.** Both were diagnosed by capturing raw response bytes; both are pinned by an end-to-end test against a loopback server.
  - Every post-login response carries a bare `Set-Cookie: HttpOnly=` next to the real one. The portal meant to append the `HttpOnly` *attribute* to `JSESSIONID` and emitted a separate header line instead. `dart:io` refuses to parse it, and `CookieManager` forces the whole map with `.toList()`, so that single throw discards the **valid** `JSESSIONID` on the same response and dio reports `DioException [unknown]: null`. Hence `CookieManager(_cookieJar, ignoreInvalidCookies: true)` — dropping just the bad fragment is what browsers do. Do not remove it, and keep `dio_cookie_manager >=3.4.0`.
  - The SSO chain is followed **by hand**, one hop per request (`_followSsoRedirects`). Dio's `followRedirects` lives in the HTTP adapter, *below* the interceptor chain, so `CookieManager` never sees intermediate responses — and `gdpk` is set on hop 0 only. With automatic following the final hop arrives cookie-less and the server answers 403.

  All of this is pinned by verbatim fixtures in `test/campus_parsing_test.dart`. Before changing a parser, read the fixture — if a change contradicts one, the change is wrong unless the school actually changed. `campus_envelope.dart` is the single unwrap layer; do not re-implement envelope checks at a call site.
- **The submit path was verified by a packet capture, not by us submitting.** A capture of the school's own page posting `saveStudentXkJs` during an open batch (2026-03-14) confirmed the body field for field — `xkid`, `xkms`, `sftj=1`, `kms=<count>`, `kmhDtoList=[{"kmh":…},…]` — and the reply `{"result":{"code":"0","msg":"提交成功！","data":"1"},"status":200}`. The former `UNVERIFIED` comment is gone; `test/campus_parsing_test.dart` pins the body against a loopback server. Two things that capture settled, both of which had been guessed wrong:
  - `xkms=0` is **submittable** — see the xkms bullet below.
  - `data` is `"1"` for a **two-course** submission the server accepted, so it is not a count of granted courses. It is carried on `SubmitResult.rawData` for the live log and takes no part in the verdict; with one sample, gating on it could turn a real success into a reported failure.
- **Per-account isolation**: each campus account gets its own `Dio` + in-memory `CookieJar`. Cookies never touch disk. `AccountsNotifier` owns these clients and disposes them on account removal, failed login, and its own disposal.
- **Secure storage only**: passwords and cookies live in platform secure storage (Android Keystore / iOS Keychain / Windows DPAPI / Linux Secret Service). Drift only stores reference keys.
- **Log sanitization**: all log output passes through `LogSanitizer` before emission. Passwords, cookies, Bearer tokens, activation codes, `deviceToken`, `licenseCode` are replaced with `[REDACTED]`. The last three patterns are kept even though the online business is gone — removing a redaction rule is never an improvement. Student names, student numbers, and course names are never logged either: log the opaque UUID instead. `mycenter_token` is a live session credential and must never be logged.
- **The grab path submits first and reads nothing before it.** `AccountWorker.run` used to make two round trips before the first `saveStudentXkJs` — `listSelections` for a local idempotency check and `listBatches` to re-read `zdxk` — at the exact moment a round trip is most expensive. `zdxk` is now snapshotted onto the target at config time, and a course already held is refused by the server with 已选该课, which `_mapSubmitMessage` types as `courseConflict` and the classifier turns into `skipTarget`. The server's answer is the better check for a second reason: the old one reported a skipped target as `success: true`, so the engine counted it toward 成功 and the log drew a green tick — indistinguishable from a course just won, which is exactly the confusion "success must be asserted, never inferred" exists to prevent. It also compared `kmh` values that are both `''` when upstream omits the id, so two unidentifiable courses matched. Do not reintroduce a pre-flight read.
- **The live-log response preview decodes before it truncates.** `_CampusLoggingInterceptor._decodePreview` hands the whole body to `decodeGbk` and lets `_excerpt` cut *characters*. Slicing 600 bytes first put the cut mid-sequence on any response long enough to truncate, strict UTF-8 decoding threw, and the whole buffer fell through to the GBK branch — so precisely the long responses worth reading rendered as a wall of `���` while short ones looked fine.
- **GBK decoding uses the `charset` package, not a hand-rolled table.** The server currently sends UTF-8; the GBK branch is a fallback. The table it replaced generated its mapping from a formula that assumed GB2312 level-1 was laid out in codepoint order (it is ordered by pinyin), and its level-2 helper said "近似" in its own comment — `趣味足球` decoded to `囓夙岔囃`. It did not fail loudly; it invented plausible characters, which is the worse failure for a decoder. Try UTF-8 first: GBK will "decode" almost any byte sequence, so reversing the order gives up the ability to tell them apart.
- **Grabber state machine**: `idle → preparing → running → success/stopped/interrupted/captchaRequired/failed`. No auto-recovery after `interrupted`. 30-minute hard timeout. **Stopping is restartable**: `stop()` leaves the state in `stopped`, from which `start()` may be called directly — `GrabberPage` shows 重新开始 there rather than forcing a reset first, which during an open batch is time the user does not have. `start()` builds a fresh `GrabberState` rather than `copyWith`ing, or the new run's preparing phase displays the previous run's tally. `GrabberStatus.paused` is retained for the `GrabTaskStatus` mapping and old task rows but **is no longer produced**: pause cancelled the workers exactly as stop did (`AccountWorker._cancelled` is a one-way latch) yet parked the state where neither stop nor reset was offered — a soft deadlock.
- **The live grabber log (`GrabLogBus`) is display-only and has two producers.** `_CampusLoggingInterceptor` publishes requests and responses, because it is the only place that sees the wire; `AccountWorker` / `GrabberEngine` publish verdicts and lifecycle, because the interceptor cannot tell an accepted submit from a refused one — both are HTTP 200. It is a process-wide singleton because clients are built deep inside `AccountsNotifier`, and the buffer is capped at 500 entries. Course names and account labels may appear **on screen** (the user owns their data) but nothing on this bus reaches the log file, whose rules are unchanged.
- **Exporting the live log is deliberately not sanitized** (`grab_log_export.dart`, reachable from the grabber page's app bar as clipboard or file). It is the display path, not the log-file path: the user presses 导出 on data they already own and decides who sees it. Redacting the campus system's own reply would defeat the one job the export has — showing someone else what the school actually said. `LogSanitizer` and `AppLogger` still govern the log file and are not involved here.
- **effectiveIntervalMs = max(userIntervalMs, settings.minRequestIntervalMs)** — jitter is upward only, never below the floor. Both values come from `app_settings`.
- **xkms classification** lives in `Xkms` (`xkms_enum.dart`) and distinguishes exactly two cases:
  - `"0"|"1"|"2"|"3"` → submittable (选课 / 抢选 / 正选 / 补退选).
  - anything else → genuinely unknown; mark the target `failed` and ask for an upgrade.

  `"0"` was previously classified as "the selection window has closed" and blocked, on the reasoning that the only batch then visible carried it and was over. The 2026-03-14 capture disproves that: the school's own page posted `xkms=0` and the server answered `code:"0"`. Batch state is carried by `zt` / `jssj`, not by `xkms`, and blocking `"0"` made the client refuse an ordinary batch — the user had to switch on debug mode to grab anything at all. Never submit with a defaulted `xkms`; the batch picker still refuses a genuinely unrecognised one.
- **Debug mode (`app_settings.debugModeEnabled`, default off) lifts the xkms gate, not the xkms value.** With it on, the batch picker lets an unrecognised batch be selected and `AccountWorker` submits instead of reporting `blockedReason` — but the request still carries the **server's own** `xkms` verbatim. Substituting a known code would destroy the only thing the mode exists to observe: what the campus system actually answers for a mode we do not recognise. `GrabberEngine` reads the flag at construction like the other limits, so the settings toggle is locked while a task runs, and `GrabberPage` shows a persistent banner while it is on — without that, a user who forgot the switch reads the server's correct refusal as a client bug.
- **Localization delegates are mandatory**: `MaterialApp.router` forces `locale: Locale('zh')`, and the implicit `DefaultMaterialLocalizations` supports `en` only. `localizationsDelegates: S.localizationsDelegates` (which bundles the three `Global*` delegates) must stay wired, or every Material widget that calls `MaterialLocalizations.of()` — `NavigationRail`, `NavigationBar`, `Scaffold` drawers — throws at build time. Keep `supportedLocales: S.supportedLocales` so it tracks the `.arb` files.

## Database Schema (Drift, schemaVersion=7)

| Table | PK | Notes |
|---|---|---|
| `accounts` | UUID TEXT | `cascade` FK owner of CourseTarget and GrabTask |
| `course_targets` | UUID TEXT | FK → accounts(id) ON DELETE CASCADE; holds a `zdxk` snapshot |
| `grab_tasks` | UUID TEXT | FK → accounts(id) ON DELETE CASCADE |
| `app_settings` | id=1 (singleton) | created with defaults on first read; holds `userIntervalMs`, `minRequestIntervalMs`, `maxAccounts`, `maxConcurrentAccounts`, `debugModeEnabled`, `customThemeColor`, and the background image (`backgroundImageFile` / `Url` / `Client`, `backgroundOverlayPercent`) |

Indexes: `idx_course_target_account_xkid`, `idx_grab_task_account_status`.

Migration history: v1→v2 dropped `license_snapshots`; v2→v3 added the three limit columns and rebuilt `app_settings` to drop `update_channel` / `crash_reporting_enabled`; v3→v4 added `debug_mode_enabled` (default false, so an upgrade is behaviour-preserving); v4→v5 added `course_targets.zdxk` (default 1, which is what the old fallback used when the re-read failed); v5→v6 added `custom_theme_color`; v6→v7 added the four background columns (nullable or defaulted, so an upgrade shows no background).

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

Tests live in `test/widget_test.dart`, `test/campus_parsing_test.dart` and `test/background_image_test.dart`.

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

`campus_parsing_test.dart` (51 cases) covers the response-parsing layer:
`RsaEncryptor.extractFromHtml`, the `campus_envelope` unwrappers,
`campusInt`/`campusString`, portal SSO (`parsePortalSession`,
`findCourseSelectionApp`, `buildSsoUrl`), `Xkms` classification, the submit
payload shape **checked field for field against the captured browser request**,
the request headers, the **submit verdict**, and the two
transport-level workarounds the school's server forces on us (malformed
`Set-Cookie`, manual SSO redirect following). Three groups run a loopback
`HttpServer` and drive the real `CampusClient` + `CampusAdapterImpl` through
it — asserting on a hand-built `CookieManager`, or on `unwrapCampusCommand`
alone, would have passed even with the fix reverted.

**Every fixture in that file is a verbatim excerpt of a real response** captured
from the live deployment, with sensitive values (RSA modulus, session ids,
student name and number) replaced by structurally-identical placeholders. Field
names, nesting, and value *types* are preserved exactly, because those are what
the parsers depend on — hand-written approximations are what let the original
defects through. Do not "tidy" a fixture into something that looks more regular
than the server actually is.

Widget tests pump the real `NKGrabberApp` with `appDatabaseProvider`
overridden to `NativeDatabase.memory()` and `secureStorageProvider` to a fake —
the production providers open a file under the application support directory,
which does not resolve in a test, so the page would spin forever and
`pumpAndSettle` would time out. Use the `_pumpApp` / `_seedAccount` /
`_seedTarget` helpers rather than repeating the override block.

- `NKGrabberApp`: reaches the accounts page, `MaterialLocalizations` / `S`
  resolve under the forced `zh` locale, empty state, list rendering
- `CourseConfigPage`: no-account prompt, empty target state, priority ordering
- `GrabberPage`: the start button stays disabled with no account, with an
  account but no targets, and with only disabled targets; enabled otherwise.
  A finished run offers 重新开始 with no reset step and no 暂停 — driven by
  actually pressing start, because the old blocker was UI gating (only
  `_IdleView` had a start button) and an engine-level assertion passes with
  it reverted. The live log reaches the screen through `grabLogProvider`.
- `GrabLogBus`: backlog replay for a late subscriber, the 500-entry cap, and
  millisecond timestamps (without which two submits one interval apart are
  indistinguishable)
- `stop then restart`: a stopped engine restarts without a reset, the new run
  does not inherit the old counters — asserted on the `preparing` state the
  stream actually emits, since the terminal state is rebuilt either way — and
  a run publishes both lifecycle and verdict lines
- `SettingsPage`: renders the stored row, persists a slider release, warns
  when the user interval is below the floor; a colour picked (hex or preset
  swatch) under a preset theme is stored and switches to custom; a background
  applied while a dialog is open makes the pages transparent without closing
  it
- Debug mode: `AccountWorker` refuses an unrecognised mode with the flag off and
  submits it — carrying the server's own `xkms` verbatim — with it on;
  `xkms=0` needs no debug mode at all; the settings toggle persists and drives
  the `GrabberPage` banner. Driven through a recording `CampusAdapter` rather
  than by asserting on `Xkms.blockedReason`, which would pass with the bypass
  reverted.

`background_image_test.dart` covers seed extraction (dominant colour first,
none for a greyscale picture), magic-number sniffing, JSON / plain-text URL
extraction, and `BackgroundController` (import re-seeds the theme in one
write, a replaced picture is pruned, removal keeps the theme). Its loopback
group runs a fake **dual-end** image host that redirects by User-Agent, and
asserts the mobile and desktop clients get different pictures. It sets
`HttpOverrides.global = null`: `TestWidgetsFlutterBinding` otherwise answers
every request with 400 without touching the socket.

Run with `flutter test`. All tests must pass before committing.

New tests must be checked negatively — break the wiring under test and
confirm the case goes red. A green test proves nothing on its own; several of
these were written after a page was already wired, and only the negative check
distinguishes "asserts the behaviour" from "asserts a coincidence".

## Release & Identity

- **The app identifier is `top.code953.nkgrabber` on every platform.** It was
  `com.example.nkgrabber` (the `flutter create` default) until the first public
  release. Changing it after users install makes the new build a *different
  app* on Android rather than an upgrade, so it had to be settled before
  v1.0.0-beta. The Linux `APPLICATION_ID` is load-bearing rather than
  cosmetic: `g_set_prgname` publishes it as the Wayland `app_id` / X11
  `WM_CLASS`, and the compositor resolves it to `<id>.desktop` to find the
  icon. ID and desktop filename must stay identical.
- **The executable name stays `nkgrabber` (lowercase)** in both CMake
  `BINARY_NAME`s and macOS `PRODUCT_NAME`. Only the *display* name is
  `NKgrabber`. Renaming the binary would break the three hardcoded `TEST_HOST`
  paths in the macOS pbxproj and the `nkgrabber.app` path in `release.yml`.
- **Android release builds must not ship debug-signed.** `build.gradle.kts`
  loads `android/key.properties` when present and falls back to the debug key
  when absent, so a checkout without the keystore still builds. CI writes that
  file from secrets and **fails the job if the secret is missing** — a
  debug-signed release is the one mistake that cannot be corrected afterwards,
  since changing signatures forces every user to uninstall. The workflow then
  asserts on the certificate with `keytool -printcert`, because a successful
  build says nothing about which key signed it.
- **Icons are generated, not hand-placed.** `tool/gen_icon_variants.ps1`
  reshapes `assets/icon/icon.png` into the two variants the platforms actually
  need, then `flutter_launcher_icons.yaml` fans them out. Two things there are
  easy to get wrong and were:
  - The source art is a rounded square on an **opaque white** canvas. Removing
    those corners by colour-keying white punches transparent holes through the
    document, the graduation cap and the hand — the artwork's interior is full
    of white. The corners must be cut **geometrically**, by clipping to a
    rounded rectangle. The colour-keyed version still looked like an icon at a
    glance, which is what made it dangerous.
  - `flutter_launcher_icons` writes a 16% `<inset>` into
    `mipmap-anydpi-v26/ic_launcher.xml`, but `icon_foreground.png` is already
    pre-inset to 72%. Stacking both renders the art at ~60% of the canvas. The
    inset is removed by hand after generation — **re-check that file after
    re-running the generator**, which overwrites it.
- **`SHA256SUMS.txt` is generated from a flattened artifact directory**
  (`merge-multiple: true`). Without that, the paths recorded are
  `./windows-x64/nkgrabber-windows-x64.zip`, which never match the flat
  filenames the release serves, so `sha256sum -c` fails on every line.
- **The version lives in `pubspec.yaml` and is mirrored by
  `AppConstants.appVersion`**, pinned by a test that reads the pubspec. The
  About row used to carry its own literal, so bumping the pubspec left the UI
  reporting the previous version.

## CI/CD

- `.github/workflows/ci.yml` — runs on every PR: format check, analyze, test, generated-file consistency check.
- `.github/workflows/release.yml` — runs on `v*` tags: builds all 5 platforms, verifies the Android signing certificate, and creates a GitHub Release (not a pre-release since v1.0.1) with SHA256SUMS. iOS ships **unsigned** as `nkgrabber-ios-unsigned.ipa` for users to sign themselves: the `Runner.app` from `flutter build ios --no-codesign`, wrapped in `Payload/`, because that is the only layout most signing tools import — v1.0.1's zip of the bare `.app` had to be rewrapped by hand. `create-release` depends on it, so an iOS compile failure blocks the whole release. `create-release` collects artifacts by extension twice, in the `sha256sum` line and in `files:`; a new artifact type must go in both, or it is built and silently left out.
- **Platform permissions the network features need are declared explicitly.** macOS runs sandboxed, and a sandboxed app without `com.apple.security.network.client` cannot open an outgoing connection at all — both entitlements files carry it (plus `files.user-selected.read-only` for the background picker). Android's `INTERNET` permission is declared in the main manifest; it used to arrive only through `file_saver`'s manifest merge, so dropping that dependency would have silently cut release builds off the network. iOS declares `NSPhotoLibraryUsageDescription` for the picker.
- **`android/build.gradle.kts` applies the Kotlin plugin to `file_picker` by hand.** file_picker 11.x stops applying it under AGP 9 and relies on built-in Kotlin, which `gradle.properties` turns off (`android.builtInKotlin=false`, from the Flutter template). Nothing then compiles its Kotlin, and the only symptom is `GeneratedPluginRegistrant.java: cannot find symbol FilePickerPlugin` at the very end of the build — v1.0.2's Android job died on it. Upstream fixed it in 12.0.0, but every 12.x needs `win32 ^6`, which `flutter_secure_storage` 9 cannot share; moving to 10 changes how Android stores the saved credentials. Remove the block when both are upgraded together. `ci.yml` builds no platform, so a plugin that only breaks the Android compile surfaces first on a release tag.

## Commit Convention

Each phase of work gets its own commit. Use `feat: Phase N - description` format. Write commit messages in Simplified Chinese.

**After completing each functional update, perform a git commit immediately.** This ensures that each feature or fix is captured as a discrete checkpoint in version control.

**Every commit must be atomic: one logical change, complete, and nothing else.**
- *Complete* — the change carries everything it needs: the tests that pin it, regenerated `*.g.dart` / l10n output, and the docs that describe it (this file, `README.md`). Each commit must pass `flutter test` on its own; a commit that only works once the next one lands is not atomic.
- *Nothing else* — a formatting pass over a file the change does not touch, a version bump, a bug found along the way: each gets its own commit, however small. When the working tree holds more than one change, stage them separately (by path, or by hunk) rather than with `git add -A` / `git commit -a`.

One request can therefore end in several commits. That is the point: any one of them can be reverted, cherry-picked or bisected without dragging an unrelated change along.

## Sensitive Data Rules

Never commit or log:
- Passwords, cookies, `gdpk`, `JSESSIONID`
- Student numbers, real names
- Course IDs or names

Log the opaque account/target UUID instead — it is meaningless outside the local
database. Displaying these in the UI is fine (the user owns the data); writing
them to the log file is not.

`.env.example` documents no required variables — the client needs no build-time secrets.
