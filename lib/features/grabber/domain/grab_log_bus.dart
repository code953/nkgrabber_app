/// In-memory bus for the live grabber log.
///
/// Two producers, one consumer:
///
/// * `_CampusLoggingInterceptor` publishes every request and response, because
///   that is the only place that sees the wire.
/// * `GrabberEngine` / `AccountWorker` publish verdicts and lifecycle, because
///   the interceptor cannot tell an accepted submit from a refused one — both
///   are HTTP 200.
///
/// It is a singleton rather than a constructor-injected sink because the
/// clients are built deep inside `AccountsNotifier`, several layers from the
/// grabber page, and there is only ever one run to observe. The tradeoff is
/// that a test must call `reset` to isolate itself.
///
/// **Nothing here is persisted.** The buffer is capped and lives only in
/// memory, so closing the app discards it. This is the display path, not the
/// log-file path — `AppLogger` and its sanitizer are unaffected.
library;

import 'dart:async';
import 'dart:collection';

import 'package:nkgrabber/features/grabber/domain/grab_log_entry.dart';

/// Most entries retained. A 30-minute run at the 1s floor produces on the
/// order of a thousand lines; keeping every one would grow without bound on a
/// long session, and the user only ever reads the recent tail.
const _maxEntries = 500;

/// The single live-log bus.
final grabLogBus = GrabLogBus();

class GrabLogBus {
  final _controller = StreamController<GrabLogEntry>.broadcast();
  final _entries = Queue<GrabLogEntry>();

  /// Entries retained so far, oldest first.
  ///
  /// A late subscriber (the grabber page is built after the run starts) needs
  /// the backlog, not just what arrives next.
  List<GrabLogEntry> get entries => List.unmodifiable(_entries);

  /// Entries as they are produced.
  Stream<GrabLogEntry> get stream => _controller.stream;

  void add(GrabLogEntry entry) {
    _entries.addLast(entry);
    while (_entries.length > _maxEntries) {
      _entries.removeFirst();
    }
    if (!_controller.isClosed) _controller.add(entry);
  }

  /// Convenience for the common shape.
  void log(
    GrabLogKind kind,
    String message, {
    String? accountId,
    String? accountLabel,
    String? detail,
  }) {
    add(
      GrabLogEntry(
        at: DateTime.now(),
        kind: kind,
        message: message,
        accountId: accountId,
        accountLabel: accountLabel,
        detail: detail,
      ),
    );
  }

  /// Drop the backlog. Called when a new run starts, and by tests.
  void reset() => _entries.clear();
}
