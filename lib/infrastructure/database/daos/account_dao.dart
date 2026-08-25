/// Data Access Object for the Account table.
///
/// Provides typed CRUD operations and query helpers for account management.
library;

import 'package:drift/drift.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/tables/accounts.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  /// Watch all accounts ordered by creation date (newest first).
  Stream<List<AccountEntry>> watchAll() {
    return (select(
      accounts,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  /// Get all accounts.
  Future<List<AccountEntry>> getAll() {
    return (select(
      accounts,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  /// Get all enabled accounts.
  Future<List<AccountEntry>> getEnabled() {
    return (select(accounts)..where((t) => t.enabled.equals(true))).get();
  }

  /// Get accounts with a specific status.
  Future<List<AccountEntry>> getByStatus(AccountStatus status) {
    return (select(accounts)..where((t) => t.status.equalsValue(status))).get();
  }

  /// Get a single account by ID.
  Future<AccountEntry?> getById(String id) {
    return (select(accounts)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new account.
  Future<void> insertAccount(AccountsCompanion entry) {
    return into(accounts).insert(entry);
  }

  /// Update an existing account.
  Future<bool> updateAccount(AccountsCompanion entry) {
    return (update(accounts)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Update only the status of an account.
  Future<void> updateStatus(String id, AccountStatus newStatus) {
    return (update(accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        status: Value(newStatus),
        updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
      ),
    );
  }

  /// Delete an account by ID (cascades to CourseTargets and GrabTasks).
  Future<int> deleteById(String id) {
    return (delete(accounts)..where((t) => t.id.equals(id))).go();
  }

  /// Count total accounts.
  Future<int> countAll() async {
    final count = accounts.id.count();
    final query = selectOnly(accounts)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Count enabled accounts.
  Future<int> countEnabled() async {
    final count = accounts.id.count();
    final query = selectOnly(accounts)
      ..addColumns([count])
      ..where(accounts.enabled.equals(true));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
