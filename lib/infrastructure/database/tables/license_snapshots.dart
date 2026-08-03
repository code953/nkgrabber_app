/// Drift table definition for LicenseSnapshot.
///
/// Single-row table caching the last validated license information.
/// Used only for UI display and local expiry detection; actual grabbing
/// requires a fresh online validation (§4.4).
library;

import 'package:drift/drift.dart';

@DataClassName('LicenseSnapshotEntry')
class LicenseSnapshots extends Table {
  /// Singleton row ID (always 1).
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// Plan identifier from backend.
  TextColumn get planId => text()();

  /// Human-readable plan name.
  TextColumn get planName => text()();

  /// Maximum accounts allowed by this plan.
  IntColumn get maxAccounts => integer()();

  /// Minimum request interval enforced by plan (ms).
  IntColumn get minRequestIntervalMs => integer()();

  /// Maximum concurrent accounts for grabbing.
  IntColumn get maxConcurrentAccounts => integer()();

  /// Total license duration in days.
  IntColumn get licenseDurationDays => integer()();

  /// When the license expires (ISO 8601 UTC).
  TextColumn get expiresAt => text()();

  /// When this snapshot was last validated (ISO 8601 UTC).
  TextColumn get validatedAt => text()();

  /// Maximum devices allowed for this license.
  IntColumn get maxDevices => integer().withDefault(const Constant(1))();

  /// Hours before device can be unbound after binding.
  IntColumn get unbindCooldownHours =>
      integer().withDefault(const Constant(24))();

  @override
  Set<Column> get primaryKey => {id};
}
