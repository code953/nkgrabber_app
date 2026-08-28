/// One line of the live grabber log.
///
/// The existing `GrabberState` only carries counters and a list of target ids,
/// so a user watching a run could see "失败 1/3" but never what the campus
/// system actually said. These entries are what the grabber page renders, and
/// they are held in memory only — nothing here is written to the log file, so
/// the same sensitivity rules do not apply to what is *displayed*, but see
/// `GrabLogEntry.detail` for what may be put in one.
library;

/// What a log line represents.
enum GrabLogKind {
  /// A request was sent to the campus system.
  request,

  /// A response came back and was understood as a non-verdict (e.g. a batch
  /// list read).
  response,

  /// A submit the server accepted.
  success,

  /// A submit the server refused, or a transport failure. Carries the reason.
  failure,

  /// Engine lifecycle: task started, stopped, timed out.
  lifecycle,
}

/// A single entry in the live grabber log.
class GrabLogEntry {
  const GrabLogEntry({
    required this.at,
    required this.kind,
    required this.message,
    this.accountId,
    this.accountLabel,
    this.detail,
  });

  /// Local wall-clock time the entry was produced.
  final DateTime at;

  final GrabLogKind kind;

  /// The one-line summary shown in the log list.
  final String message;

  /// The opaque account UUID this line belongs to, if any.
  final String? accountId;

  /// Human-readable account label for display.
  ///
  /// The user owns their own data, so showing a student number on screen is
  /// fine — writing one to the log file is not. Nothing in this class is
  /// routed to the app logger.
  final String? accountLabel;

  /// Free-form extra text: the server's own message, an exception, a body
  /// excerpt. Rendered under the message in a monospace style.
  final String? detail;

  /// `HH:mm:ss.mmm`, the resolution a user needs to see the interval working.
  String get timestamp {
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    final s = at.second.toString().padLeft(2, '0');
    final ms = at.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}
