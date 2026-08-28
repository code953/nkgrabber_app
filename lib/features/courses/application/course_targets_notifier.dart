/// Course targets notifier.
///
/// Manages CRUD operations on course targets and priority ordering.
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/features/accounts/application/accounts_notifier.dart';
import 'package:nkgrabber/infrastructure/campus/models/campus_models.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/daos/course_target_dao.dart';
import 'package:nkgrabber/infrastructure/providers.dart';
import 'package:uuid/uuid.dart';

/// The account whose course targets are being configured.
///
/// Null until the user picks one; the course page shows a picker in that case.
final selectedAccountIdProvider = StateProvider<String?>((ref) => null);

/// Course targets for [selectedAccountIdProvider].
///
/// Family-keyed on the account id so switching accounts yields a fresh
/// notifier instead of leaking the previous account's targets.
final courseTargetsProvider =
    StateNotifierProvider.family<
      CourseTargetsNotifier,
      CourseTargetsState,
      String
    >((ref, accountId) {
      return CourseTargetsNotifier(
        courseTargetDao: ref.watch(courseTargetDaoProvider),
        accountId: accountId,
      )..load();
    });

/// Selection batches fetched from the campus system for a given account.
///
/// This is the one place the course page touches the network. It fails loudly
/// rather than returning an empty list, so "not logged in" never looks like
/// "no batches available".
final batchesProvider = FutureProvider.family<List<SelectionBatch>, String>((
  ref,
  accountId,
) async {
  final adapter = await ref
      .watch(accountsProvider.notifier)
      .ensureAdapter(accountId);
  if (adapter == null) {
    throw StateError('账号登录已失效，请重新添加账号');
  }
  return adapter.listBatches();
});

/// Courses available within a batch.
final coursesProvider =
    FutureProvider.family<List<Course>, ({String accountId, String xkid})>((
      ref,
      key,
    ) async {
      final adapter = await ref
          .watch(accountsProvider.notifier)
          .ensureAdapter(key.accountId);
      if (adapter == null) {
        throw StateError('账号登录已失效，请重新添加账号');
      }
      return adapter.listCourses(key.xkid);
    });

/// State for the course targets list.
class CourseTargetsState {
  const CourseTargetsState({
    this.targets = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CourseTargetEntry> targets;
  final bool isLoading;
  final String? error;

  CourseTargetsState copyWith({
    List<CourseTargetEntry>? targets,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CourseTargetsState(
      targets: targets ?? this.targets,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Manages course targets for a specific account.
class CourseTargetsNotifier extends StateNotifier<CourseTargetsState> {
  CourseTargetsNotifier({
    required CourseTargetDao courseTargetDao,
    required String accountId,
  }) : _dao = courseTargetDao,
       _accountId = accountId,
       super(const CourseTargetsState());

  final CourseTargetDao _dao;
  final String _accountId;
  final _logger = AppLogger('CourseTargets');

  /// Load all targets for the current account.
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final targets = await _dao.getByAccount(_accountId);
    state = state.copyWith(targets: targets, isLoading: false);
  }

  /// Add a new course target.
  Future<bool> addTarget({
    required String xkid,
    required String xkms,
    required String kmh,
    required String courseName,
    required String batchName,
    required int zdxk,
    String? xbkid,
  }) async {
    try {
      // Check for duplicate.
      final existing = await _dao.findByAccountAndXkid(_accountId, xkid);
      if (existing != null && existing.kmh == kmh) {
        state = state.copyWith(error: '该课程已在目标列表中');
        return false;
      }

      final now = DateTime.now().toUtc().toIso8601String();
      final currentCount = await _dao.countByAccount(_accountId);

      await _dao.insertTarget(
        CourseTargetsCompanion.insert(
          id: const Uuid().v4(),
          accountId: _accountId,
          xkid: xkid,
          xkms: xkms,
          kmh: kmh,
          zdxk: Value(zdxk),
          xbkid: Value(xbkid),
          batchName: batchName,
          courseName: courseName,
          priority: Value(currentCount),
          snapshotAt: now,
        ),
      );

      await load();
      // Course names are sensitive; log the opaque target key instead.
      _logger.info('Target added for batch $xkid');
      return true;
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Remove a target by ID.
  Future<void> removeTarget(String id) async {
    await _dao.deleteById(id);
    await load();
  }

  /// Remove all targets for the current account.
  Future<void> removeAll() async {
    await _dao.deleteByAccount(_accountId);
    await load();
  }

  /// Toggle target enabled state.
  Future<void> toggleEnabled(String id, {required bool enabled}) async {
    await _dao.updateTarget(
      CourseTargetsCompanion(id: Value(id), enabled: Value(enabled)),
    );
    await load();
  }

  /// Reorder targets by updating priorities.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final targets = List<CourseTargetEntry>.from(state.targets);
    if (oldIndex >= targets.length || newIndex >= targets.length) return;

    final item = targets.removeAt(oldIndex);
    targets.insert(newIndex, item);

    // Update all priorities.
    for (var i = 0; i < targets.length; i++) {
      await _dao.updateTarget(
        CourseTargetsCompanion(id: Value(targets[i].id), priority: Value(i)),
      );
    }
    await load();
  }

  /// Get enabled targets ordered by priority.
  Future<List<CourseTargetEntry>> getEnabledTargets() async {
    return _dao.getEnabledByAccount(_accountId);
  }
}
