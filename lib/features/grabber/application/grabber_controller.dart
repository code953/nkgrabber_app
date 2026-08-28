/// Riverpod wiring for the grabber engine.
///
/// The engine owns a broadcast stream rather than Riverpod state, so this
/// notifier mirrors that stream into a `StateNotifier` the UI can watch.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/features/accounts/application/accounts_notifier.dart';
import 'package:nkgrabber/features/grabber/application/grabber_engine.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_bus.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_entry.dart';
import 'package:nkgrabber/features/grabber/domain/grabber_state.dart';
import 'package:nkgrabber/infrastructure/providers.dart';

/// Builds the engine from current settings and exposes its state.
///
/// Watches [appSettingsProvider], so changing the interval or concurrency in
/// the settings page rebuilds the engine. That is safe only while idle — a
/// rebuild mid-run would orphan the running workers, so the settings page
/// disables those controls while a task is active.
final grabberProvider = StateNotifierProvider<GrabberController, GrabberState>((
  ref,
) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;

  final engine = GrabberEngine(
    courseTargetDao: ref.watch(courseTargetDaoProvider),
    grabTaskDao: ref.watch(grabTaskDaoProvider),
    // Resolved lazily so a restart rehydrates the client from the stored
    // cookie instead of reporting "no adapter".
    adapterResolver: ref.read(accountsProvider.notifier).ensureAdapter,
    maxConcurrentAccounts: settings?.maxConcurrentAccounts ?? 3,
    minRequestIntervalMs: settings?.minRequestIntervalMs ?? 800,
    userIntervalMs: settings?.userIntervalMs ?? 1000,
    debugMode: settings?.debugModeEnabled ?? false,
    // Read, not watch: a label is cosmetic, and re-watching the account list
    // would rebuild the engine mid-run every time an account row changed.
    accountLabels: (id) => ref
        .read(accountsProvider)
        .accounts
        .where((a) => a.id == id)
        .map((a) => a.displayName)
        .firstOrNull,
  );

  return GrabberController(engine);
});

/// The live request/response log, newest last.
///
/// Seeded with the buffered backlog because the grabber page is usually built
/// after a run has already produced lines.
final grabLogProvider = StreamProvider<List<GrabLogEntry>>((ref) async* {
  yield grabLogBus.entries;
  await for (final _ in grabLogBus.stream) {
    yield grabLogBus.entries;
  }
});

/// Mirrors [GrabberEngine.stateStream] into Riverpod and forwards commands.
class GrabberController extends StateNotifier<GrabberState> {
  GrabberController(this._engine) : super(_engine.state) {
    _subscription = _engine.stateStream.listen((s) => state = s);
  }

  final GrabberEngine _engine;
  late final StreamSubscription<GrabberState> _subscription;

  /// Start grabbing for the given accounts.
  Future<void> start(List<String> accountIds) => _engine.start(accountIds);

  /// Stop the current task. The state becomes `stopped`, from which
  /// [start] may be called again without a reset.
  void stop() => _engine.stop();

  /// Return to the idle state so a new task can be started.
  void reset() => _engine.reset();

  /// Flag tasks left running by a crash. Called once at app start.
  Future<void> markInterrupted() => _engine.markInterrupted();

  @override
  void dispose() {
    _subscription.cancel();
    _engine.dispose();
    super.dispose();
  }
}
