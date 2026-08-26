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
