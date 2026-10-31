/// Grabber engine — orchestrates parallel account workers.
///
/// Manages the full grabber state machine (§9.1), enforces
/// 30-minute timeout, concurrency limits, and interval guarantees.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/core/utils/constants.dart';
import 'package:nkgrabber/features/grabber/application/account_worker.dart';
import 'package:nkgrabber/features/grabber/application/retry_classifier.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_bus.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_entry.dart';
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
typedef AdapterResolver =
    Future<CampusAdapter?> Function(
      String accountId, {
      CancelToken? cancelToken,
    });

/// Resolves an account's display name for the on-screen live log.
///
/// Synchronous and best-effort: a missing label costs a nicer log line, not a
/// failed run, so the caller returns null rather than hitting the database.
typedef AccountLabelResolver = String? Function(String accountId);

/// The main grabber engine.
class GrabberEngine {
  GrabberEngine({
    required CourseTargetDao courseTargetDao,
    required GrabTaskDao grabTaskDao,
    required AdapterResolver adapterResolver,
    required int maxConcurrentAccounts,
    required int minRequestIntervalMs,
    required int userIntervalMs,
    bool debugMode = false,
    AccountLabelResolver? accountLabels,
  }) : _courseTargetDao = courseTargetDao,
       _grabTaskDao = grabTaskDao,
       _adapterResolver = adapterResolver,
       _accountLabels = accountLabels,
       _maxConcurrent = maxConcurrentAccounts,
       _debugMode = debugMode,
       _effectiveIntervalMs = max(userIntervalMs, minRequestIntervalMs);

  final CourseTargetDao _courseTargetDao;
  final GrabTaskDao _grabTaskDao;
  final AdapterResolver _adapterResolver;

  /// Display name for an account, used only in the on-screen live log.
  final AccountLabelResolver? _accountLabels;
  final int _maxConcurrent;

  /// Lets workers submit against batches the `xkms` gate would refuse.
  final bool _debugMode;

  /// Effective interval: max of the user setting and the local floor.
  /// Jitter is applied upward only, never below the floor.
  final int _effectiveIntervalMs;

  final _logger = AppLogger('GrabberEngine');
  _GrabberRun? _run;
  GrabberState _state = const GrabberState();
  final _stateController = StreamController<GrabberState>.broadcast();
  bool _disposed = false;

  /// Stream of state changes for UI binding.
  Stream<GrabberState> get stateStream => _stateController.stream;

  /// Current state.
  GrabberState get state => _state;

  bool _isActive(_GrabberRun run) =>
      !_disposed && identical(_run, run) && !run.cancelToken.isCancelled;

  /// Start the grabber for the given account IDs.
  Future<void> start(List<String> accountIds) async {
    if (_disposed || _state.isRunning) return;

    final run = _GrabberRun();
    _run = run;
    grabLogBus
      ..reset()
      ..log(GrabLogKind.lifecycle, '开始抢课：${accountIds.length} 个账号');
    _updateState(
      GrabberState(
        status: GrabberStatus.preparing,
        startedAt: DateTime.now().toUtc(),
        activeAccountIds: List.of(accountIds),
      ),
    );

    final futures = <Future<void>>[];
    try {
      final accountTargets = <String, List<CourseTargetEntry>>{};
      for (final accountId in accountIds) {
        final targets = await _courseTargetDao.getEnabledByAccount(accountId);
        if (!_isActive(run)) return;
        if (targets.isNotEmpty) {
          accountTargets[accountId] = targets;
          run.totalTargets += targets.length;
        }
      }

      if (accountTargets.isEmpty) {
        run.finalStatus = GrabberStatus.failed;
        _updateState(
          _state.copyWith(status: run.finalStatus, message: '没有可用的课程目标'),
        );
        return;
      }

      _updateState(
        _state.copyWith(
          status: GrabberStatus.running,
          totalTargets: run.totalTargets,
        ),
      );
      run.timeoutTimer = Timer(
        const Duration(minutes: AppConstants.maxGrabTaskRuntimeMinutes),
        () => _onTimeout(run),
      );

      for (final accountId in accountTargets.keys.take(_maxConcurrent)) {
        if (!_isActive(run)) return;
        final adapter = await _adapterResolver(
          accountId,
          cancelToken: run.cancelToken,
        );
        if (!_isActive(run)) return;
        if (adapter == null) {
          _logger.warn('No adapter for account $accountId');
          grabLogBus.log(
            GrabLogKind.failure,
            '账号登录状态已失效，跳过',
            accountId: accountId,
          );
          continue;
        }

        final worker = AccountWorker(
          accountId: accountId,
          adapter: adapter,
          effectiveIntervalMs: _effectiveIntervalMs,
          debugMode: _debugMode,
          accountLabel: _accountLabels?.call(accountId),
          onTargetResult: (targetId, {required bool success, String? message}) {
            if (!_isActive(run)) return;
            if (success) {
              run.completedTargets.add(targetId);
            } else {
              run.failedTargets.add(targetId);
            }
            _updateState(
              _state.copyWith(
                completedTargets: List.of(run.completedTargets),
                successCount: run.completedTargets.length,
                failedTargets: List.of(run.failedTargets),
                failedCount: run.failedTargets.length,
              ),
            );
          },
        );
        run.workers.add(worker);

        final taskId = const Uuid().v4();
        final targets = accountTargets[accountId]!;
        await _grabTaskDao.insertTask(
          GrabTasksCompanion.insert(
            id: taskId,
            accountId: accountId,
            targetIdsJson: jsonEncode(targets.map((t) => t.id).toList()),
            status: GrabTaskStatus.running,
            effectiveIntervalMs: _effectiveIntervalMs,
            startedAt: Value(DateTime.now().toUtc().toIso8601String()),
          ),
        );
        // An insert cannot be cancelled. Even if stop won the race, this row
        // belongs to this run and must still be finalized in finally.
        run.taskIds.add(taskId);
        if (!_isActive(run)) return;
        futures.add(_runWorker(run, worker, targets));
      }

      await Future.wait(futures);
      if (!_isActive(run)) return;

      run.finalStatus = run.completedTargets.length == run.totalTargets
          ? GrabberStatus.success
          : GrabberStatus.failed;
      final message = run.taskIds.isEmpty
          ? '所有账号的登录状态均已失效，请重新添加账号'
          : run.finalStatus == GrabberStatus.success
          ? '全部课程选课成功'
          : '完成 ${run.completedTargets.length}/${run.totalTargets}';
      _updateState(_state.copyWith(status: run.finalStatus, message: message));
      grabLogBus.log(
        run.finalStatus == GrabberStatus.success
            ? GrabLogKind.success
            : GrabLogKind.failure,
        '任务结束：$message',
      );
    } catch (_) {
      _failRun(run);
    } finally {
      run.cancel(run.finalStatus);
      try {
        await Future.wait(futures);
      } finally {
        try {
          await _finalizeTasks(run);
        } finally {
          // A stopped run may finish after its replacement has already started.
          if (identical(_run, run)) _run = null;
        }
      }
    }
  }

  Future<void> _runWorker(
    _GrabberRun run,
    AccountWorker worker,
    List<CourseTargetEntry> targets,
  ) async {
    try {
      final decision = await worker.run(targets);
      if (_isActive(run) && decision == RetryDecision.stopTask) {
        _logger.warn('Worker ${worker.accountId} requested task stop');
      }
    } catch (_) {
      _failRun(run);
    }
  }

  void _failRun(_GrabberRun run) {
    if (!_isActive(run)) return;
    run.cancel(GrabberStatus.failed);
    _logger.warn('Grabber run failed');
    grabLogBus.log(GrabLogKind.failure, '任务执行失败，已停止');
    _updateState(
      _state.copyWith(status: GrabberStatus.failed, message: '任务执行失败，请重试'),
    );
  }

  Future<void> _finalizeTasks(_GrabberRun run) async {
    final stoppedAt = DateTime.now().toUtc().toIso8601String();
    for (final taskId in run.taskIds) {
      await _grabTaskDao.updateTask(
        GrabTasksCompanion(
          id: Value(taskId),
          status: Value(_grabTaskStatusFrom(run.finalStatus)),
          stoppedAt: Value(stoppedAt),
          lastResultJson: Value(
            jsonEncode({
              'completed': run.completedTargets.length,
              'failed': run.failedTargets.length,
              'total': run.totalTargets,
            }),
          ),
        ),
      );
    }
  }

  /// Stop the current run. A new run may start without waiting for its cleanup.
  void stop() {
    final run = _run;
    if (run == null || !_state.isRunning) return;

    run.cancel(GrabberStatus.stopped);
    _logger.info('Grabber stopped by user');
    grabLogBus.log(GrabLogKind.lifecycle, '用户已停止');
    _updateState(
      _state.copyWith(status: GrabberStatus.stopped, message: '已手动停止'),
    );
  }

  /// Reset to idle state.
  void reset() {
    _run?.cancel(GrabberStatus.stopped);
    _run = null;
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
    _run?.cancel(GrabberStatus.stopped);
    _run = null;
    _disposed = true;
    _stateController.close();
  }

  void _onTimeout(_GrabberRun run) {
    if (!_isActive(run)) return;
    run.cancel(GrabberStatus.stopped);
    _logger.warn('Grabber reached 30-minute timeout');
    grabLogBus.log(GrabLogKind.lifecycle, '已达到 30 分钟运行上限，自动停止');
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
    if (_disposed) return;
    _state = newState;
    _stateController.add(_state);
  }
}

/// Resources and results must outlive stop without becoming the next run's.
class _GrabberRun {
  final cancelToken = CancelToken();
  final workers = <AccountWorker>[];
  final taskIds = <String>[];
  final completedTargets = <String>[];
  final failedTargets = <String>[];
  int totalTargets = 0;
  GrabberStatus finalStatus = GrabberStatus.stopped;
  Timer? timeoutTimer;

  void cancel(GrabberStatus status) {
    if (cancelToken.isCancelled) return;
    finalStatus = status;
    cancelToken.cancel();
    timeoutTimer?.cancel();
    for (final worker in workers) {
      worker.cancel();
    }
  }
}
