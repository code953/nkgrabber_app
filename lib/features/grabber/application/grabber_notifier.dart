/// Grabber notifier — Riverpod state provider for the grabber engine.
///
/// Bridges the [GrabberEngine] to the UI layer via [StateNotifier].
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/features/grabber/application/grabber_engine.dart';
import 'package:nkgrabber/features/grabber/domain/grabber_state.dart';

/// Notifier wrapping the grabber engine for Riverpod.
class GrabberNotifier extends StateNotifier<GrabberState> {
  GrabberNotifier({required GrabberEngine engine})
    : _engine = engine,
      super(const GrabberState()) {
    _subscription = _engine.stateStream.listen((engineState) {
      state = engineState;
    });
  }

  final GrabberEngine _engine;
  StreamSubscription<GrabberState>? _subscription;

  /// Start grabbing for the given accounts.
  Future<void> start(List<String> accountIds) async {
    await _engine.start(accountIds);
  }

  /// Stop the current grabbing task.
  void stop() => _engine.stop();

  /// Pause the current grabbing task.
  void pause() => _engine.pause();

  /// Reset to idle state.
  void reset() => _engine.reset();

  @override
  void dispose() {
    _subscription?.cancel();
    _engine.dispose();
    super.dispose();
  }
}
