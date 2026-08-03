/// Drift table definition for CourseTarget.
///
/// Stores the user's course selection targets, each bound to an Account.
/// Cascading delete ensures targets are removed when their account is deleted.
library;

import 'package:drift/drift.dart';
import 'package:nkgrabber/infrastructure/database/tables/accounts.dart';

@DataClassName('CourseTargetEntry')
class CourseTargets extends Table {
  /// UUID v4 primary key.
  TextColumn get id => text()();

  /// FK to Account.id — cascading delete.
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();

  /// 选课批次 ID from campus system.
  TextColumn get xkid => text()();

  /// 选课模式: "1"=抢选, "2"=正选, "3"=补退选.
  TextColumn get xkms => text()();

  /// 课目号 — the real course number used for submission.
  TextColumn get kmh => text()();

  /// 选报课 ID — display group, may differ from kmh.
  TextColumn get xbkid => text().nullable()();

  /// Snapshot of batch name at configuration time.
  TextColumn get batchName => text()();

  /// Snapshot of course name at configuration time.
  TextColumn get courseName => text()();

  /// Priority ordering (lower = higher priority).
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// Whether this target is active.
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// When the course info was captured.
  TextColumn get snapshotAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
