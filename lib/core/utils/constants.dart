/// Application-wide constants.
library;

class AppConstants {
  const AppConstants._();

  /// Business backend base URL.
  static const backendBaseUrl = 'https://nkgrabber.code953.top/api/v1';

  /// Campus system base URL.
  static const campusBaseUrl = 'http://campus.nks.edu.cn';

  /// HTTP timeouts for business backend.
  static const backendConnectTimeout = Duration(seconds: 5);
  static const backendReceiveTimeout = Duration(seconds: 10);

  /// HTTP timeout for startup config/update checks.
  static const startupCheckTimeout = Duration(seconds: 10);

  /// Maximum clock offset (ms) between client and server before warning.
  static const maxServerClockOffsetMinutes = 10;

  /// Maximum clock offset (s) between campus and server before warning.
  static const maxCampusServerDriftSeconds = 60;

  /// Maximum continuous grab task runtime (minutes).
  static const maxGrabTaskRuntimeMinutes = 30;

  /// Activation code format regex.
  static final activationCodeRegex =
      RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');

  /// Default user request interval (ms).
  static const defaultUserIntervalMs = 1000;

  /// Maximum recent task logs to keep.
  static const maxRecentTaskLogs = 3;

  /// Maximum request log entries to keep.
  static const maxRequestLogEntries = 200;
}
