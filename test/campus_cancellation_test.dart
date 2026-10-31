import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/core/security/secure_storage.dart';
import 'package:nkgrabber/features/accounts/application/accounts_notifier.dart';
import 'package:nkgrabber/features/grabber/application/account_worker.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_bus.dart';
import 'package:nkgrabber/infrastructure/campus/campus_adapter.dart';
import 'package:nkgrabber/infrastructure/campus/campus_adapter_impl.dart';
import 'package:nkgrabber/infrastructure/campus/campus_client_factory.dart';
import 'package:nkgrabber/infrastructure/campus/models/campus_models.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/tables/accounts.dart';

const _deadline = Duration(seconds: 3);
const _now = '2026-01-01T00:00:00.000Z';
const _success =
    '{"result":{"code":"0","msg":"提交成功！","data":"1"},"status":200}';
// Only structurally relevant, synthetic identity fields are supplied. No test
// connects to a campus host: every CampusClient uses this recording transport.
const _profile =
    '{"result":[{"xsid":"fixture-student","xkid":"fixture-batch"}],"status":200}';
const _name = '{"result":[{"xm":"测试用户"}],"status":200}';
const _emptyRows = '{"result":null,"status":200}';
const _command = SubmitSelection(
  xkid: 'fixture-batch',
  xkms: '1',
  kmhList: ['fixture-course'],
);
const _target = CourseTargetEntry(
  id: 'target-a',
  accountId: 'a',
  xkid: 'fixture-batch',
  xkms: '1',
  zdxk: 1,
  kmh: 'fixture-course',
  batchName: '测试批次',
  courseName: '测试课程',
  priority: 0,
  enabled: true,
  snapshotAt: _now,
);

Matcher get _cancelled =>
    isA<DioException>().having((e) => e.type, 'type', DioExceptionType.cancel);

class _PendingRequest {
  _PendingRequest(this.options, Future<void>? cancelFuture) {
    cancelFuture?.then((_) {
      if (!cancelled.isCompleted) cancelled.complete();
    });
  }

  final RequestOptions options;
  final response = Completer<ResponseBody>();
  final cancelled = Completer<void>();

  void reply(String body) {
    if (!response.isCompleted) {
      response.complete(ResponseBody.fromString(body, 200));
    }
  }
}

/// Records actual Dio dispatch, including its transport cancellation signal.
/// Replies are deliberately held independently of cancellation to simulate a
/// response arriving after the user has stopped the run.
class _RecordingTransport implements HttpClientAdapter {
  final requests = <_PendingRequest>[];
  final _waiting = <int, Completer<_PendingRequest>>{};
  bool closed = false;

  Future<_PendingRequest> request(int index) {
    if (requests.length > index) return Future.value(requests[index]);
    return (_waiting[index] ??= Completer<_PendingRequest>()).future.timeout(
      _deadline,
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    expect(options.uri.host, '127.0.0.1');
    final pending = _PendingRequest(options, cancelFuture);
    requests.add(pending);
    _waiting.remove(requests.length - 1)?.complete(pending);
    return pending.response.future;
  }

  @override
  void close({bool force = false}) {
    closed = true;
    for (final request in requests) {
      request.reply(_emptyRows);
    }
  }
}

CampusClient _client(_RecordingTransport transport) {
  return CampusClient(accountId: 'a', baseUrl: 'http://127.0.0.1:1')
    ..dio.httpClientAdapter = transport;
}

class _Storage extends Fake implements SecureStorage {
  final entered = Completer<void>();
  Completer<String?>? reply;
  int reads = 0;

  @override
  Future<String?> read({required String key}) async {
    reads++;
    if (!entered.isCompleted) entered.complete();
    return reply == null ? 'fixture-cookie' : reply!.future;
  }
}

class _WorkerAdapter extends Fake implements CampusAdapter {
  _WorkerAdapter(this.reply);

  final Future<SubmitResult> Function() reply;
  final submitted = Completer<void>();
  final tokens = <CancelToken?>[];

  @override
  Future<SubmitResult> submit(
    SubmitSelection command, {
    CancelToken? cancelToken,
  }) {
    tokens.add(cancelToken);
    if (!submitted.isCompleted) submitted.complete();
    return reply();
  }
}

Future<AppDatabase> _database() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await db.accountDao.insertAccount(
    AccountsCompanion.insert(
      id: 'a',
      displayName: '测试账号',
      studentNo: 'fixture-student',
      loginType: LoginType.cookie,
      cookieJarRef: 'fixture-cookie-ref',
      status: AccountStatus.ready,
      createdAt: _now,
      updatedAt: _now,
    ),
  );
  return db;
}

void main() {
  setUp(grabLogBus.reset);
  tearDown(grabLogBus.reset);

  group('CampusAdapterImpl cancellation', () {
    late _RecordingTransport transport;
    late CampusAdapterImpl adapter;

    setUp(() {
      transport = _RecordingTransport();
      final client = _client(transport);
      addTearDown(client.dispose);
      adapter = CampusAdapterImpl(client: client);
    });

    test(
      'queued submit cancels promptly without sending or breaking serialization',
      () async {
        final first = adapter.submit(_command);
        final inFlight = await transport.request(0);
        final token = CancelToken();
        final queued = adapter.submit(_command, cancelToken: token);
        final cancelled = expectLater(queued, throwsA(_cancelled));
        token.cancel();
        // Cancellation must finish before the unrelated first request does.
        await cancelled.timeout(_deadline);

        final third = adapter.listBatches();
        await Future<void>.delayed(Duration.zero);
        expect(transport.requests, hasLength(1));
        inFlight.reply(_success);
        expect((await first).success, isTrue);
        final next = await transport.request(1);
        expect(next.options.path, '/njs_3033/xsxk/getStudentXkList');
        next.reply(_emptyRows);
        await third;
        expect(transport.requests, hasLength(2));
      },
    );

    test(
      'in-flight submit passes cancellation to the real Dio transport',
      () async {
        final token = CancelToken();
        final result = adapter.submit(_command, cancelToken: token);
        final cancelled = expectLater(result, throwsA(_cancelled));
        final pending = await transport.request(0);
        expect(pending.options.cancelToken, same(token));
        token.cancel();
        await cancelled.timeout(_deadline);
        await pending.cancelled.future.timeout(_deadline);
        pending.reply(_success);

        // A cancelled request must not poison the account's queue or token.
        final next = adapter.submit(_command, cancelToken: CancelToken());
        (await transport.request(1)).reply(_success);
        expect((await next).success, isTrue);
      },
    );

    for (final cancelDuringName in [false, true]) {
      test(
        'cookie validation propagates cancellation during ${cancelDuringName ? 'name' : 'profile'} lookup',
        () async {
          final token = CancelToken();
          final result = adapter.validateCookie(
            'fixture-cookie',
            cancelToken: token,
          );
          final cancelled = expectLater(result, throwsA(_cancelled));
          var pending = await transport.request(0);
          if (cancelDuringName) {
            pending.reply(_profile);
            pending = await transport.request(1);
          }
          expect(pending.options.cancelToken, same(token));
          token.cancel();
          await cancelled.timeout(_deadline);
          await pending.cancelled.future.timeout(_deadline);
          pending.reply(cancelDuringName ? _name : _profile);

          // Drain the same queue to prove that validation cannot resume and
          // start a name lookup after its profile request was cancelled.
          final drain = adapter.listBatches();
          final next = await transport.request(cancelDuringName ? 2 : 1);
          expect(next.options.path, '/njs_3033/xsxk/getStudentXkList');
          next.reply(_emptyRows);
          await drain;
        },
      );
    }
  });

  group('AccountWorker cancellation', () {
    for (final lateError in [false, true]) {
      test(
        'stop ignores a late ${lateError ? 'error' : 'success'} and emits no old verdict',
        () async {
          final reply = Completer<SubmitResult>();
          final adapter = _WorkerAdapter(() => reply.future);
          final results = <bool>[];
          final worker = AccountWorker(
            accountId: 'a',
            adapter: adapter,
            effectiveIntervalMs: 60000,
            onTargetResult: (_, {required success, message}) =>
                results.add(success),
          );
          addTearDown(worker.cancel);
          final running = worker.run([_target]);
          await adapter.submitted.future;
          worker.cancel();
          expect(adapter.tokens.single, isNotNull);
          expect(adapter.tokens.single!.isCancelled, isTrue);
          grabLogBus.reset(); // A restarted run owns the display now.
          if (lateError) {
            reply.completeError(
              const CampusException(
                message: 'fixture session rejection',
                type: CampusExceptionType.sessionExpired,
              ),
            );
          } else {
            reply.complete(const SubmitResult(success: true));
          }
          expect(await running.timeout(_deadline), isNull);
          expect(results, isEmpty);
          expect(grabLogBus.entries, isEmpty);
          expect(adapter.tokens, hasLength(1));
        },
      );
    }

    testWidgets('stop wakes retry wait and removes its timer', (tester) async {
      final adapter = _WorkerAdapter(
        () async => const SubmitResult(success: false),
      );
      final worker = AccountWorker(
        accountId: 'a',
        adapter: adapter,
        effectiveIntervalMs: 60000,
        onTargetResult: (_, {required success, message}) =>
            fail('No verdict expected'),
      );
      addTearDown(worker.cancel);
      var completed = false;
      final running = worker.run([_target]).then((_) => completed = true);
      await tester.pump();
      expect(adapter.tokens, hasLength(1));
      expect(completed, isFalse);
      worker.cancel();
      await tester.pump();
      expect(completed, isTrue);
      await running;
      // Deliberately do not advance 60s: testWidgets' pending-timer invariant
      // also catches racing the delay without actually cancelling its timer.
      expect(adapter.tokens, hasLength(1));
    });
  });

  group('AccountsNotifier restoration cancellation', () {
    test(
      'pre-cancelled restoration never reads credentials or creates a client',
      () async {
        final db = await _database();
        final storage = _Storage();
        final notifier = AccountsNotifier(
          accountDao: db.accountDao,
          secureStorage: storage,
          clientFactory: (_) => throw StateError('Must not create a client'),
        );
        addTearDown(notifier.dispose);
        await expectLater(
          notifier.ensureAdapter('a', cancelToken: CancelToken()..cancel()),
          throwsA(_cancelled),
        );
        expect(storage.reads, 0);
        expect((await db.accountDao.getById('a'))!.status, AccountStatus.ready);
      },
    );

    test(
      'stop while credentials load prevents validation and does not expire account',
      () async {
        final db = await _database();
        final storage = _Storage()..reply = Completer<String?>();
        final notifier = AccountsNotifier(
          accountDao: db.accountDao,
          secureStorage: storage,
          clientFactory: (_) => throw StateError('Must not create a client'),
        );
        addTearDown(notifier.dispose);
        final token = CancelToken();
        final restoring = notifier.ensureAdapter('a', cancelToken: token);
        final cancelled = expectLater(restoring, throwsA(_cancelled));
        await storage.entered.future;
        token.cancel();
        storage.reply!.complete('fixture-cookie');
        await cancelled.timeout(_deadline);
        expect(notifier.getAdapter('a'), isNull);
        expect((await db.accountDao.getById('a'))!.status, AccountStatus.ready);
      },
    );

    for (final cancelDuringName in [false, true]) {
      test(
        'stop during ${cancelDuringName ? 'name' : 'profile'} validation releases only its client, not account',
        () async {
          final db = await _database();
          final transports = <_RecordingTransport>[];
          final oldCreated = Completer<_RecordingTransport>();
          final freshCreated = Completer<_RecordingTransport>();
          final notifier = AccountsNotifier(
            accountDao: db.accountDao,
            secureStorage: _Storage(),
            clientFactory: (_) {
              final transport = _RecordingTransport();
              transports.add(transport);
              (transports.length == 1 ? oldCreated : freshCreated).complete(
                transport,
              );
              return _client(transport);
            },
          );
          addTearDown(notifier.dispose);
          final token = CancelToken();
          final restoring = notifier.ensureAdapter('a', cancelToken: token);
          final cancelled = expectLater(restoring, throwsA(_cancelled));
          final old = await oldCreated.future.timeout(_deadline);
          var pending = await old.request(0);
          if (cancelDuringName) {
            pending.reply(_profile);
            pending = await old.request(1);
          }
          token.cancel();
          await cancelled.timeout(_deadline);
          await pending.cancelled.future.timeout(_deadline);
          expect(old.closed, isTrue);
          expect(notifier.getAdapter('a'), isNull);
          expect(
            (await db.accountDao.getById('a'))!.status,
            AccountStatus.ready,
          );

          final restarted = notifier.ensureAdapter(
            'a',
            cancelToken: CancelToken(),
          );
          final fresh = await freshCreated.future.timeout(_deadline);
          (await fresh.request(0)).reply(_profile);
          (await fresh.request(1)).reply(_name);
          final adapter = await restarted.timeout(_deadline);
          expect(adapter, isNotNull);
          expect(notifier.getAdapter('a'), same(adapter));
          expect(fresh.closed, isFalse);
          expect(
            (await db.accountDao.getById('a'))!.status,
            AccountStatus.ready,
          );
        },
      );
    }

    test(
      'a genuine cookie refusal still expires the account and releases client',
      () async {
        final db = await _database();
        final transport = _RecordingTransport();
        final notifier = AccountsNotifier(
          accountDao: db.accountDao,
          secureStorage: _Storage(),
          clientFactory: (_) => _client(transport),
        );
        addTearDown(notifier.dispose);
        final restoring = notifier.ensureAdapter('a');
        (await transport.request(
          0,
        )).reply('{"error":{"code":"-32604","message":"account expired"}}');
        expect(await restoring.timeout(_deadline), isNull);
        expect(notifier.getAdapter('a'), isNull);
        expect(transport.closed, isTrue);
        expect(
          (await db.accountDao.getById('a'))!.status,
          AccountStatus.expired,
        );
      },
    );
  });
}
