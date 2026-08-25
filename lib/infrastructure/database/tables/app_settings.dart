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

  /// UI theme: 'simple', 'anime', or 'system'.
  TextColumn get theme => text().withDefault(const Constant('system'))();

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

  @override
  Set<Column> get primaryKey => {id};
}
