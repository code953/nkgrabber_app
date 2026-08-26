/// Riverpod wiring for the grabber engine.
///
/// The engine owns a broadcast stream rather than Riverpod state, so this
/// notifier mirrors that stream into a `StateNotifier` the UI can watch.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/features/accounts/application/accounts_notifier.dart';
import 'package:nkgrabber/features/grabber/application/grabber_engine.dart';
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
  );

  return GrabberController(engine);
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

  /// Stop the current task.
  void stop() => _engine.stop();

  /// Pause the current task.
  void pause() => _engine.pause();

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
