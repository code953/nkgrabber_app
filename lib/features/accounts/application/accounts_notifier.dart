/// Accounts feature notifier.
///
/// Manages the lifecycle of campus accounts: add, remove, validate,
/// enable/disable, and enforce plan limits.
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/core/security/secure_storage.dart';
import 'package:nkgrabber/core/security/secure_storage_keys.dart';
import 'package:nkgrabber/core/utils/extensions.dart';
import 'package:nkgrabber/infrastructure/campus/campus_adapter.dart';
import 'package:nkgrabber/infrastructure/campus/campus_adapter_impl.dart';
import 'package:nkgrabber/infrastructure/campus/campus_client_factory.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/daos/account_dao.dart';
import 'package:nkgrabber/infrastructure/database/tables/accounts.dart';
import 'package:uuid/uuid.dart';

/// State for the accounts list.
class AccountsState {
  const AccountsState({
    this.accounts = const [],
    this.isLoading = false,
    this.error,
  });

  final List<AccountEntry> accounts;
  final bool isLoading;
  final String? error;

  AccountsState copyWith({
    List<AccountEntry>? accounts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Manages campus accounts.
class AccountsNotifier extends StateNotifier<AccountsState> {
  AccountsNotifier({
    required AccountDao accountDao,
    required SecureStorage secureStorage,
  })  : _accountDao = accountDao,
        _secureStorage = secureStorage,
        super(const AccountsState());

  final AccountDao _accountDao;
  final SecureStorage _secureStorage;
  final _logger = AppLogger('AccountsNotifier');

  /// Active campus adapters keyed by account ID.
  final Map<String, CampusAdapter> _adapters = {};

  /// Load all accounts from the database.
  Future<void> loadAccounts() async {
    state = state.copyWith(isLoading: true);
    final accounts = await _accountDao.getAll();
    state = state.copyWith(accounts: accounts, isLoading: false);
  }

  /// Add a new account via password login.
  Future<bool> addByPassword({
    required String studentNo,
    required String password,
    required bool rememberPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final client = CampusClient(accountId: studentNo);
      final adapter = CampusAdapterImpl(client: client);

      final result = await adapter.loginWithPassword(studentNo, password);
      final id = const Uuid().v4();
      final now = DateTime.now().toUtc().toIso8601String();

      // Save password to secure storage if requested.
      String? credentialRef;
      if (rememberPassword) {
        credentialRef = SecureStorageKeys.accountPassword(id);
        await _secureStorage.write(
          key: credentialRef,
          value: password,
        );
      }

      // Save cookies to secure storage.
      final cookieRef = SecureStorageKeys.accountCookies(id);
      await _secureStorage.write(key: cookieRef, value: result.gdpk);

      await _accountDao.insertAccount(
        AccountsCompanion.insert(
          id: id,
          displayName: '${result.studentName}（${studentNo.lastN(4)}）',
          studentNo: result.studentNo,
          loginType: LoginType.password,
          credentialRef: Value(credentialRef),
          cookieJarRef: cookieRef,
          status: AccountStatus.ready,
          lastValidatedAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
      );

      _adapters[id] = adapter;
      await loadAccounts();
      _logger.info('Account added: ${result.studentName}');
      return true;
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      _logger.warn('Failed to add account by password', e);
      return false;
    }
  }

  /// Add a new account via cookie (ephemeral mode).
  Future<bool> addByCookie({required String gdpk}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final client = CampusClient(accountId: 'cookie-tmp');
      final adapter = CampusAdapterImpl(client: client);

      final profile = await adapter.validateCookie(gdpk);
      final id = const Uuid().v4();
      final now = DateTime.now().toUtc().toIso8601String();

      final cookieRef = SecureStorageKeys.accountCookies(id);
      await _secureStorage.write(key: cookieRef, value: gdpk);

      await _accountDao.insertAccount(
        AccountsCompanion.insert(
          id: id,
          displayName: '${profile.studentName}（${profile.studentNo.lastN(4)}）',
          studentNo: profile.studentNo,
          loginType: LoginType.cookie,
          cookieJarRef: cookieRef,
          status: AccountStatus.ready,
          lastValidatedAt: Value(now),
          ephemeral: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );

      _adapters[id] = adapter;
      await loadAccounts();
      _logger.info('Cookie account added: ${profile.studentName}');
      return true;
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      _logger.warn('Failed to add account by cookie', e);
      return false;
    }
  }

  /// Remove an account and its related secure data.
  Future<void> removeAccount(String id) async {
    final account = await _accountDao.getById(id);
    if (account == null) return;

    // Clean up secure storage.
    if (account.credentialRef != null) {
      await _secureStorage.delete(key: account.credentialRef!);
    }
    await _secureStorage.delete(key: account.cookieJarRef);

    // Clean up adapter.
    _adapters.remove(id);

    // Delete from DB (cascades to CourseTargets and GrabTasks).
    await _accountDao.deleteById(id);
    await loadAccounts();
    _logger.info('Account removed: ${account.displayName}');
  }

  /// Enforce plan account limit.
  ///
  /// When entitlements decrease, disables accounts from newest to oldest.
  /// When slots are freed, re-enables from oldest to newest.
  Future<void> enforcePlanLimit(int maxAccounts) async {
    final accounts = await _accountDao.getAll();
    final enabledCount =
        accounts.where((a) => a.enabled).length;

    if (enabledCount > maxAccounts) {
      // Disable excess accounts from newest to oldest.
      final toDisable = enabledCount - maxAccounts;
      final sorted = accounts.where((a) => a.enabled).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      for (var i = 0; i < toDisable && i < sorted.length; i++) {
        await _accountDao.updateAccount(
          AccountsCompanion(
            id: Value(sorted[i].id),
            enabled: const Value(false),
            disabledReason: const Value('超出计划限额'),
            status: const Value(AccountStatus.disabledByPlan),
            updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
          ),
        );
      }
    } else if (enabledCount < maxAccounts) {
      // Re-enable disabled accounts from oldest to newest.
      final disabled = accounts
          .where(
            (a) => !a.enabled && a.status == AccountStatus.disabledByPlan,
          )
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final toEnable = maxAccounts - enabledCount;
      for (var i = 0; i < toEnable && i < disabled.length; i++) {
        await _accountDao.updateAccount(
          AccountsCompanion(
            id: Value(disabled[i].id),
            enabled: const Value(true),
            disabledReason: const Value(null),
            status: const Value(AccountStatus.ready),
            updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
          ),
        );
      }
    }

    await loadAccounts();
  }

  /// Get or create the campus adapter for an account.
  CampusAdapter? getAdapter(String accountId) => _adapters[accountId];

  /// Clean up ephemeral accounts on normal exit.
  Future<void> cleanupEphemeral() async {
    final accounts = await _accountDao.getAll();
    for (final account in accounts) {
      if (account.ephemeral) {
        await removeAccount(account.id);
      }
    }
  }
}
