/// Grabber engine — orchestrates parallel account workers.
///
/// Manages the full grabber state machine (§9.1), enforces
/// 30-minute timeout, concurrency limits, and interval guarantees.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/core/utils/constants.dart';
import 'package:nkgrabber/features/grabber/application/account_worker.dart';
import 'package:nkgrabber/features/grabber/application/retry_classifier.dart';
import 'package:nkgrabber/features/grabber/domain/grabber_state.dart';
import 'package:nkgrabber/infrastructure/campus/campus_adapter.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/daos/course_target_dao.dart';
import 'package:nkgrabber/infrastructure/database/daos/grab_task_dao.dart';
import 'package:nkgrabber/infrastructure/database/tables/grab_tasks.dart';
import 'package:uuid/uuid.dart';

/// Callback to get the campus adapter for an account.
///
/// Async because adapters live only in memory: after a restart the account
/// exists in the database but has no client, and rebuilding one requires
/// reading the stored cookie.
typedef AdapterResolver = Future<CampusAdapter?> Function(String accountId);

/// The main grabber engine.
class GrabberEngine {
  GrabberEngine({
    required CourseTargetDao courseTargetDao,
    required GrabTaskDao grabTaskDao,
    required AdapterResolver adapterResolver,
    required int maxConcurrentAccounts,
    required int minRequestIntervalMs,
    required int userIntervalMs,
  }) : _courseTargetDao = courseTargetDao,
       _grabTaskDao = grabTaskDao,
       _adapterResolver = adapterResolver,
       _maxConcurrent = maxConcurrentAccounts,
       _effectiveIntervalMs = max(userIntervalMs, minRequestIntervalMs);

  final CourseTargetDao _courseTargetDao;
  final GrabTaskDao _grabTaskDao;
  final AdapterResolver _adapterResolver;
  final int _maxConcurrent;

  /// Effective interval: max of the user setting and the local floor.
  /// Jitter is applied upward only, never below the floor.
  final int _effectiveIntervalMs;

  final _logger = AppLogger('GrabberEngine');
  final _workers = <String, AccountWorker>{};
  Timer? _timeoutTimer;
  GrabberState _state = const GrabberState();
  final _stateController = StreamController<GrabberState>.broadcast();
  bool _disposed = false;

  /// Stream of state changes for UI binding.
  Stream<GrabberState> get stateStream => _stateController.stream;

  /// Current state.
  GrabberState get state => _state;

  /// Start the grabber for the given account IDs.
  Future<void> start(List<String> accountIds) async {
    if (_state.isRunning) {
      _logger.warn('Grabber already running, ignoring start');
      return;
    }

    _updateState(
      _state.copyWith(
        status: GrabberStatus.preparing,
        clearMessage: true,
        startedAt: DateTime.now().toUtc(),
        activeAccountIds: accountIds,
      ),
    );

    // Step 1: Gather targets per account.
    final accountTargets = <String, List<CourseTargetEntry>>{};
    var totalTargets = 0;

    for (final accountId in accountIds) {
      final targets = await _courseTargetDao.getEnabledByAccount(accountId);
      if (targets.isNotEmpty) {
        accountTargets[accountId] = targets;
        totalTargets += targets.length;
      }
    }

    if (accountTargets.isEmpty) {
      _updateState(
        _state.copyWith(status: GrabberStatus.failed, message: '没有可用的课程目标'),
      );
      return;
    }

    _updateState(
      _state.copyWith(
        status: GrabberStatus.running,
        totalTargets: totalTargets,
      ),
    );

    // Step 2: Start 30-minute timeout timer.
    _timeoutTimer = Timer(
      const Duration(minutes: AppConstants.maxGrabTaskRuntimeMinutes),
      _onTimeout,
    );

    // Step 3: Create task records and launch workers.
    final completedTargets = <String>[];
    final failedTargets = <String>[];

    // Limit concurrent accounts.
    final activeIds = accountTargets.keys.take(_maxConcurrent).toList();

    // Track task IDs for finalization.
    final taskIds = <String, String>{};

    final futures = <Future<void>>[];

    for (final accountId in activeIds) {
      final adapter = await _adapterResolver(accountId);
      if (adapter == null) {
        _logger.warn('No adapter for account $accountId');
        continue;
      }

      final worker = AccountWorker(
        accountId: accountId,
        adapter: adapter,
        effectiveIntervalMs: _effectiveIntervalMs,
        onTargetResult: (targetId, {required bool success, String? message}) {
          if (success) {
            completedTargets.add(targetId);
            _updateState(
              _state.copyWith(
                completedTargets: List.from(completedTargets),
                successCount: completedTargets.length,
              ),
            );
          } else {
            failedTargets.add(targetId);
            _updateState(
              _state.copyWith(
                failedTargets: List.from(failedTargets),
                failedCount: failedTargets.length,
              ),
            );
          }
        },
      );

      _workers[accountId] = worker;

      // Create a task record in the database with JSON target list.
      final taskId = const Uuid().v4();
      taskIds[accountId] = taskId;
      final targetIds = accountTargets[accountId]!.map((t) => t.id).toList();
      await _grabTaskDao.insertTask(
        GrabTasksCompanion.insert(
          id: taskId,
          accountId: accountId,
          targetIdsJson: jsonEncode(targetIds),
          status: GrabTaskStatus.running,
          effectiveIntervalMs: _effectiveIntervalMs,
          startedAt: Value(DateTime.now().toUtc().toIso8601String()),
        ),
      );

      futures.add(
        worker.run(accountTargets[accountId]!).then((decision) {
          if (decision == RetryDecision.stopTask) {
            _logger.warn('Worker $accountId requested task stop');
          }
        }),
      );
    }

    // Wait for all workers to complete.
    await Future.wait(futures);

    // Determine final status.
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _workers.clear();

    // No worker ever started — every account failed to produce an adapter.
    // Reporting "完成 0/N" here would blame the campus system for what is
    // really an expired login.
    if (taskIds.isEmpty) {
      _updateState(
        _state.copyWith(
          status: GrabberStatus.failed,
          message: '所有账号的登录状态均已失效，请重新添加账号',
        ),
      );
      return;
    }

    final finalStatus = _state.status == GrabberStatus.running
        ? (completedTargets.length == totalTargets
              ? GrabberStatus.success
              : GrabberStatus.failed)
        : _state.status; // Preserve stopped/interrupted/etc.

    final finalMessage = finalStatus == GrabberStatus.success
        ? '全部课程选课成功'
        : '完成 ${completedTargets.length}/$totalTargets';

    if (_state.status == GrabberStatus.running) {
      _updateState(_state.copyWith(status: finalStatus, message: finalMessage));
    }

    // Finalize task records.
    final stoppedAt = DateTime.now().toUtc().toIso8601String();
    for (final accountId in activeIds) {
      final taskId = taskIds[accountId];
      if (taskId == null) continue;
      await _grabTaskDao.updateTask(
        GrabTasksCompanion(
          id: Value(taskId),
          status: Value(_grabTaskStatusFrom(finalStatus)),
          stoppedAt: Value(stoppedAt),
          lastResultJson: Value(
            jsonEncode({
              'completed': completedTargets.length,
              'failed': failedTargets.length,
              'total': totalTargets,
            }),
          ),
        ),
      );
    }
  }

  /// Stop the grabber.
  void stop() {
    if (!_state.isRunning) return;

    _logger.info('Grabber stopped by user');
    for (final worker in _workers.values) {
      worker.cancel();
    }
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _updateState(
      _state.copyWith(status: GrabberStatus.stopped, message: '已手动停止'),
    );
  }

  /// Pause the grabber.
  void pause() {
    if (_state.status != GrabberStatus.running) return;

    for (final worker in _workers.values) {
      worker.cancel();
    }

    _updateState(_state.copyWith(status: GrabberStatus.paused, message: '已暂停'));
  }

  /// Reset to idle state.
  void reset() {
    _workers.clear();
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _updateState(const GrabberState());
  }

  /// Mark active tasks as interrupted (call on app start for crash recovery).
  Future<void> markInterrupted() async {
    final count = await _grabTaskDao.markActiveAsInterrupted();
    if (count > 0) {
      _logger.warn('Marked $count active tasks as interrupted');
    }
  }

  /// Clean up resources.
  void dispose() {
    _timeoutTimer?.cancel();
    for (final worker in _workers.values) {
      worker.cancel();
    }
    _workers.clear();
    _disposed = true;
    _stateController.close();
  }

  void _onTimeout() {
    _logger.warn('Grabber reached 30-minute timeout');
    for (final worker in _workers.values) {
      worker.cancel();
    }
    _updateState(
      _state.copyWith(status: GrabberStatus.stopped, message: '已达到30分钟运行上限'),
    );
  }

  /// Map grabber status to a task DB status.
  GrabTaskStatus _grabTaskStatusFrom(GrabberStatus status) {
    switch (status) {
      case GrabberStatus.success:
        return GrabTaskStatus.success;
      case GrabberStatus.failed:
        return GrabTaskStatus.failed;
      case GrabberStatus.stopped:
        return GrabTaskStatus.stopped;
      case GrabberStatus.interrupted:
        return GrabTaskStatus.interrupted;
      case GrabberStatus.captchaRequired:
        return GrabTaskStatus.captchaRequired;
      case GrabberStatus.idle:
      case GrabberStatus.preparing:
      case GrabberStatus.running:
      case GrabberStatus.paused:
        return GrabTaskStatus.stopped;
    }
  }

  void _updateState(GrabberState newState) {
    _state = newState;
    // A worker awaiting its interval can outlive dispose(); adding to a
    // closed controller would throw from a future nobody is watching.
    if (_disposed) return;
    _stateController.add(_state);
  }
}
