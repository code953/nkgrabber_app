/// Main Drift database class for NKgrabber.
///
/// Aggregates all tables and DAOs, manages schema version and migrations.
/// Uses `NativeDatabase` with background isolate for optimal performance.
library;

import 'package:drift/drift.dart';
import 'package:nkgrabber/infrastructure/database/daos/account_dao.dart';
import 'package:nkgrabber/infrastructure/database/daos/course_target_dao.dart';
import 'package:nkgrabber/infrastructure/database/daos/grab_task_dao.dart';
import 'package:nkgrabber/infrastructure/database/daos/license_dao.dart';
import 'package:nkgrabber/infrastructure/database/daos/settings_dao.dart';
import 'package:nkgrabber/infrastructure/database/tables/accounts.dart';
import 'package:nkgrabber/infrastructure/database/tables/app_settings.dart';
import 'package:nkgrabber/infrastructure/database/tables/course_targets.dart';
import 'package:nkgrabber/infrastructure/database/tables/grab_tasks.dart';
import 'package:nkgrabber/infrastructure/database/tables/license_snapshots.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    CourseTargets,
    GrabTasks,
    LicenseSnapshots,
    AppSettings,
  ],
  daos: [
    AccountDao,
    CourseTargetDao,
    GrabTaskDao,
    LicenseDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Create indexes for performance.
        await m.database.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_course_target_account_xkid '
          'ON course_targets (account_id, xkid)',
        );
        await m.database.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_grab_task_account_status '
          'ON grab_tasks (account_id, status)',
        );

        // Insert default settings row.
        await m.database.customStatement(
          'INSERT OR IGNORE INTO app_settings (id) VALUES (1)',
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations go here.
        // Each version bump adds a case to handle the incremental change.
      },
      beforeOpen: (details) async {
        // Enable foreign keys for cascade delete support.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
