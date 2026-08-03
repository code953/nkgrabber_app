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
  TextColumn get theme =>
      text().withDefault(const Constant('system'))();

  /// User-configured request interval in milliseconds.
  IntColumn get userIntervalMs =>
      integer().withDefault(const Constant(1000))();

  /// Update channel preference.
  TextColumn get updateChannel =>
      text().withDefault(const Constant('stable'))();

  /// Minimum log level: 'debug', 'info', 'warn', 'error'.
  TextColumn get logLevel =>
      text().withDefault(const Constant('info'))();

  /// UI locale code.
  TextColumn get locale =>
      text().withDefault(const Constant('zh_CN'))();

  /// Whether crash reporting is enabled (opt-out).
  BoolColumn get crashReportingEnabled =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
