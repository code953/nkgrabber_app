import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/core/logging/log_sanitizer.dart';
import 'package:nkgrabber/core/security/secure_storage.dart';
import 'package:nkgrabber/core/utils/constants.dart';
import 'package:nkgrabber/core/utils/extensions.dart';
import 'package:nkgrabber/features/courses/presentation/course_config_page.dart';
import 'package:nkgrabber/features/grabber/application/retry_classifier.dart';
import 'package:nkgrabber/features/grabber/domain/grabber_state.dart';
import 'package:nkgrabber/infrastructure/campus/clock_sync.dart';
import 'package:nkgrabber/infrastructure/campus/xkms_enum.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/tables/accounts.dart';
import 'package:nkgrabber/infrastructure/database/tables/grab_tasks.dart';
import 'package:nkgrabber/infrastructure/providers.dart';
import 'package:nkgrabber/l10n/app_localizations.dart';
import 'package:nkgrabber/main.dart' show NKGrabberApp;

/// In-memory secure storage so widget tests never touch the platform keychain.
class _FakeSecureStorage implements SecureStorage {
  final _store = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async =>
      _store[key] = value;

  @override
  Future<String?> read({required String key}) async => _store[key];

  @override
  Future<void> delete({required String key}) async => _store.remove(key);

  @override
  Future<void> deleteAll() async => _store.clear();

  @override
  Future<bool> isAvailable() async => true;
}

/// Pump the real app against an in-memory database.
///
/// The production `appDatabaseProvider` opens a file under the application
/// support directory, which does not resolve in a widget test — the accounts
/// page would spin forever and `pumpAndSettle` would time out.
Future<AppDatabase> _pumpApp(
  WidgetTester tester, {
  AppDatabase? database,
}) async {
  final db = database ?? AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
      ],
      child: const NKGrabberApp(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

const _seedNow = '2026-01-01T00:00:00.000Z';

/// Insert one ready account so pages that need an account can render.
Future<void> _seedAccount(AppDatabase db, {String id = 'a1'}) {
  return db.accountDao.insertAccount(
    AccountsCompanion.insert(
      id: id,
      displayName: '测试账号',
      studentNo: '20260001',
      loginType: LoginType.password,
      cookieJarRef: 'cookie-$id',
      status: AccountStatus.ready,
      createdAt: _seedNow,
      updatedAt: _seedNow,
    ),
  );
}

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

    test('CampusException carries type and message', () {
      const exception = CampusException(
        message: 'Session expired',
        type: CampusExceptionType.sessionExpired,
      );
      expect(exception.message, 'Session expired');
      expect(exception.type, CampusExceptionType.sessionExpired);
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
    test('campus URL is well-formed', () {
      expect(Uri.tryParse(AppConstants.campusBaseUrl), isNotNull);
    });

    test('timeouts are reasonable', () {
      expect(AppConstants.maxGrabTaskRuntimeMinutes, 30);
    });

    test('default user interval is at or above the floor', () {
      expect(
        AppConstants.defaultUserIntervalMs,
        greaterThanOrEqualTo(AppConstants.defaultMinRequestIntervalMs),
      );
    });

    test('default concurrency does not exceed the account limit', () {
      expect(
        AppConstants.defaultMaxConcurrentAccounts,
        lessThanOrEqualTo(AppConstants.defaultMaxAccounts),
      );
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
    test('has all 9 states with no license-related state', () {
      expect(GrabTaskStatus.values.length, 9);
      expect(
        GrabTaskStatus.values.map((e) => e.name),
        isNot(contains('authExpired')),
      );
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
    test('campusNow adjusts forward for a positive offset', () {
      const status = ClockSyncStatus(campusOffsetMs: 5000);
      final now = DateTime.now().toUtc();
      expect(
        status.campusNow.difference(now).inMilliseconds,
        greaterThan(4000),
      );
    });

    test('campusNow adjusts backward for a negative offset', () {
      const status = ClockSyncStatus(campusOffsetMs: -5000);
      final now = DateTime.now().toUtc();
      expect(status.campusNow.difference(now).inMilliseconds, lessThan(-4000));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Interval calculation
  // ═══════════════════════════════════════════════════════════════════════
  group('Interval calculation', () {
    test('effective interval is max of user and floor', () {
      expect(max(1000, 2000), 2000);
    });

    test('user interval below the floor is clamped up', () {
      expect(max(500, 1000), 1000);
    });

    test('user interval above the floor is respected', () {
      expect(max(3000, 800), 3000);
    });

    test('the default pair yields the user interval', () {
      expect(
        max(
          AppConstants.defaultUserIntervalMs,
          AppConstants.defaultMinRequestIntervalMs,
        ),
        AppConstants.defaultUserIntervalMs,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // App shell — regression guard for localization wiring
  // ═══════════════════════════════════════════════════════════════════════
  group('NKGrabberApp', () {
    testWidgets('boots straight into the accounts page', (tester) async {
      await _pumpApp(tester);

      expect(find.text('账号管理'), findsOneWidget);
    });

    testWidgets('shows the empty state when no accounts are stored', (
      tester,
    ) async {
      await _pumpApp(tester);

      expect(find.text('还没有账号'), findsOneWidget);
    });

    testWidgets('lists accounts loaded from the database', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await _seedAccount(db);
      await _pumpApp(tester, database: db);

      expect(find.text('还没有账号'), findsNothing);
      expect(find.text('测试账号'), findsOneWidget);
      expect(find.text('就绪'), findsOneWidget);
    });

    testWidgets('provides MaterialLocalizations under the zh locale', (
      tester,
    ) async {
      await _pumpApp(tester);
      // The 800x600 default surface takes the desktop branch, so this is the
      // NavigationRail that threw "No MaterialLocalizations found" while
      // `localizationsDelegates` was left unset: it calls
      // MaterialLocalizations.of() during build, and the implicit
      // DefaultMaterialLocalizations covers 'en' only.
      final rail = find.byType(NavigationRail);
      expect(rail, findsOneWidget);

      final context = tester.element(rail);
      expect(Localizations.localeOf(context).languageCode, 'zh');
      expect(MaterialLocalizations.of(context), isNotNull);
      expect(S.of(context), isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Course config page
  // ═══════════════════════════════════════════════════════════════════════
  group('CourseConfigPage', () {
    /// Navigate to the 课程 tab via the NavigationRail.
    Future<void> openCourses(WidgetTester tester) async {
      await tester.tap(find.text('课程'));
      await tester.pumpAndSettle();
    }

    testWidgets('prompts for an account when none exist', (tester) async {
      await _pumpApp(tester);
      await openCourses(tester);

      expect(find.text('请先在「账号」页添加校园账号'), findsOneWidget);
    });

    testWidgets('shows the empty target state once an account exists', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      await _seedAccount(db);
      await _pumpApp(tester, database: db);
      await openCourses(tester);

      expect(find.text('还没有配置抢课目标，点击右下角添加'), findsOneWidget);
    });

    testWidgets('renders stored targets in priority order', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await _seedAccount(db);
      // Inserted highest-priority-last to prove the page orders by priority
      // rather than by insertion.
      for (final (id, name, priority) in [
        ('t2', '第二志愿', 1),
        ('t1', '第一志愿', 0),
      ]) {
        await db.courseTargetDao.insertTarget(
          CourseTargetsCompanion.insert(
            id: id,
            accountId: 'a1',
            xkid: 'xk-1',
            xkms: '1',
            kmh: 'km-$id',
            batchName: '春季选课',
            courseName: name,
            priority: Value(priority),
            snapshotAt: _seedNow,
          ),
        );
      }

      await _pumpApp(tester, database: db);
      await openCourses(tester);

      expect(find.text('还没有配置抢课目标，点击右下角添加'), findsNothing);
      expect(find.text('春季选课 · 抢选'), findsNWidgets(2));

      final cards = tester
          .widgetList<TargetListCard>(find.byType(TargetListCard))
          .toList();
      expect(cards.map((c) => c.courseName), ['第一志愿', '第二志愿']);
    });
  });
}
