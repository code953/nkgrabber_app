/// Drift table definition for Account.
///
/// Stores campus system account information. Sensitive fields (password,
/// cookies) are stored only in platform secure storage; this table holds
/// reference IDs to those entries.
library;

import 'package:drift/drift.dart';

/// Account login type.
enum LoginType { password, cookie }

/// Account status reflecting campus session health.
enum AccountStatus {
  validating,
  ready,
  expired,
  captchaRequired,
  networkError,
  disabledByPlan,
}

@DataClassName('AccountEntry')
class Accounts extends Table {
  /// UUID v4 primary key.
  TextColumn get id => text()();

  /// Display name format: "姓名（学号后四位）".
  TextColumn get displayName => text()();

  /// Student number.
  TextColumn get studentNo => text()();

  /// Login method: 'password' or 'cookie'.
  TextColumn get loginType => textEnum<LoginType>()();

  /// Reference to secure storage entry for credentials.
  TextColumn get credentialRef => text().nullable()();

  /// Reference to the isolated Cookie Jar for this account.
  TextColumn get cookieJarRef => text()();

  /// Current account status.
  TextColumn get status => textEnum<AccountStatus>()();

  /// Last time the session was validated against campus.
  TextColumn get lastValidatedAt => text().nullable()();

  /// Whether this is a temporary (cookie-mode) account.
  BoolColumn get ephemeral => boolean().withDefault(const Constant(false))();

  /// Whether this account is enabled for grabbing.
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Reason for being disabled (e.g., plan limit exceeded).
  TextColumn get disabledReason => text().nullable()();

  /// When this account was created.
  TextColumn get createdAt => text()();

  /// Last modification timestamp.
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
