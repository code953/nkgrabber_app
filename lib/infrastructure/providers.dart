/// Riverpod providers for database and secure storage.
///
/// These are keepAlive providers since the database and storage
/// instances should persist for the entire app lifecycle.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/core/security/secure_storage.dart';
import 'package:nkgrabber/core/security/secure_storage_impl.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/connection/native.dart';
import 'package:nkgrabber/infrastructure/database/daos/account_dao.dart';
import 'package:nkgrabber/infrastructure/database/daos/course_target_dao.dart';
import 'package:nkgrabber/infrastructure/database/daos/grab_task_dao.dart';
import 'package:nkgrabber/infrastructure/database/daos/settings_dao.dart';

/// Provides the singleton [AppDatabase] instance.
///
/// keepAlive ensures the database connection persists across the app lifecycle.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(createNativeDatabase());
  ref.onDispose(db.close);
  return db;
});

/// Provides the singleton [SecureStorage] instance.
///
/// keepAlive ensures the storage adapter persists across the app lifecycle.
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorageImpl();
});

// ─── DAOs ──────────────────────────────────────────────────────────────────
// Thin accessors over the single AppDatabase instance. They hold no state of
// their own, so they inherit its lifecycle rather than registering a dispose.

/// Provides the [AccountDao].
final accountDaoProvider = Provider<AccountDao>((ref) {
  return ref.watch(appDatabaseProvider).accountDao;
});

/// Provides the [CourseTargetDao].
final courseTargetDaoProvider = Provider<CourseTargetDao>((ref) {
  return ref.watch(appDatabaseProvider).courseTargetDao;
});

/// Provides the [GrabTaskDao].
final grabTaskDaoProvider = Provider<GrabTaskDao>((ref) {
  return ref.watch(appDatabaseProvider).grabTaskDao;
});

/// Provides the [SettingsDao].
final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return ref.watch(appDatabaseProvider).settingsDao;
});

/// Exposes the singleton settings row and persists edits.
///
/// A `StreamProvider` over `SettingsDao.watch()` would be the obvious fit, but
/// drift schedules a zero-duration cleanup timer when a query stream is
/// cancelled, and in widget tests that timer outlives the framework's final
/// pump — every test then fails with "A Timer is still pending". Reading once
/// and re-reading after each write avoids the stream without giving up
/// reactivity, since this row only ever changes through this notifier.
final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettingsEntry>(
      AppSettingsNotifier.new,
    );

/// Reads and writes the singleton `app_settings` row.
class AppSettingsNotifier extends AsyncNotifier<AppSettingsEntry> {
  @override
  Future<AppSettingsEntry> build() => ref.watch(settingsDaoProvider).get();

  Future<void> _apply(Future<void> Function(SettingsDao dao) write) async {
    final dao = ref.read(settingsDaoProvider);
    await write(dao);
    state = AsyncData(await dao.get());
  }

  /// Persist the UI theme.
  Future<void> setTheme(String theme) => _apply((d) => d.setTheme(theme));

  /// Persist the user-requested request interval.
  Future<void> setUserIntervalMs(int ms) =>
      _apply((d) => d.setUserIntervalMs(ms));

  /// Persist the request interval floor.
  Future<void> setMinRequestIntervalMs(int ms) =>
      _apply((d) => d.setMinRequestIntervalMs(ms));

  /// Persist the maximum number of enabled accounts.
  Future<void> setMaxAccounts(int count) =>
      _apply((d) => d.setMaxAccounts(count));

  /// Persist the maximum number of accounts grabbing in parallel.
  Future<void> setMaxConcurrentAccounts(int count) =>
      _apply((d) => d.setMaxConcurrentAccounts(count));

  /// Persist the debug-mode flag.
  ///
  /// Positional so it can be passed straight to `SwitchListTile.onChanged`.
  // ignore: avoid_positional_boolean_parameters
  Future<void> setDebugModeEnabled(bool enabled) =>
      _apply((d) => d.setDebugModeEnabled(enabled));

  /// Persist the custom theme color (ARGB hex string).
  Future<void> setCustomThemeColor(String? colorHex) =>
      _apply((d) => d.setCustomThemeColor(colorHex));
}
