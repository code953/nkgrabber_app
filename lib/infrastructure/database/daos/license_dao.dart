/// Data Access Object for the LicenseSnapshot table.
///
/// Single-row table storing the last validated license data.
/// Used for UI display and local expiry detection only.
library;

import 'package:drift/drift.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/tables/license_snapshots.dart';

part 'license_dao.g.dart';

@DriftAccessor(tables: [LicenseSnapshots])
class LicenseDao extends DatabaseAccessor<AppDatabase>
    with _$LicenseDaoMixin {
  LicenseDao(super.db);

  /// Get the current license snapshot (singleton row).
  Future<LicenseSnapshotEntry?> get() {
    return (select(licenseSnapshots)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  /// Watch the license snapshot for reactive UI updates.
  Stream<LicenseSnapshotEntry?> watch() {
    return (select(licenseSnapshots)..where((t) => t.id.equals(1)))
        .watchSingleOrNull();
  }

  /// Upsert the license snapshot (always row id=1).
  Future<void> upsert(LicenseSnapshotsCompanion entry) {
    return into(licenseSnapshots).insertOnConflictUpdate(
      entry.copyWith(id: const Value(1)),
    );
  }

  /// Delete the license snapshot (on deactivation).
  Future<int> clear() {
    return (delete(licenseSnapshots)..where((t) => t.id.equals(1))).go();
  }

  /// Check whether a license exists locally.
  Future<bool> exists() async {
    final row = await get();
    return row != null;
  }

  /// Check whether the locally cached license has expired.
  Future<bool> isExpired() async {
    final row = await get();
    if (row == null) return true;
    final expires = DateTime.tryParse(row.expiresAt);
    if (expires == null) return true;
    return DateTime.now().toUtc().isAfter(expires);
  }
}
