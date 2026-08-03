import 'package:flutter_test/flutter_test.dart';
import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/core/logging/log_sanitizer.dart';
import 'package:nkgrabber/core/utils/constants.dart';

void main() {
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
  });

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

    test('sanitizes headers map', () {
      final headers = <String, dynamic>{
        'Authorization': 'Bearer token123',
        'Content-Type': 'application/json',
        'Cookie': 'session=abc',
      };
      final sanitized = LogSanitizer.sanitizeHeaders(headers);
      expect(sanitized['Authorization'], '[REDACTED]');
      expect(sanitized['Content-Type'], 'application/json');
      expect(sanitized['Cookie'], '[REDACTED]');
    });

    test('leaves non-sensitive text unchanged', () {
      const input = 'Fetching course list for batch 2026-01';
      final result = LogSanitizer.sanitize(input);
      expect(result, input);
    });
  });

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
  });
}
