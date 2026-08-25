/// Data Access Object for the AppSettings table.
///
/// Single-row table managing user preferences with defaults.
library;

import 'package:drift/drift.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/tables/app_settings.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Get current settings (creates default row if absent).
  Future<AppSettingsEntry> get() async {
    final existing =
        await (select(appSettings)..where((t) => t.id.equals(1)))
            .getSingleOrNull();
    if (existing != null) return existing;

    // Create default settings row.
    await into(appSettings).insert(
      AppSettingsCompanion.insert(),
    );
    return (select(appSettings)..where((t) => t.id.equals(1))).getSingle();
  }

  /// Watch settings for reactive UI updates.
  Stream<AppSettingsEntry> watch() {
    return (select(appSettings)..where((t) => t.id.equals(1)))
        .watchSingle();
  }

  /// Update settings (always row id=1).
  Future<void> update_(AppSettingsCompanion entry) {
    return (update(appSettings)..where((t) => t.id.equals(1))).write(
      entry.copyWith(id: const Value(1)),
    );
  }

  /// Update theme.
  Future<void> setTheme(String theme) {
    return update_(AppSettingsCompanion(theme: Value(theme)));
  }

  /// Update user interval.
  Future<void> setUserIntervalMs(int ms) {
    return update_(AppSettingsCompanion(userIntervalMs: Value(ms)));
  }

  /// Update log level.
  Future<void> setLogLevel(String level) {
    return update_(AppSettingsCompanion(logLevel: Value(level)));
  }

  /// Update locale.
  Future<void> setLocale(String locale) {
    return update_(AppSettingsCompanion(locale: Value(locale)));
  }

  /// Update the request interval floor.
  Future<void> setMinRequestIntervalMs(int ms) {
    return update_(AppSettingsCompanion(minRequestIntervalMs: Value(ms)));
  }

  /// Update the maximum number of simultaneously enabled accounts.
  Future<void> setMaxAccounts(int count) {
    return update_(AppSettingsCompanion(maxAccounts: Value(count)));
  }

  /// Update the maximum number of accounts grabbing in parallel.
  Future<void> setMaxConcurrentAccounts(int count) {
    return update_(AppSettingsCompanion(maxConcurrentAccounts: Value(count)));
  }
}
