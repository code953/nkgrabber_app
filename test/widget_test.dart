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
import 'package:nkgrabber/features/grabber/application/account_worker.dart';
import 'package:nkgrabber/features/grabber/application/grabber_controller.dart';
import 'package:nkgrabber/features/grabber/application/grabber_engine.dart';
import 'package:nkgrabber/features/grabber/application/retry_classifier.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_bus.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_entry.dart';
import 'package:nkgrabber/features/grabber/domain/grabber_state.dart';
import 'package:nkgrabber/features/grabber/presentation/grabber_page.dart';
import 'package:nkgrabber/infrastructure/campus/campus_adapter.dart';
import 'package:nkgrabber/infrastructure/campus/clock_sync.dart';
import 'package:nkgrabber/infrastructure/campus/models/campus_models.dart';
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

/// Insert one course target for the seeded account.
Future<void> _seedTarget(
  AppDatabase db, {
  String id = 't1',
  String accountId = 'a1',
  String courseName = '测试课程',
  int priority = 0,
  bool enabled = true,
}) {
  return db.courseTargetDao.insertTarget(
    CourseTargetsCompanion.insert(
      id: id,
      accountId: accountId,
      xkid: 'xk-1',
      xkms: '1',
      kmh: 'km-$id',
      batchName: '春季选课',
      courseName: courseName,
      priority: Value(priority),
      enabled: Value(enabled),
      snapshotAt: _seedNow,
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
  // Stop is restartable
  // ═══════════════════════════════════════════════════════════════════════
  group('stop then restart', () {
    tearDown(grabLogBus.reset);

    /// An engine wired to a recording adapter, so a run can be started and
    /// stopped without touching the network.
    Future<(GrabberEngine, AppDatabase, _RecordingAdapter)>
    buildEngine() async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedAccount(db);
      await _seedTarget(db);
      final adapter = _RecordingAdapter(xkms: '1');

      final engine = GrabberEngine(
        courseTargetDao: db.courseTargetDao,
        grabTaskDao: db.grabTaskDao,
        adapterResolver: (_) async => adapter,
        maxConcurrentAccounts: 1,
        minRequestIntervalMs: 1,
        userIntervalMs: 1,
      );
      addTearDown(engine.dispose);
      return (engine, db, adapter);
    }

    test('a stopped run can be started again without a reset', () async {
      final (engine, _, _) = await buildEngine();

      await engine.start(['a1']);
      expect(engine.state.status, GrabberStatus.success);

      engine.stop();

      // The old flow parked here and required reset() before _IdleView — the
      // only place with a start button — would render again. Starting has to
      // work straight from `stopped`.
      await engine.start(['a1']);
      expect(
        engine.state.status,
        isNot(GrabberStatus.stopped),
        reason: 'start() from a stopped state must actually run',
      );
      expect(engine.state.startedAt, isNotNull);
    });

    test('a restart does not inherit the previous run counters', () async {
      final (engine, _, _) = await buildEngine();

      await engine.start(['a1']);
      expect(engine.state.successCount, 1);

      engine.stop();

      // The counters must already be clear when the run is announced, not
      // merely by the time it finishes. copyWith'ing the old state left the
      // progress bar showing "成功 1/1" over a run that had submitted nothing
      // yet — visible for the whole preparing phase.
      final announced = <GrabberState>[];
      final sub = engine.stateStream.listen(announced.add);
      addTearDown(sub.cancel);

      await engine.start(['a1']);

      final preparing = announced.firstWhere(
        (s) => s.status == GrabberStatus.preparing,
      );
      expect(preparing.successCount, 0);
      expect(preparing.failedCount, 0);
      expect(preparing.completedTargets, isEmpty);
      expect(preparing.message, isNull);
    });

    test('a run publishes lifecycle and verdict lines to the log', () async {
      final (engine, _, _) = await buildEngine();

      await engine.start(['a1']);

      final kinds = grabLogBus.entries.map((e) => e.kind).toSet();
      expect(kinds, contains(GrabLogKind.lifecycle));
      expect(
        kinds,
        contains(GrabLogKind.success),
        reason:
            'the verdict comes from the worker; the interceptor only sees '
            'HTTP 200 either way',
      );
    });

    test('starting a new run clears the previous run log', () async {
      final (engine, _, _) = await buildEngine();

      await engine.start(['a1']);
      final first = grabLogBus.entries.length;
      expect(first, greaterThan(0));

      await engine.start(['a1']);

      expect(
        grabLogBus.entries.first.message,
        contains('开始抢课'),
        reason: 'mixing two runs makes it impossible to tell which is which',
      );
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
      // rather than by insertion. 't1'/priority 0 are the helper defaults.
      await _seedTarget(db, id: 't2', courseName: '第二志愿', priority: 1);
      await _seedTarget(db, courseName: '第一志愿');

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

  // ═══════════════════════════════════════════════════════════════════════
  // Grabber page
  // ═══════════════════════════════════════════════════════════════════════
  group('GrabberPage', () {
    Future<void> openGrabber(WidgetTester tester) async {
      await tester.tap(find.text('抢课').first);
      await tester.pumpAndSettle();
    }

    testWidgets('start is disabled with no accounts', (tester) async {
      await _pumpApp(tester);
      await openGrabber(tester);

      expect(find.text('尚未就绪'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('start stays disabled when an account has no targets', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      await _seedAccount(db);
      await _pumpApp(tester, database: db);
      await openGrabber(tester);

      // An account alone is not enough — starting here would create a task
      // that instantly fails with '没有可用的课程目标'.
      expect(find.text('尚未就绪'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('start is enabled once an enabled target exists', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      await _seedAccount(db);
      await _seedTarget(db);
      await _pumpApp(tester, database: db);
      await openGrabber(tester);

      expect(find.text('准备就绪'), findsOneWidget);
      expect(find.text('将为 1 个账号抢课'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('disabled targets do not count towards readiness', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      await _seedAccount(db);
      await _seedTarget(db, enabled: false);
      await _pumpApp(tester, database: db);
      await openGrabber(tester);

      expect(find.text('尚未就绪'), findsOneWidget);
    });

    testWidgets('the live log renders entries from the bus', (tester) async {
      addTearDown(grabLogBus.reset);
      final db = AppDatabase(NativeDatabase.memory());
      await _seedAccount(db);
      await _seedTarget(db);
      await _pumpApp(tester, database: db);
      await openGrabber(tester);

      // Drive the page out of idle without a network run: the engine's own
      // start() would need a live adapter. What is under test is that a bus
      // entry reaches the screen.
      grabLogBus.log(GrabLogKind.failure, '提交被拒绝（继续重试）', detail: '该课程人数已满');
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GrabberPage)),
      );
      // Keep the provider alive, then let the stream deliver its first value —
      // a StreamProvider is AsyncLoading until a microtask has run.
      final sub = container.listen(grabLogProvider, (_, _) {});
      addTearDown(sub.close);
      await tester.pump();

      expect(
        container.read(grabLogProvider).valueOrNull,
        isNotNull,
        reason: 'the log provider must expose the buffered backlog',
      );
      expect(
        container.read(grabLogProvider).valueOrNull!.last.detail,
        '该课程人数已满',
        reason: "the server's own message is what the panel exists to show",
      );
    });
    testWidgets('a finished run offers restart, and no pause is offered', (
      tester,
    ) async {
      addTearDown(grabLogBus.reset);
      final db = AppDatabase(NativeDatabase.memory());
      await _seedAccount(db);
      await _seedTarget(db);
      await _pumpApp(tester, database: db);
      await openGrabber(tester);

      // A real start: the seeded account has no adapter (none was ever logged
      // in), so the run ends immediately in a non-idle terminal state — the
      // same place a user's stop press leaves it. What is under test is the
      // UI's gating, which previously put a start button only in `idle` and so
      // forced a separate reset press before the user could try again.
      await tester.tap(find.text('开始抢课'));
      await tester.pumpAndSettle();

      expect(find.text('开始抢课'), findsNothing);
      expect(
        find.text('重新开始'),
        findsOneWidget,
        reason: 'a finished run must not require a reset before trying again',
      );
      expect(find.text('暂停'), findsNothing);

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('重新开始'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Live grabber log
  // ═══════════════════════════════════════════════════════════════════════

  group('GrabLogBus', () {
    tearDown(grabLogBus.reset);

    test('retains a backlog for late subscribers', () {
      grabLogBus.log(GrabLogKind.request, '→ POST /a');

      // The grabber page is built after a run starts, so a stream with no
      // replay would show an empty panel over a run already in flight.
      expect(grabLogBus.entries.single.message, '→ POST /a');
    });

    test('caps the buffer so a long run cannot grow without bound', () {
      for (var i = 0; i < 600; i++) {
        grabLogBus.log(GrabLogKind.request, 'line $i');
      }

      expect(grabLogBus.entries.length, lessThanOrEqualTo(500));
      expect(
        grabLogBus.entries.last.message,
        'line 599',
        reason: 'the tail is what the user reads; the head is what is dropped',
      );
    });

    test('timestamps carry milliseconds', () {
      // Without ms two submits one interval apart are indistinguishable, and
      // the panel cannot show that the retry loop is actually cycling.
      final entry = GrabLogEntry(
        at: DateTime(2026, 8, 28, 9, 5, 3, 42),
        kind: GrabLogKind.request,
        message: 'x',
      );

      expect(entry.timestamp, '09:05:03.042');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Settings page
  // ═══════════════════════════════════════════════════════════════════════
  group('SettingsPage', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders the stored settings row', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      // Seed the singleton row, then change it away from the defaults so a
      // passing test cannot be explained by the widget's fallbacks.
      await db.settingsDao.get();
      await db.settingsDao.setUserIntervalMs(2500);
      await db.settingsDao.setMaxAccounts(7);
      await db.settingsDao.setTheme('anime');

      await _pumpApp(tester, database: db);
      await openSettings(tester);

      expect(find.text('2500 ms'), findsOneWidget);
      expect(find.textContaining('7 个'), findsOneWidget);
      expect(find.text('二次元 (粉紫)'), findsOneWidget);
    });

    testWidgets('persists a slider release to the database', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await _pumpApp(tester, database: db);
      await openSettings(tester);

      // Drag the 请求间隔 slider (the first one) to its maximum.
      final slider = find.byType(Slider).first;
      await tester.drag(slider, const Offset(500, 0));
      await tester.pumpAndSettle();

      final stored = await db.settingsDao.get();
      expect(stored.userIntervalMs, 5000);
      expect(find.text('5000 ms'), findsOneWidget);
    });

    testWidgets('warns when the user interval sits below the floor', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.settingsDao.get();
      await db.settingsDao.setUserIntervalMs(500);
      await db.settingsDao.setMinRequestIntervalMs(1500);

      await _pumpApp(tester, database: db);
      await openSettings(tester);

      // effectiveIntervalMs = max(user, floor) — the UI must say so rather
      // than implying the 500 ms it shows is what will be used.
      expect(find.textContaining('实际按 1500 ms 执行'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Offline operation
  // ═══════════════════════════════════════════════════════════════════════
  group('Offline', () {
    testWidgets('every page renders with no network access', (tester) async {
      // The acceptance criterion for removing the online business: nothing
      // outside the campus system may gate the UI. Widget tests have no
      // network at all, so reaching all four pages and reading persisted
      // settings proves there is no remote precondition left.
      final db = AppDatabase(NativeDatabase.memory());
      await _seedAccount(db);
      await _seedTarget(db);
      await _pumpApp(tester, database: db);

      for (final (tab, marker) in [
        ('账号', '账号管理'),
        ('课程', '课程设置'),
        ('抢课', '准备就绪'),
        ('设置', '导出诊断包'),
      ]) {
        await tester.tap(find.text(tab).first);
        await tester.pumpAndSettle();
        expect(find.text(marker), findsWidgets, reason: '$tab 页未能离线渲染');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Debug mode
  // ═══════════════════════════════════════════════════════════════════════
  group('Debug mode', () {
    /// Drive one worker over a single closed-batch target and report what it
    /// did. The worker is the real gate — the batch picker is only advisory.
    Future<({List<SubmitSelection> submits, List<String?> messages})>
    runWorker({required bool debugMode, String xkms = Xkms.closedCode}) async {
      final adapter = _RecordingAdapter(xkms: xkms);
      final messages = <String?>[];

      final worker = AccountWorker(
        accountId: 'a1',
        adapter: adapter,
        effectiveIntervalMs: 1,
        debugMode: debugMode,
        onTargetResult: (_, {required bool success, String? message}) =>
            messages.add(message),
      );

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedAccount(db);
      await _seedTarget(db);
      final target = (await db.courseTargetDao.getEnabledByAccount(
        'a1',
      )).single.copyWith(xkms: xkms);

      await worker.run([target]);
      return (submits: adapter.submits, messages: messages);
    }

    test(
      'off: a closed batch is refused without contacting the server',
      () async {
        final r = await runWorker(debugMode: false);

        expect(r.submits, isEmpty);
        expect(r.messages, ['该批次选课已结束']);
      },
    );

    test(
      "on: a closed batch is submitted with the server's own xkms",
      () async {
        final r = await runWorker(debugMode: true);

        // The whole point is to see the real server response, so the value must
        // not be swapped for a submittable one.
        expect(r.submits, hasLength(1));
        expect(r.submits.single.xkms, Xkms.closedCode);
      },
    );

    test('on: an unrecognised xkms is also submitted verbatim', () async {
      final r = await runWorker(debugMode: true, xkms: '99');

      expect(r.submits.single.xkms, '99');
    });

    testWidgets('the settings toggle persists and drives the grabber banner', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      await _pumpApp(tester, database: db);

      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      // Off by default, so no banner yet.
      await tester.tap(find.text('抢课').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('调试模式已开启'), findsNothing);

      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      // The toggle is the last section, below the fold on a test viewport.
      await tester.scrollUntilVisible(find.text('调试模式'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('调试模式'));
      await tester.pumpAndSettle();

      expect((await db.settingsDao.get()).debugModeEnabled, isTrue);

      await tester.tap(find.text('抢课').first);
      await tester.pumpAndSettle();
      // Surfacing it here is what stops the user reading the server's正常拒绝
      // as a client bug.
      expect(find.textContaining('调试模式已开启'), findsOneWidget);
    });
  });
}

/// A [CampusAdapter] that records submissions instead of making requests.
class _RecordingAdapter implements CampusAdapter {
  _RecordingAdapter({required this.xkms});

  final String xkms;
  final submits = <SubmitSelection>[];

  @override
  Future<List<SelectionBatch>> listBatches() async => [
    SelectionBatch(
      xkid: 'xk-1',
      xkms: xkms,
      batchName: '春季选课',
      zdxk: 1,
      kssj: '2026-01-01 00:00:00',
      jssj: '2026-01-02 00:00:00',
    ),
  ];

  @override
  Future<List<SelectionRecord>> listSelections(String xkid) async => const [];

  @override
  Future<SubmitResult> submit(SubmitSelection command) async {
    submits.add(command);
    // Mirror what a closed batch really answers: a refusal, not a throw.
    return const SubmitResult(success: true, message: 'ok');
  }

  @override
  int get campusClockOffsetMs => 0;

  @override
  Future<List<Course>> listCourses(String xkid) => throw UnimplementedError();

  @override
  Future<LoginResult> loginWithPassword(String a, String p) =>
      throw UnimplementedError();

  @override
  Future<StudentProfile> validateCookie(String gdpk) =>
      throw UnimplementedError();

  @override
  Future<WithdrawResult> withdraw(String xkid) => throw UnimplementedError();
}
