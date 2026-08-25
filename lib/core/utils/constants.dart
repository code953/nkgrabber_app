/// Application-wide constants.
library;

class AppConstants {
  const AppConstants._();

  /// Campus system base URL.
  static const campusBaseUrl = 'http://campus.nks.edu.cn';

  /// Maximum continuous grab task runtime (minutes).
  static const maxGrabTaskRuntimeMinutes = 30;

  /// Default user request interval (ms).
  static const defaultUserIntervalMs = 1000;

  /// Default floor for the request interval (ms).
  ///
  /// Jitter is applied upward only, so the effective interval never drops
  /// below this value.
  static const defaultMinRequestIntervalMs = 800;

  /// Default maximum number of simultaneously enabled accounts.
  static const defaultMaxAccounts = 5;

  /// Default maximum number of accounts grabbing in parallel.
  static const defaultMaxConcurrentAccounts = 3;

  /// Maximum recent task logs to keep.
  static const maxRecentTaskLogs = 3;

  /// Maximum request log entries to keep.
  static const maxRequestLogEntries = 200;
}
