import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nkgrabber/features/grabber/application/grabber_engine.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_bus.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_entry.dart';
import 'package:nkgrabber/features/grabber/domain/grabber_state.dart';
import 'package:nkgrabber/infrastructure/campus/campus_adapter.dart';
import 'package:nkgrabber/infrastructure/campus/models/campus_models.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/daos/course_target_dao.dart';
import 'package:nkgrabber/infrastructure/database/daos/grab_task_dao.dart';
import 'package:nkgrabber/infrastructure/database/tables/accounts.dart';
import 'package:nkgrabber/infrastructure/database/tables/grab_tasks.dart';

const _now = '2026-01-01T00:00:00.000Z';
const _deadline = Duration(seconds: 3);

class _Adapter extends Fake implements CampusAdapter {
  _Adapter(this.reply);

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

class _GatedTargets extends CourseTargetDao {
  _GatedTargets(super.db);

  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<List<CourseTargetEntry>> getEnabledByAccount(String accountId) async {
    entered.complete();
    await release.future;
    return super.getEnabledByAccount(accountId);
  }
}

class _GatedTasks extends GrabTaskDao {
  _GatedTasks(super.db);

  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> insertTask(GrabTasksCompanion entry) async {
    await super.insertTask(entry);
    if (!entered.isCompleted) {
      entered.complete();
      await release.future;
    }
  }
}

class _GatedFinalization extends GrabTaskDao {
  _GatedFinalization(super.db);

  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<bool> updateTask(GrabTasksCompanion entry) async {
    if (!entered.isCompleted) {
      entered.complete();
      await release.future;
    }
    return super.updateTask(entry);
  }
}

Future<AppDatabase> _database() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  for (final id in ['a', 'b']) {
    await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        id: id,
        displayName: '测试账号',
        studentNo: 'fixture-$id',
        loginType: LoginType.cookie,
        cookieJarRef: 'fixture-cookie-$id',
        status: AccountStatus.ready,
        createdAt: _now,
        updatedAt: _now,
      ),
    );
    await db.courseTargetDao.insertTarget(
      CourseTargetsCompanion.insert(
        id: 'target-$id',
        accountId: id,
        xkid: 'fixture-batch',
        xkms: '1',
        kmh: 'fixture-course',
        batchName: '测试批次',
        courseName: '测试课程',
        snapshotAt: _now,
      ),
    );
  }
  return db;
}

GrabberEngine _engine(
  AppDatabase db,
  AdapterResolver resolver, {
  CourseTargetDao? targets,
  GrabTaskDao? tasks,
}) {
  final engine = GrabberEngine(
    courseTargetDao: targets ?? db.courseTargetDao,
    grabTaskDao: tasks ?? db.grabTaskDao,
    adapterResolver: resolver,
    maxConcurrentAccounts: 2,
    minRequestIntervalMs: 60000,
    userIntervalMs: 60000,
  );
  addTearDown(engine.dispose);
  return engine;
}

void main() {
  tearDown(grabLogBus.reset);

  test('stop during target loading cannot return to running', () async {
    final db = await _database();
    final targets = _GatedTargets(db);
    var resolutions = 0;
    final engine = _engine(db, (_, {cancelToken}) async {
      resolutions++;
      return null;
    }, targets: targets);

    final running = engine.start(['a']);
    await targets.entered.future.timeout(_deadline);
    engine.stop();
    targets.release.complete();
    await running.timeout(_deadline);

    expect(engine.state.status, GrabberStatus.stopped);
    expect(resolutions, 0);
    expect(await db.grabTaskDao.getByAccount('a'), isEmpty);
  });

  test(
    'stop cancels retrying account and prevents a later account launch',
    () async {
      final db = await _database();
      final first = _Adapter(() async => const SubmitResult(success: false));
      final later = _Adapter(() async => const SubmitResult(success: true));
      final resolvingLater = Completer<void>();
      final resolveLater = Completer<CampusAdapter?>();
      CancelToken? resolverToken;
      final engine = _engine(db, (id, {cancelToken}) async {
        if (id == 'a') return first;
        resolverToken = cancelToken;
        resolvingLater.complete();
        return resolveLater.future;
      });

      final running = engine.start(['a', 'b']);
      await resolvingLater.future.timeout(_deadline);
      await first.submitted.future.timeout(_deadline);
      engine.stop();
      expect(resolverToken?.isCancelled, isTrue);
      resolveLater.complete(later);
      await running.timeout(_deadline);

      expect(engine.state.status, GrabberStatus.stopped);
      expect(first.tokens, hasLength(1));
      expect(first.tokens.single?.isCancelled, isTrue);
      expect(later.tokens, isEmpty);
      expect(await db.grabTaskDao.getByAccount('b'), isEmpty);
      final tasks = await db.grabTaskDao.getByAccount('a');
      expect(tasks.single.status, GrabTaskStatus.stopped);
      expect(tasks.single.stoppedAt, isNotNull);
    },
  );

  test(
    'stop during task insertion finalizes the row without submitting',
    () async {
      final db = await _database();
      final tasks = _GatedTasks(db);
      final adapter = _Adapter(() async => const SubmitResult(success: true));
      var resolutions = 0;
      final engine = _engine(db, (_, {cancelToken}) async {
        resolutions++;
        return adapter;
      }, tasks: tasks);

      final running = engine.start(['a', 'b']);
      await tasks.entered.future.timeout(_deadline);
      engine.stop();
      tasks.release.complete();
      await running.timeout(_deadline);

      expect(adapter.tokens, isEmpty);
      expect(resolutions, 1);
      expect(engine.state.status, GrabberStatus.stopped);
      final rows = await db.grabTaskDao.getByAccount('a');
      expect(rows.single.status, GrabTaskStatus.stopped);
      expect(rows.single.stoppedAt, isNotNull);
      expect(await db.grabTaskDao.getActiveTasks(), isEmpty);
    },
  );

  test(
    'late old run cannot overwrite or cancel an immediate restart',
    () async {
      final db = await _database();
      final oldReply = Completer<SubmitResult>();
      final newReply = Completer<SubmitResult>();
      final first = _Adapter(() => oldReply.future);
      final restarted = _Adapter(() => newReply.future);
      final later = _Adapter(() async => const SubmitResult(success: true));
      final resolvingLater = Completer<void>();
      final resolveLater = Completer<CampusAdapter?>();
      var firstResolutions = 0;
      final engine = _engine(db, (id, {cancelToken}) async {
        if (id == 'a') return firstResolutions++ == 0 ? first : restarted;
        resolvingLater.complete();
        return resolveLater.future;
      });

      final oldRun = engine.start(['a', 'b']);
      await resolvingLater.future.timeout(_deadline);
      await first.submitted.future.timeout(_deadline);
      engine.stop();
      final newRun = engine.start(['a']);
      await restarted.submitted.future.timeout(_deadline);
      final newStartedAt = engine.state.startedAt;

      resolveLater.complete(later);
      oldReply.complete(const SubmitResult(success: true));
      await oldRun.timeout(_deadline);

      expect(later.tokens, isEmpty);
      expect(engine.state.status, GrabberStatus.running);
      expect(engine.state.startedAt, newStartedAt);
      expect(engine.state.successCount, 0);
      expect(restarted.tokens.single?.isCancelled, isFalse);
      expect(
        grabLogBus.entries.where((e) => e.kind == GrabLogKind.success),
        isEmpty,
      );
      final rows = await db.grabTaskDao.getByAccount('a');
      expect(
        rows.where((t) => t.status == GrabTaskStatus.stopped),
        hasLength(1),
      );
      expect(
        rows.where((t) => t.status == GrabTaskStatus.running),
        hasLength(1),
      );

      engine.stop();
      expect(restarted.tokens.single?.isCancelled, isTrue);
      newReply.complete(const SubmitResult(success: true));
      await newRun.timeout(_deadline);
      expect(engine.state.status, GrabberStatus.stopped);
      expect(engine.state.successCount, 0);
      expect(await db.grabTaskDao.getActiveTasks(), isEmpty);
    },
  );

  test('a resolver failure cancels workers already launched', () async {
    final db = await _database();
    final adapter = _Adapter(() async => const SubmitResult(success: false));
    final engine = _engine(db, (id, {cancelToken}) async {
      if (id == 'a') return adapter;
      await adapter.submitted.future;
      throw Exception('fixture resolver failure');
    });

    await engine.start(['a', 'b']).timeout(_deadline);

    expect(engine.state.status, GrabberStatus.failed);
    expect(adapter.tokens, hasLength(1));
    expect(adapter.tokens.single?.isCancelled, isTrue);
    final tasks = await db.grabTaskDao.getByAccount('a');
    expect(tasks.single.status, GrabTaskStatus.failed);
    expect(await db.grabTaskDao.getActiveTasks(), isEmpty);
  });

  for (final dispose in [false, true]) {
    test(
      'finished task status survives ${dispose ? 'dispose' : 'reset'} during persistence',
      () async {
        final db = await _database();
        final tasks = _GatedFinalization(db);
        final adapter = _Adapter(() async => const SubmitResult(success: true));
        final engine = _engine(
          db,
          (_, {cancelToken}) async => adapter,
          tasks: tasks,
        );

        final running = engine.start(['a', 'b']);
        await tasks.entered.future.timeout(_deadline);
        expect(engine.state.status, GrabberStatus.success);
        if (dispose) {
          engine.dispose();
        } else {
          engine.reset();
        }
        tasks.release.complete();
        await running.timeout(_deadline);

        for (final id in ['a', 'b']) {
          final rows = await db.grabTaskDao.getByAccount(id);
          expect(rows.single.status, GrabTaskStatus.success);
        }
      },
    );
  }

  test('an unexpected worker error cannot leave a running task', () async {
    final db = await _database();
    final adapter = _Adapter(() async => throw StateError('fixture'));
    final engine = _engine(db, (_, {cancelToken}) async => adapter);

    await engine.start(['a']).timeout(_deadline);

    expect(engine.state.status, GrabberStatus.failed);
    final rows = await db.grabTaskDao.getByAccount('a');
    expect(rows.single.status, GrabTaskStatus.failed);
    expect(rows.single.stoppedAt, isNotNull);
    expect(await db.grabTaskDao.getActiveTasks(), isEmpty);
  });

  test('dispose during adapter resolution never launches a worker', () async {
    final db = await _database();
    final resolving = Completer<void>();
    final resolve = Completer<CampusAdapter?>();
    final adapter = _Adapter(() async => const SubmitResult(success: true));
    CancelToken? token;
    final engine = _engine(db, (_, {cancelToken}) {
      token = cancelToken;
      resolving.complete();
      return resolve.future;
    });
    final running = engine.start(['a']);
    await resolving.future.timeout(_deadline);
    engine.dispose();
    resolve.complete(adapter);
    await running.timeout(_deadline);

    expect(token?.isCancelled, isTrue);
    expect(adapter.tokens, isEmpty);
    expect(await db.grabTaskDao.getByAccount('a'), isEmpty);
    await engine.start(['a']);
    expect(adapter.tokens, isEmpty);
  });
}
