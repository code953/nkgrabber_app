/// Data Access Object for the GrabTask table.
///
/// Provides CRUD and query operations for grab task records.
library;

import 'package:drift/drift.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/tables/grab_tasks.dart';

part 'grab_task_dao.g.dart';

@DriftAccessor(tables: [GrabTasks])
class GrabTaskDao extends DatabaseAccessor<AppDatabase>
    with _$GrabTaskDaoMixin {
  GrabTaskDao(super.db);

  /// Watch all tasks for a given account.
  Stream<List<GrabTaskEntry>> watchByAccount(String accountId) {
    return (select(grabTasks)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  /// Get all tasks for a given account.
  Future<List<GrabTaskEntry>> getByAccount(String accountId) {
    return (select(grabTasks)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  /// Get tasks by status (across all accounts).
  Future<List<GrabTaskEntry>> getByStatus(GrabTaskStatus status) {
    return (select(grabTasks)
          ..where((t) => t.status.equalsValue(status)))
        .get();
  }

  /// Get a single task by ID.
  Future<GrabTaskEntry?> getById(String id) {
    return (select(grabTasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get the most recent task for an account (regardless of status).
  Future<GrabTaskEntry?> getLatestByAccount(String accountId) {
    return (select(grabTasks)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get all running/preparing tasks (for crash recovery detection).
  Future<List<GrabTaskEntry>> getActiveTasks() {
    return (select(grabTasks)
          ..where(
            (t) =>
                t.status.equalsValue(GrabTaskStatus.running) |
                t.status.equalsValue(GrabTaskStatus.preparing),
          ))
        .get();
  }

  /// Insert a new task.
  Future<void> insertTask(GrabTasksCompanion entry) {
    return into(grabTasks).insert(entry);
  }

  /// Update a task.
  Future<bool> updateTask(GrabTasksCompanion entry) {
    return (update(grabTasks)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Update only the status of a task.
  Future<void> updateStatus(String id, GrabTaskStatus newStatus) {
    return (update(grabTasks)..where((t) => t.id.equals(id))).write(
      GrabTasksCompanion(status: Value(newStatus)),
    );
  }

  /// Mark running/preparing tasks as interrupted (for crash recovery).
  Future<int> markActiveAsInterrupted() {
    return (update(grabTasks)
          ..where(
            (t) =>
                t.status.equalsValue(GrabTaskStatus.running) |
                t.status.equalsValue(GrabTaskStatus.preparing),
          ))
        .write(
      GrabTasksCompanion(
        status: const Value(GrabTaskStatus.interrupted),
        stoppedAt: Value(DateTime.now().toUtc().toIso8601String()),
      ),
    );
  }

  /// Delete a task by ID.
  Future<int> deleteById(String id) {
    return (delete(grabTasks)..where((t) => t.id.equals(id))).go();
  }

  /// Get recent tasks (for diagnostics export, last 3).
  Future<List<GrabTaskEntry>> getRecent({int limit = 3}) {
    return (select(grabTasks)
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit))
        .get();
  }
}
