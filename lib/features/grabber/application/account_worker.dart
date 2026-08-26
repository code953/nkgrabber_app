/// Single-account worker for course grabbing.
///
/// Runs a serial submission loop for one account, respecting the
/// configured interval and retry classification (§9.3-9.4).
library;

import 'dart:async';
import 'dart:math';

import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/features/grabber/application/retry_classifier.dart';
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
  });

  final String accountId;
  final CampusAdapter adapter;
  final int effectiveIntervalMs;
  final TargetResultCallback onTargetResult;

  final _logger = AppLogger('AccountWorker');
  final _random = Random();
  bool _cancelled = false;

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
      if (blockedReason != null) {
        for (final t in batchTargets) {
          onTargetResult(t.id, success: false, message: blockedReason);
        }
        continue;
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

    while (!_cancelled) {
      try {
        final result = await adapter.submit(command);

        if (result.success) {
          for (final t in chunk) {
            onTargetResult(t.id, success: true, message: result.message);
          }
          return null; // Chunk done.
        }

        // submit() returned success=false without throwing — treat as a
        // transient failure so the campus_adapter's message→exception
        // mapping in the exception path can drive the classifier.
        // If no exception was raised, retry after the interval.
        _logger.debug(
          '[$accountId] Submit returned failure: ${result.message}, retrying',
        );
      } on Exception catch (e) {
        final decision = RetryClassifier.classify(e);
        _logger.warn('[$accountId] Submit error: $e, decision: $decision');

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
            _logger.info(
              '[$accountId] Target ${target.courseName} already selected',
            );
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
