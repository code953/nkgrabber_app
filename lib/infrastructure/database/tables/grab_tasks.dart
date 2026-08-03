/// Drift table definition for GrabTask.
///
/// Records each grabbing task's lifecycle and results.
/// Linked to Account via cascading FK.
library;

import 'package:drift/drift.dart';
import 'package:nkgrabber/infrastructure/database/tables/accounts.dart';

/// Grabber state machine states (§9.1).
enum GrabTaskStatus {
  idle,
  preparing,
  running,
  paused,
  stopped,
  success,
  failed,
  interrupted,
  authExpired,
  captchaRequired,
}

@DataClassName('GrabTaskEntry')
class GrabTasks extends Table {
  /// UUID v4 primary key.
  TextColumn get id => text()();

  /// FK to Account.id — cascading delete.
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();

  /// JSON array of CourseTarget.id values assigned to this task.
  TextColumn get targetIdsJson => text()();

  /// Current task state in the state machine.
  TextColumn get status => textEnum<GrabTaskStatus>()();

  /// Effective request interval in milliseconds (max of user setting and plan minimum).
  IntColumn get effectiveIntervalMs => integer()();

  /// When the task started running.
  TextColumn get startedAt => text().nullable()();

  /// When the task was stopped/completed.
  TextColumn get stoppedAt => text().nullable()();

  /// Sanitized snapshot of the last submit result (JSON).
  TextColumn get lastResultJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
