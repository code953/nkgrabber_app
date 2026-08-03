/// Single-account worker for course grabbing.
///
/// Runs a serial submission loop for one account, respecting the
/// configured interval and retry classification (§9.3-9.4).
library;

import 'dart:async';

import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/features/grabber/application/retry_classifier.dart';
import 'package:nkgrabber/infrastructure/campus/campus_adapter.dart';
import 'package:nkgrabber/infrastructure/campus/models/campus_models.dart';
import 'package:nkgrabber/infrastructure/campus/xkms_enum.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';

/// Callback for reporting target result.
typedef TargetResultCallback = void Function(
  String targetId,
  bool success,
  String? message,
);

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

      // Validate xkms for all targets in this batch.
      final xkms = batchTargets.first.xkms;
      if (XkmsMode.fromCode(xkms) == null) {
        for (final t in batchTargets) {
          onTargetResult(t.id, false, '无法识别的选课模式，请等待客户端升级');
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

      // Split targets into chunks respecting zdxk.
      final chunks = _chunkTargets(batchTargets, zdxk);

      for (final chunk in chunks) {
        if (_cancelled) return null;

        final kmhList = chunk.map((t) => t.kmh).toList();
        final command = SubmitSelection(
          xkid: xkid,
          xkms: xkms,
          kmhList: kmhList,
        );

        try {
          final result = await adapter.submit(command);

          if (result.success) {
            for (final t in chunk) {
              onTargetResult(t.id, true, result.message);
            }
          } else {
            // Check if we should retry or skip.
            for (final t in chunk) {
              onTargetResult(t.id, false, result.message);
            }
          }
        } on Exception catch (e) {
          final decision = RetryClassifier.classify(e);
          _logger.warn('[$accountId] Submit error: $e, decision: $decision');

          switch (decision) {
            case RetryDecision.stopTask:
              return decision;
            case RetryDecision.skipTarget:
              for (final t in chunk) {
                onTargetResult(t.id, false, e.toString());
              }
            case RetryDecision.retry:
              // Will retry on next loop iteration.
              break;
          }
        }

        // Wait for the configured interval before next submission.
        if (!_cancelled) {
          await _waitWithJitter(effectiveIntervalMs);
        }
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
            onTargetResult(target.id, true, '已选中（幂等检查）');
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
  List<List<CourseTargetEntry>> _chunkTargets(
    List<CourseTargetEntry> targets,
    int zdxk,
  ) {
    final chunks = <List<CourseTargetEntry>>[];
    for (var i = 0; i < targets.length; i += zdxk) {
      final end = (i + zdxk).clamp(0, targets.length);
      chunks.add(targets.sublist(i, end));
    }
    return chunks;
  }

  /// Wait for the specified interval with a small upward jitter.
  Future<void> _waitWithJitter(int baseMs) async {
    // Jitter: 0-10% upward only (never below the minimum).
    final jitter = (baseMs * 0.1 * (_hashCode() % 100) / 100).toInt();
    final waitMs = baseMs + jitter;
    await Future<void>.delayed(Duration(milliseconds: waitMs));
  }

  /// Simple hash for jitter variation.
  int _hashCode() => accountId.hashCode.abs();
}
