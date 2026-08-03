/// Grabber state definition.
///
/// Represents the full state machine for the course grabbing engine (§9.1).
library;

/// All possible states of the grabber engine.
enum GrabberStatus {
  /// No task running.
  idle,

  /// Validating license, checking prerequisites.
  preparing,

  /// Actively submitting course selections.
  running,

  /// Task completed — all targets succeeded.
  success,

  /// User-initiated pause.
  paused,

  /// User-initiated stop or 30-minute timeout.
  stopped,

  /// App crashed or was killed during a task.
  interrupted,

  /// License validation failed during task.
  authExpired,

  /// Campus system requires captcha.
  captchaRequired,

  /// Task failed — no more retries or fatal error.
  failed,
}

/// Overall grabber engine state exposed to the UI.
class GrabberState {
  const GrabberState({
    this.status = GrabberStatus.idle,
    this.activeAccountIds = const [],
    this.completedTargets = const [],
    this.failedTargets = const [],
    this.message,
    this.startedAt,
    this.elapsedMs = 0,
    this.totalTargets = 0,
    this.successCount = 0,
    this.failedCount = 0,
  });

  final GrabberStatus status;
  final List<String> activeAccountIds;
  final List<String> completedTargets;
  final List<String> failedTargets;
  final String? message;
  final DateTime? startedAt;
  final int elapsedMs;
  final int totalTargets;
  final int successCount;
  final int failedCount;

  bool get isRunning =>
      status == GrabberStatus.running ||
      status == GrabberStatus.preparing;

  bool get isTerminal =>
      status == GrabberStatus.success ||
      status == GrabberStatus.failed ||
      status == GrabberStatus.stopped ||
      status == GrabberStatus.interrupted ||
      status == GrabberStatus.authExpired;

  GrabberState copyWith({
    GrabberStatus? status,
    List<String>? activeAccountIds,
    List<String>? completedTargets,
    List<String>? failedTargets,
    String? message,
    DateTime? startedAt,
    int? elapsedMs,
    int? totalTargets,
    int? successCount,
    int? failedCount,
    bool clearMessage = false,
  }) {
    return GrabberState(
      status: status ?? this.status,
      activeAccountIds: activeAccountIds ?? this.activeAccountIds,
      completedTargets: completedTargets ?? this.completedTargets,
      failedTargets: failedTargets ?? this.failedTargets,
      message: clearMessage ? null : (message ?? this.message),
      startedAt: startedAt ?? this.startedAt,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      totalTargets: totalTargets ?? this.totalTargets,
      successCount: successCount ?? this.successCount,
      failedCount: failedCount ?? this.failedCount,
    );
  }
}
