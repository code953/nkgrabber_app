/// Data Access Object for the CourseTarget table.
///
/// Provides CRUD and query operations for course selection targets.
library;

import 'package:drift/drift.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/tables/course_targets.dart';

part 'course_target_dao.g.dart';

@DriftAccessor(tables: [CourseTargets])
class CourseTargetDao extends DatabaseAccessor<AppDatabase>
    with _$CourseTargetDaoMixin {
  CourseTargetDao(super.db);

  /// Watch all targets for a given account, ordered by priority.
  Stream<List<CourseTargetEntry>> watchByAccount(String accountId) {
    return (select(courseTargets)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
        .watch();
  }

  /// Get all targets for a given account.
  Future<List<CourseTargetEntry>> getByAccount(String accountId) {
    return (select(courseTargets)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
        .get();
  }

  /// Get all enabled targets for a given account.
  Future<List<CourseTargetEntry>> getEnabledByAccount(String accountId) {
    return (select(courseTargets)
          ..where((t) => t.accountId.equals(accountId) & t.enabled.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
        .get();
  }

  /// Get a single target by ID.
  Future<CourseTargetEntry?> getById(String id) {
    return (select(
      courseTargets,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Check if a target with the same accountId+xkid already exists.
  Future<CourseTargetEntry?> findByAccountAndXkid(
    String accountId,
    String xkid,
  ) {
    return (select(courseTargets)
          ..where((t) => t.accountId.equals(accountId) & t.xkid.equals(xkid)))
        .getSingleOrNull();
  }

  /// Insert a new course target.
  Future<void> insertTarget(CourseTargetsCompanion entry) {
    return into(courseTargets).insert(entry);
  }

  /// Insert multiple targets in a batch.
  Future<void> insertAll(List<CourseTargetsCompanion> entries) {
    return batch((b) {
      b.insertAll(courseTargets, entries);
    });
  }

  /// Update a target.
  Future<bool> updateTarget(CourseTargetsCompanion entry) {
    return (update(courseTargets)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Delete a target by ID.
  Future<int> deleteById(String id) {
    return (delete(courseTargets)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all targets for an account.
  Future<int> deleteByAccount(String accountId) {
    return (delete(
      courseTargets,
    )..where((t) => t.accountId.equals(accountId))).go();
  }

  /// Count targets for an account.
  Future<int> countByAccount(String accountId) async {
    final count = courseTargets.id.count();
    final query = selectOnly(courseTargets)
      ..addColumns([count])
      ..where(courseTargets.accountId.equals(accountId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
