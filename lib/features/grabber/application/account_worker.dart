/// Single-account worker for course grabbing.
///
/// Runs a serial submission loop for one account, respecting the
/// configured interval and retry classification (§9.3-9.4).
library;

import 'dart:async';
import 'dart:math';

import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/features/grabber/application/retry_classifier.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_bus.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_entry.dart';
import 'package:nkgrabber/infrastructure/campus/campus_adapter.dart';
import 'package:nkgrabber/infrastructure/campus/models/campus_models.dart';
import 'package:nkgrabber/infrastructure/campus/xkms_enum.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';

/// Callback for reporting target result.
typedef TargetResultCallback =
    void Function(String targetId, {required bool success, String? message});

/// A worker that processes targets for a single account.
class AccountWorker {
  AccountWorker({
    required this.accountId,
    required this.adapter,
    required this.effectiveIntervalMs,
    required this.onTargetResult,
    this.debugMode = false,
    this.accountLabel,
  });

  final String accountId;
  final CampusAdapter adapter;
  final int effectiveIntervalMs;
  final TargetResultCallback onTargetResult;

  /// Label shown next to this account's lines in the live log.
  ///
  /// The user owns their own data, so a student number on screen is fine —
  /// this never reaches the log file, which still gets the opaque id.
  final String? accountLabel;

  /// Skip the `xkms` submittability gate and submit anyway.
  ///
  /// The `xkms` sent is still the server's own value — see
  /// `AppSettings.debugModeEnabled`.
  final bool debugMode;

  final _logger = AppLogger('AccountWorker');
  final _random = Random();
  bool _cancelled = false;

  /// Attempts made for the current chunk, so the live log can show that the
  /// loop really is retrying rather than stuck.
  int _attempt = 0;

  /// Cancel the worker.
  void cancel() => _cancelled = true;

  /// Run the submission loop for the given targets.
  ///
  /// Returns the [RetryDecision] that caused the loop to stop,
  /// or null if all targets were processed.
  Future<RetryDecision?> run(List<CourseTargetEntry> targets) async {
    // Step 1: Idempotency check — match against already-selected courses.
    final remainingTargets = await _filterAlreadySelected(targets);
    if (remainingTargets.isEmpty) {
      _logger.info('[$accountId] All targets already selected');
      return null;
    }

    // Step 2: Group targets by xkid for batch submission.
    final byBatch = <String, List<CourseTargetEntry>>{};
    for (final target in remainingTargets) {
      byBatch.putIfAbsent(target.xkid, () => []).add(target);
    }

    // Step 3: Process each batch.
    for (final entry in byBatch.entries) {
      if (_cancelled) return null;

      final xkid = entry.key;
      final batchTargets = entry.value;

      // Validate xkms for all targets in this batch. A closed batch and an
      // unrecognised mode are both non-submittable, but they need different
      // messages — "please upgrade the client" is misleading when the batch is
      // simply over.
      final xkms = batchTargets.first.xkms;
      final blockedReason = Xkms.blockedReason(xkms);
      if (blockedReason != null && !debugMode) {
        _log(GrabLogKind.failure, '批次不可提交：$blockedReason');
        for (final t in batchTargets) {
          onTargetResult(t.id, success: false, message: blockedReason);
        }
        continue;
      }
      if (blockedReason != null) {
        // Debug mode: proceed, but say so — a submission against a closed
        // batch is expected to be rejected by the server, and that rejection
        // is the observation being made.
        _logger.warn(
          '[$accountId] Debug mode: submitting to a non-submittable batch '
          '($blockedReason)',
        );
        _log(GrabLogKind.lifecycle, '调试模式：无视批次状态强制提交', detail: blockedReason);
      }

      // Re-fetch batch info for latest zdxk.
      int zdxk;
      try {
        final batches = await adapter.listBatches();
        final batch = batches.where((b) => b.xkid == xkid).firstOrNull;
        zdxk = batch?.zdxk ?? 1;
      } on Exception {
        zdxk = 1; // Conservative default.
      }

      // Split targets into chunks respecting zdxk (minimum 1 to avoid infinite loop).
      final chunks = _chunkTargets(batchTargets, zdxk);

      for (final chunk in chunks) {
        if (_cancelled) return null;

        final decision = await _submitChunkWithRetry(xkid, xkms, chunk);
        if (decision == RetryDecision.stopTask) return decision;
      }
    }

    return null;
  }

  /// Submit a single chunk with retry logic.
  ///
  /// Retries on [RetryDecision.retry], skips on [RetryDecision.skipTarget],
  /// and propagates [RetryDecision.stopTask] immediately.
  Future<RetryDecision?> _submitChunkWithRetry(
    String xkid,
    String xkms,
    List<CourseTargetEntry> chunk,
  ) async {
    final command = SubmitSelection(
      xkid: xkid,
      xkms: xkms,
      kmhList: chunk.map((t) => t.kmh).toList(),
    );

    final courseNames = chunk.map((t) => t.courseName).join('、');
    _attempt = 0;

    while (!_cancelled) {
      _attempt++;
      _log(
        GrabLogKind.request,
        '第 $_attempt 次提交：$courseNames',
        detail: 'xkid=$xkid xkms=$xkms',
      );
      try {
        final result = await adapter.submit(command);

        if (result.success) {
          _log(
            GrabLogKind.success,
            '选课成功：$courseNames',
            detail: result.message,
          );
          for (final t in chunk) {
            onTargetResult(t.id, success: true, message: result.message);
          }
          return null; // Chunk done.
        }

        // submit() reported a failure without throwing. Nothing has been
        // classified, so the only safe reading is "not selected yet" — keep
        // retrying like the exception path's retry branch does. Reporting
        // success here is what the caller must never be allowed to infer from
        // an absence of errors.
        _logger.warn(
          '[$accountId] Submit reported failure without an exception: '
          '${result.message} — retrying',
        );
        _log(GrabLogKind.failure, '提交未确认，将重试', detail: result.message);
      } on Exception catch (e) {
        final decision = RetryClassifier.classify(e);
        _logger.warn('[$accountId] Submit error: $e, decision: $decision');
        _log(
          GrabLogKind.failure,
          '提交被拒绝（${_decisionLabel(decision)}）',
          detail: _reasonOf(e),
        );

        switch (decision) {
          case RetryDecision.stopTask:
            return RetryDecision.stopTask;
          case RetryDecision.skipTarget:
            for (final t in chunk) {
              onTargetResult(t.id, success: false, message: e.toString());
            }
            return null; // Skip to next chunk.
          case RetryDecision.retry:
            break; // Fall through to interval wait and retry.
        }
      }

      // Wait before retrying this chunk.
      if (!_cancelled) {
        await _waitWithJitter(effectiveIntervalMs);
      }
    }

    return null;
  }

  /// Publish a line to the on-screen live log.
  void _log(GrabLogKind kind, String message, {String? detail}) {
    grabLogBus.log(
      kind,
      message,
      accountId: accountId,
      accountLabel: accountLabel,
      detail: detail,
    );
  }

  /// The user-facing reason behind an exception.
  ///
  /// `toString()` on a CampusException prefixes the type, which reads as noise
  /// next to the school's own Chinese message.
  static String _reasonOf(Exception e) =>
      e is AppException ? e.message : e.toString();

  static String _decisionLabel(RetryDecision decision) => switch (decision) {
    RetryDecision.retry => '继续重试',
    RetryDecision.skipTarget => '跳过该课程',
    RetryDecision.stopTask => '终止任务',
  };

  /// Filter out targets that are already selected (idempotency check).
  Future<List<CourseTargetEntry>> _filterAlreadySelected(
    List<CourseTargetEntry> targets,
  ) async {
    final remaining = <CourseTargetEntry>[];

    // Group by xkid to batch the idempotency check.
    final byBatch = <String, List<CourseTargetEntry>>{};
    for (final t in targets) {
      byBatch.putIfAbsent(t.xkid, () => []).add(t);
    }

    for (final entry in byBatch.entries) {
      try {
        final selected = await adapter.listSelections(entry.key);
        final selectedKmh = selected.map((s) => s.kmh).toSet();

        for (final target in entry.value) {
          if (selectedKmh.contains(target.kmh)) {
            // The log file gets the opaque id; the course name goes only to
            // the on-screen live log, which is never persisted.
            _logger.info('[$accountId] Target ${target.id} already selected');
            _log(GrabLogKind.success, '已选中，跳过：${target.courseName}');
            onTargetResult(target.id, success: true, message: '已选中（幂等检查）');
          } else {
            remaining.add(target);
          }
        }
      } on Exception catch (e) {
        _logger.warn(
          '[$accountId] Idempotency check failed for ${entry.key}',
          e,
        );
        // If we can't check, include all targets.
        remaining.addAll(entry.value);
      }
    }

    return remaining;
  }

  /// Split targets into chunks respecting the zdxk limit.
  ///
  /// Clamps [zdxk] to at least 1 to prevent an infinite loop when the
  /// server returns 0.
  List<List<CourseTargetEntry>> _chunkTargets(
    List<CourseTargetEntry> targets,
    int zdxk,
  ) {
    final safeZdxk = zdxk.clamp(1, targets.length);
    final chunks = <List<CourseTargetEntry>>[];
    for (var i = 0; i < targets.length; i += safeZdxk) {
      final end = (i + safeZdxk).clamp(0, targets.length);
      chunks.add(targets.sublist(i, end));
    }
    return chunks;
  }

  /// Wait for the specified interval with a small upward jitter.
  ///
  /// Uses [Random] so each wait has a different offset (not a fixed
  /// hash-derived constant). Jitter is 0–10% upward only.
  Future<void> _waitWithJitter(int baseMs) async {
    final jitter = (baseMs * 0.1 * _random.nextInt(100) / 100).toInt();
    final waitMs = baseMs + jitter;
    await Future<void>.delayed(Duration(milliseconds: waitMs));
  }
}
