/// Application logger with sanitization support.
///
/// Wraps the `logging` package and applies [LogSanitizer] to all messages
/// before they are emitted.
library;

import 'dart:developer' as developer;

import 'package:logging/logging.dart';
import 'package:nkgrabber/core/logging/log_sanitizer.dart';

/// Global log level configuration.
enum AppLogLevel {
  debug(Level.FINE),
  info(Level.INFO),
  warn(Level.WARNING),
  error(Level.SEVERE);

  const AppLogLevel(this.level);
  final Level level;

  static AppLogLevel fromString(String value) {
    return AppLogLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppLogLevel.info,
    );
  }
}

class AppLogger {
  factory AppLogger(String name) => AppLogger._(Logger(name));
  AppLogger._(this._logger);

  final Logger _logger;

  static bool _initialized = false;

  /// Initialize the logging system. Call once at app startup.
  static void init({AppLogLevel level = AppLogLevel.info}) {
    if (_initialized) return;
    _initialized = true;

    Logger.root.level = level.level;
    Logger.root.onRecord.listen((record) {
      final sanitized = LogSanitizer.sanitize(record.message);
      developer.log(
        sanitized,
        time: record.time,
        level: record.level.value,
        name: record.loggerName,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    });
  }

  /// Update the global log level at runtime.
  static void setLevel(AppLogLevel level) {
    Logger.root.level = level.level;
  }

  void debug(String message) => _logger.fine(message);
  void info(String message) => _logger.info(message);
  void warn(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.warning(message, error, stackTrace);
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.severe(message, error, stackTrace);
}
