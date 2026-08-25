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

  /// Maximum recent task logs to keep.
  static const maxRecentTaskLogs = 3;

  /// Maximum request log entries to keep.
  static const maxRequestLogEntries = 200;
}
