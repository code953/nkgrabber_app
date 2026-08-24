/// Crash reporter.
///
/// Captures uncaught Flutter and Dart errors, sanitizes them,
/// and reports to the backend. Default: enabled (opt-out via settings).
/// Never reports passwords, cookies, tokens, student data, or course data.
library;

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/core/logging/log_sanitizer.dart';
import 'package:nkgrabber/core/utils/constants.dart';
import 'package:nkgrabber/infrastructure/backend/backend_repository.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/crash_report_dto.dart';

class CrashReporter {
  CrashReporter({
    required BackendRepository backendRepository,
    required String installId,
    required String appVersion,
    required String platform,
    required String arch,
    required String locale,
  })  : _backendRepo = backendRepository,
        _installIdHash = _hashInstallId(installId),
        _appVersion = appVersion,
        _platform = platform,
        _arch = arch,
        _locale = locale;

  final BackendRepository _backendRepo;
  final String _installIdHash;
  final String _appVersion;
  final String _platform;
  final String _arch;
  final String _locale;
  final _logger = AppLogger('CrashReporter');

  /// Whether crash reporting is enabled.
  bool enabled = true;

  /// Install the crash reporter into Flutter's error handling.
  ///
  /// Call this wrapping `runApp` in `main()`:
  /// ```dart
  /// CrashReporter.install(reporter, () => runApp(MyApp()));
  /// ```
  static void install(CrashReporter reporter, VoidCallback appRunner) {
    // Capture Flutter framework errors.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      reporter._reportFlutterError(details);
    };

    // Capture errors outside Flutter's framework.
    runZonedGuarded(
      appRunner,
      (error, stackTrace) {
        reporter._reportZoneError(error, stackTrace);
      },
    );
  }

  void _reportFlutterError(FlutterErrorDetails details) {
    if (!enabled) return;

    final sanitizedStack = LogSanitizer.sanitizeStackTrace(
      details.stack?.toString() ?? '',
    );

    _sendReport(
      crashType: 'FlutterError',
      stackTrace: sanitizedStack,
    );
  }

  void _reportZoneError(Object error, StackTrace stackTrace) {
    if (!enabled) return;

    final sanitizedStack = LogSanitizer.sanitizeStackTrace(
      stackTrace.toString(),
    );

    _sendReport(
      crashType: error.runtimeType.toString(),
      stackTrace: sanitizedStack,
    );
  }

  /// Send a crash report (best-effort, retries with backoff).
  Future<void> _sendReport({
    required String crashType,
    required String stackTrace,
  }) async {
    final report = CrashReportDto(
      installIdHash: _installIdHash,
      appVersion: _appVersion,
      platform: _platform,
      arch: _arch,
      locale: _locale,
      crashType: crashType,
      sanitizedStackTrace: stackTrace,
      timestamp: DateTime.now().toUtc().toIso8601String(),
    );

    for (var attempt = 0; attempt < AppConstants.crashReportMaxRetries; attempt++) {
      try {
        await _backendRepo.reportCrash(report);
        return;
      } on Exception catch (e) {
        _logger.debug('Crash report attempt ${attempt + 1} failed: $e');
        if (attempt + 1 < AppConstants.crashReportMaxRetries) {
          // Exponential backoff: 1s, 2s, 4s, …
          await Future<void>.delayed(
            Duration(milliseconds: 1000 * (1 << attempt)),
          );
        }
      }
    }
    _logger.debug(
      'Crash report discarded after ${AppConstants.crashReportMaxRetries} attempts',
    );
  }

  /// Hash the installId for privacy (never send raw installId).
  static String _hashInstallId(String installId) {
    final bytes = utf8.encode(installId);
    return sha256.convert(bytes).toString();
  }
}
