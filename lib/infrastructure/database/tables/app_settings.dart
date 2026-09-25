/// Drift table definition for AppSettings.
///
/// Single-row table storing user preferences.
/// Defaults are applied at the database level.
library;

import 'package:drift/drift.dart';

@DataClassName('AppSettingsEntry')
class AppSettings extends Table {
  /// Singleton row ID (always 1).
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// UI theme: 'simple', 'anime', 'system', or 'custom'.
  TextColumn get theme => text().withDefault(const Constant('system'))();

  /// Custom theme seed color (ARGB hex string), null if not using custom theme.
  TextColumn get customThemeColor => text().nullable()();

  /// File name of the background image inside the app's background directory,
  /// or null for no background.
  ///
  /// A bare name, never an absolute path: iOS moves the app container on
  /// every update, so a stored absolute path would point at nothing after the
  /// first upgrade.
  TextColumn get backgroundImageFile => text().nullable()();

  /// Image-host URL the background was downloaded from; null for a local file.
  ///
  /// Kept so the user can re-fetch — random-image APIs return a new picture
  /// on every request, which is the whole reason the result is cached on disk
  /// rather than loaded from the network on each launch.
  TextColumn get backgroundImageUrl => text().nullable()();

  /// Which kind of device to present as when fetching [backgroundImageUrl]:
  /// null (follow the platform), 'desktop', or 'mobile'.
  ///
  /// Many image hosts serve a landscape picture to desktop browsers and a
  /// portrait one to phones, deciding by User-Agent.
  TextColumn get backgroundImageClient => text().nullable()();

  /// Opacity (0–100) of the surface-coloured scrim drawn over the background
  /// image so text stays readable.
  IntColumn get backgroundOverlayPercent =>
      integer().withDefault(const Constant(60))();

  /// User-configured request interval in milliseconds.
  IntColumn get userIntervalMs => integer().withDefault(const Constant(1000))();

  /// Floor for the request interval (ms).
  ///
  /// `effectiveIntervalMs = max(userIntervalMs, minRequestIntervalMs)` —
  /// protects the campus server and keeps the client below the rate at
  /// which its risk control kicks in.
  IntColumn get minRequestIntervalMs =>
      integer().withDefault(const Constant(800))();

  /// Maximum number of simultaneously enabled accounts.
  IntColumn get maxAccounts => integer().withDefault(const Constant(5))();

  /// Maximum number of accounts grabbing in parallel.
  IntColumn get maxConcurrentAccounts =>
      integer().withDefault(const Constant(3))();

  /// Minimum log level: 'debug', 'info', 'warn', 'error'.
  TextColumn get logLevel => text().withDefault(const Constant('info'))();

  /// UI locale code.
  TextColumn get locale => text().withDefault(const Constant('zh_CN'))();

  /// Debug mode: submit against batches the client would otherwise refuse.
  ///
  /// Normally a batch whose `xkms` is `"0"` (closed) or unrecognised is not
  /// submittable, and both the batch picker and `AccountWorker` refuse it.
  /// With this on, the refusal is skipped and the request goes out carrying
  /// the server's own `xkms` verbatim — the point is to observe what the
  /// campus system actually answers, so faking a submittable mode would
  /// destroy the only signal the mode exists to collect.
  BoolColumn get debugModeEnabled =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
