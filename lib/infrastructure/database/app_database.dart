/// Main Drift database class for NKgrabber.
///
/// Aggregates all tables and DAOs, manages schema version and migrations.
/// Uses `NativeDatabase` with background isolate for optimal performance.
library;

import 'package:drift/drift.dart';
import 'package:nkgrabber/infrastructure/database/daos/account_dao.dart';
import 'package:nkgrabber/infrastructure/database/daos/course_target_dao.dart';
import 'package:nkgrabber/infrastructure/database/daos/grab_task_dao.dart';
import 'package:nkgrabber/infrastructure/database/daos/settings_dao.dart';
import 'package:nkgrabber/infrastructure/database/tables/accounts.dart';
import 'package:nkgrabber/infrastructure/database/tables/app_settings.dart';
import 'package:nkgrabber/infrastructure/database/tables/course_targets.dart';
import 'package:nkgrabber/infrastructure/database/tables/grab_tasks.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Accounts, CourseTargets, GrabTasks, AppSettings],
  daos: [AccountDao, CourseTargetDao, GrabTaskDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 7;

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
        // v1 → v2: online license business removed. Drop the snapshot table
        // that cached the server-issued plan.
        if (from < 2) {
          await m.database.customStatement(
            'DROP TABLE IF EXISTS license_snapshots',
          );
        }

        // v2 → v3: the limits formerly issued by the server plan became
        // local settings. Add the three new columns, then rebuild the table
        // to drop `update_channel` and `crash_reporting_enabled` (SQLite has
        // no DROP COLUMN, so alterTable recreates and copies).
        if (from < 3) {
          await m.addColumn(appSettings, appSettings.minRequestIntervalMs);
          await m.addColumn(appSettings, appSettings.maxAccounts);
          await m.addColumn(appSettings, appSettings.maxConcurrentAccounts);
          // TableMigration carries drift's @experimental annotation, but it is
          // the documented way to drop a column and has been stable for years.
          // The alternative is hand-rolling SQLite's 12-step table rebuild
          // with a hardcoded column list that silently rots on schema change.
          // ignore: experimental_member_use
          await m.alterTable(TableMigration(appSettings));
        }

        // v3 → v4: debug mode. Defaults to false, so an upgraded install
        // behaves exactly as before until the user turns it on.
        if (from < 4) {
          await m.addColumn(appSettings, appSettings.debugModeEnabled);
        }

        // v4 → v5: targets snapshot the batch's zdxk so the grab path no
        // longer spends a round trip re-reading it. Existing rows default to
        // 1 — one course per submit, which is what the old conservative
        // fallback did whenever the re-read failed.
        if (from < 5) {
          await m.addColumn(courseTargets, courseTargets.zdxk);
        }

        // v5 → v6: custom theme color support. Allows users to define their
        // own primary color via a color picker.
        if (from < 6) {
          await m.addColumn(appSettings, appSettings.customThemeColor);
        }

        // v6 → v7: custom background image. All nullable or defaulted, so an
        // upgraded install shows no background until the user picks one.
        if (from < 7) {
          await m.addColumn(appSettings, appSettings.backgroundImageFile);
          await m.addColumn(appSettings, appSettings.backgroundImageUrl);
          await m.addColumn(appSettings, appSettings.backgroundImageClient);
          await m.addColumn(appSettings, appSettings.backgroundOverlayPercent);
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys for cascade delete support.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
