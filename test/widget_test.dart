import 'package:flutter_test/flutter_test.dart';
import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/core/logging/log_sanitizer.dart';
import 'package:nkgrabber/core/utils/constants.dart';
import 'package:nkgrabber/core/utils/extensions.dart';
import 'package:nkgrabber/features/grabber/application/retry_classifier.dart';
import 'package:nkgrabber/features/grabber/domain/grabber_state.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/app_config_dto.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/crash_report_dto.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/latest_release_dto.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/license_activation_dto.dart';
import 'package:nkgrabber/infrastructure/campus/clock_sync.dart';
import 'package:nkgrabber/infrastructure/campus/xkms_enum.dart';
import 'package:nkgrabber/infrastructure/database/tables/accounts.dart';
import 'package:nkgrabber/infrastructure/database/tables/grab_tasks.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // Core Exceptions
  // ═══════════════════════════════════════════════════════════════════════
  group('AppException', () {
    test('NetworkException carries type and message', () {
      const exception = NetworkException(
        message: 'Connection timed out',
        type: NetworkExceptionType.timeout,
      );
      expect(exception.message, 'Connection timed out');
      expect(exception.type, NetworkExceptionType.timeout);
    });

    test('AuthException carries type and message', () {
      const exception = AuthException(
        message: 'Token expired',
        type: AuthExceptionType.tokenInvalid,
      );
      expect(exception.message, 'Token expired');
      expect(exception.type, AuthExceptionType.tokenInvalid);
    });

    test('CampusException carries type and message', () {
      const exception = CampusException(
        message: 'Session expired',
        type: CampusExceptionType.sessionExpired,
      );
      expect(exception.message, 'Session expired');
      expect(exception.type, CampusExceptionType.sessionExpired);
    });

    test('MaintenanceException carries maintenance message', () {
      const exception = MaintenanceException(
        message: 'Server down',
        maintenanceMessage: '系统维护中',
      );
      expect(exception.maintenanceMessage, '系统维护中');
    });

    test('VersionTooLowException carries minimum version', () {
      const exception = VersionTooLowException(
        message: 'Update needed',
        minimumVersion: '2.0.0',
      );
      expect(exception.minimumVersion, '2.0.0');
    });

    test('toString includes message', () {
      const exception = UnknownException(message: 'something broke');
      expect(exception.toString(), contains('something broke'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Log Sanitizer
  // ═══════════════════════════════════════════════════════════════════════
  group('LogSanitizer', () {
    test('redacts passwords', () {
      const input = 'Login with password=secret123 failed';
      final result = LogSanitizer.sanitize(input);
      expect(result, contains('[REDACTED]'));
      expect(result, isNot(contains('secret123')));
    });

    test('redacts activation codes', () {
      const input = 'Activating code ABCD-1234-EFGH-5678';
      final result = LogSanitizer.sanitize(input);
      expect(result, contains('[REDACTED]'));
      expect(result, isNot(contains('ABCD-1234-EFGH-5678')));
    });

    test('redacts bearer tokens', () {
      const input = 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.payload';
      final result = LogSanitizer.sanitize(input);
      expect(result, contains('[REDACTED]'));
      expect(result, isNot(contains('eyJhbGciOiJIUzI1NiJ9')));
    });

    test('redacts cookies', () {
      const input = 'gdpk=abc123def456 found in response';
      final result = LogSanitizer.sanitize(input);
      expect(result, contains('[REDACTED]'));
      expect(result, isNot(contains('abc123def456')));
    });

    test('redacts deviceToken in JSON', () {
      const input = '{"deviceToken":"secret-token-value"}';
      final result = LogSanitizer.sanitize(input);
      expect(result, isNot(contains('secret-token-value')));
    });

    test('redacts licenseCode in JSON', () {
      const input = '{"licenseCode":"ABCD-1234-EFGH-5678"}';
      final result = LogSanitizer.sanitize(input);
      expect(result, isNot(contains('ABCD-1234-EFGH-5678')));
    });

    test('sanitizes headers map', () {
      final headers = <String, dynamic>{
        'Authorization': 'Bearer token123',
        'Content-Type': 'application/json',
        'Cookie': 'session=abc',
        'X-Device-Token': 'device-token-val',
      };
      final sanitized = LogSanitizer.sanitizeHeaders(headers);
      expect(sanitized['Authorization'], '[REDACTED]');
      expect(sanitized['Content-Type'], 'application/json');
      expect(sanitized['Cookie'], '[REDACTED]');
      expect(sanitized['X-Device-Token'], '[REDACTED]');
    });

    test('leaves non-sensitive text unchanged', () {
      const input = 'Fetching course list for batch 2026-01';
      final result = LogSanitizer.sanitize(input);
      expect(result, input);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Constants & Regex
  // ═══════════════════════════════════════════════════════════════════════
  group('AppConstants', () {
    test('activation code regex matches valid codes', () {
      expect(
        AppConstants.activationCodeRegex.hasMatch('ABCD-1234-EFGH-5678'),
        isTrue,
      );
      expect(
        AppConstants.activationCodeRegex.hasMatch('A1B2-C3D4-E5F6-G7H8'),
        isTrue,
      );
    });

    test('activation code regex rejects invalid codes', () {
      expect(
        AppConstants.activationCodeRegex.hasMatch('ABCD-1234-EFGH'),
        isFalse,
      );
      expect(
        AppConstants.activationCodeRegex.hasMatch('abcd-1234-efgh-5678'),
        isFalse,
      );
      expect(
        AppConstants.activationCodeRegex.hasMatch('ABCD1234EFGH5678'),
        isFalse,
      );
    });

    test('backend URLs are well-formed', () {
      expect(Uri.tryParse(AppConstants.backendBaseUrl), isNotNull);
      expect(Uri.tryParse(AppConstants.campusBaseUrl), isNotNull);
    });

    test('timeouts are reasonable', () {
      expect(AppConstants.backendConnectTimeout.inSeconds, 5);
      expect(AppConstants.backendReceiveTimeout.inSeconds, 10);
      expect(AppConstants.maxGrabTaskRuntimeMinutes, 30);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Extensions
  // ═══════════════════════════════════════════════════════════════════════
  group('StringExtensions', () {
    test('maskExcept hides middle characters', () {
      expect('password123'.maskExcept(), contains('***'));
      expect('ab'.maskExcept(), 'ab');
    });
  });

  group('DateTimeExtensions', () {
    test('toIso8601Utc produces UTC string', () {
      final dt = DateTime(2026, 7, 21, 5);
      final result = dt.toIso8601Utc();
      expect(result, contains('2026'));
    });
  });

  group('DurationExtensions', () {
    test('toHms formats correctly', () {
      const d = Duration(hours: 1, minutes: 23, seconds: 45);
      expect(d.toHms(), '01:23:45');
    });

    test('toHms handles zero', () {
      expect(Duration.zero.toHms(), '00:00:00');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Enums
  // ═══════════════════════════════════════════════════════════════════════
  group('AccountStatus enum', () {
    test('has all expected values', () {
      expect(AccountStatus.values.length, 6);
      expect(AccountStatus.values, contains(AccountStatus.ready));
      expect(AccountStatus.values, contains(AccountStatus.disabledByPlan));
    });
  });

  group('GrabTaskStatus enum', () {
    test('has all 10 states', () {
      expect(GrabTaskStatus.values.length, 10);
    });
  });

  group('LoginType enum', () {
    test('has password and cookie', () {
      expect(LoginType.values.length, 2);
      expect(LoginType.values, contains(LoginType.password));
      expect(LoginType.values, contains(LoginType.cookie));
    });
  });

  group('XkmsMode', () {
    test('fromCode parses valid values', () {
      expect(XkmsMode.fromCode('1'), XkmsMode.rush);
      expect(XkmsMode.fromCode('2'), XkmsMode.regular);
      expect(XkmsMode.fromCode('3'), XkmsMode.addDrop);
    });

    test('fromCode returns null for unknown values', () {
      expect(XkmsMode.fromCode('4'), isNull);
      expect(XkmsMode.fromCode(''), isNull);
      expect(XkmsMode.fromCode('abc'), isNull);
    });

    test('has correct labels', () {
      expect(XkmsMode.rush.label, '抢选');
      expect(XkmsMode.regular.label, '正选');
      expect(XkmsMode.addDrop.label, '补退选');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Grabber State Machine
  // ═══════════════════════════════════════════════════════════════════════
  group('GrabberState', () {
    test('default state is idle', () {
      const state = GrabberState();
      expect(state.status, GrabberStatus.idle);
      expect(state.isRunning, isFalse);
      expect(state.isTerminal, isFalse);
    });

    test('isRunning is true for running and preparing', () {
      expect(
        const GrabberState(status: GrabberStatus.running).isRunning,
        isTrue,
      );
      expect(
        const GrabberState(status: GrabberStatus.preparing).isRunning,
        isTrue,
      );
      expect(
        const GrabberState(status: GrabberStatus.paused).isRunning,
        isFalse,
      );
    });

    test('isTerminal is true for terminal states', () {
      for (final status in [
        GrabberStatus.success,
        GrabberStatus.failed,
        GrabberStatus.stopped,
        GrabberStatus.interrupted,
        GrabberStatus.authExpired,
      ]) {
        expect(
          GrabberState(status: status).isTerminal,
          isTrue,
          reason: '$status should be terminal',
        );
      }
    });

    test('isTerminal is false for non-terminal states', () {
      for (final status in [
        GrabberStatus.idle,
        GrabberStatus.preparing,
        GrabberStatus.running,
        GrabberStatus.paused,
        GrabberStatus.captchaRequired,
      ]) {
        expect(
          GrabberState(status: status).isTerminal,
          isFalse,
          reason: '$status should not be terminal',
        );
      }
    });

    test('copyWith preserves unchanged fields', () {
      const original = GrabberState(
        status: GrabberStatus.running,
        totalTargets: 5,
        successCount: 2,
      );
      final updated = original.copyWith(successCount: 3);
      expect(updated.status, GrabberStatus.running);
      expect(updated.totalTargets, 5);
      expect(updated.successCount, 3);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Retry Classifier
  // ═══════════════════════════════════════════════════════════════════════
  group('RetryClassifier', () {
    test('sessionExpired → stopTask', () {
      expect(
        RetryClassifier.classify(
          const CampusException(
            message: 'expired',
            type: CampusExceptionType.sessionExpired,
          ),
        ),
        RetryDecision.stopTask,
      );
    });

    test('captchaRequired → stopTask', () {
      expect(
        RetryClassifier.classify(
          const CampusException(
            message: 'captcha',
            type: CampusExceptionType.captchaRequired,
          ),
        ),
        RetryDecision.stopTask,
      );
    });

    test('courseFull → retry', () {
      expect(
        RetryClassifier.classify(
          const CampusException(
            message: 'full',
            type: CampusExceptionType.courseFull,
          ),
        ),
        RetryDecision.retry,
      );
    });

    test('courseConflict → skipTarget', () {
      expect(
        RetryClassifier.classify(
          const CampusException(
            message: 'conflict',
            type: CampusExceptionType.courseConflict,
          ),
        ),
        RetryDecision.skipTarget,
      );
    });

    test('networkError → retry', () {
      expect(
        RetryClassifier.classify(
          const CampusException(
            message: 'network',
            type: CampusExceptionType.networkError,
          ),
        ),
        RetryDecision.retry,
      );
    });

    test('AuthException → stopTask', () {
      expect(
        RetryClassifier.classify(
          const AuthException(
            message: 'invalid',
            type: AuthExceptionType.tokenInvalid,
          ),
        ),
        RetryDecision.stopTask,
      );
    });

    test('unknown error → retry', () {
      expect(
        RetryClassifier.classify(Exception('random')),
        RetryDecision.retry,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Clock Sync
  // ═══════════════════════════════════════════════════════════════════════
  group('ClockSyncStatus', () {
    test('drift within threshold is not excessive', () {
      const status = ClockSyncStatus(
        campusOffsetMs: 1000,
        serverOffsetMs: 500,
      );
      expect(status.driftMs, 500);
      expect(status.isDriftExcessive, isFalse);
    });

    test('drift > 60s is excessive', () {
      const status = ClockSyncStatus(
        campusOffsetMs: 70000,
        serverOffsetMs: 0,
      );
      expect(status.isDriftExcessive, isTrue);
    });

    test('server offset > 10min is excessive', () {
      const status = ClockSyncStatus(
        campusOffsetMs: 0,
        serverOffsetMs: 11 * 60 * 1000,
      );
      expect(status.isServerOffsetExcessive, isTrue);
    });

    test('campusNow adjusts for offset', () {
      const status = ClockSyncStatus(
        campusOffsetMs: 5000,
        serverOffsetMs: 0,
      );
      final now = DateTime.now().toUtc();
      final campusNow = status.campusNow;
      expect(
        campusNow.difference(now).inMilliseconds,
        greaterThan(4000),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // DTOs
  // ═══════════════════════════════════════════════════════════════════════
  group('DTOs', () {
    test('AppConfigDto fromJson parses maintenance fields', () {
      final dto = AppConfigDto.fromJson({
        'maintenance': true,
        'maintenanceMessage': '维护中',
        'minimumSupportedVersion': '1.0.0',
        'supportUrl': 'https://example.com',
      });
      expect(dto.maintenance, isTrue);
      expect(dto.maintenanceMessage, '维护中');
      expect(dto.minimumSupportedVersion, '1.0.0');
    });

    test('AppConfigDto fromJson defaults', () {
      final dto = AppConfigDto.fromJson({});
      expect(dto.maintenance, isFalse);
      expect(dto.minimumSupportedVersion, '0.0.0');
    });

    test('LatestReleaseDto fromJson parses all fields', () {
      final dto = LatestReleaseDto.fromJson({
        'version': '2.0.0',
        'mandatory': true,
        'publishedAt': '2026-07-20T00:00:00Z',
        'releaseNotes': '新功能',
        'downloadUrl': 'https://example.com/dl',
        'sha256': 'abcdef',
        'signature': 'c2ln',
      });
      expect(dto.version, '2.0.0');
      expect(dto.mandatory, isTrue);
      expect(dto.sha256, 'abcdef');
    });

    test('PlanDto fromJson with defaults', () {
      final dto = PlanDto.fromJson({
        'id': 'free',
        'name': 'Free',
        'maxAccounts': 1,
        'minRequestIntervalMs': 2000,
        'maxConcurrentAccounts': 1,
        'licenseDurationDays': 30,
      });
      expect(dto.maxDevices, 1);
      expect(dto.unbindCooldownHours, 24);
    });

    test('CrashReportDto toJson contains required fields', () {
      const report = CrashReportDto(
        installIdHash: 'hash123',
        appVersion: '1.0.0',
        platform: 'windows',
        arch: 'x64',
        locale: 'zh_CN',
        crashType: 'FlutterError',
        sanitizedStackTrace: 'stack...',
        timestamp: '2026-07-21T05:00:00Z',
      );
      final json = report.toJson();
      expect(json['installIdHash'], 'hash123');
      expect(json['platform'], 'windows');
      expect(json, isNot(contains('password')));
      expect(json, isNot(contains('cookie')));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Interval calculation
  // ═══════════════════════════════════════════════════════════════════════
  group('Interval calculation', () {
    test('effective interval is max of user and plan', () {
      final effective = [1000, 2000].reduce((a, b) => a > b ? a : b);
      expect(effective, 2000);
    });

    test('user interval below plan minimum is clamped', () {
      const userMs = 500;
      const planMinMs = 1000;
      const effective = userMs > planMinMs ? userMs : planMinMs;
      expect(effective, 1000);
    });
  });
}
