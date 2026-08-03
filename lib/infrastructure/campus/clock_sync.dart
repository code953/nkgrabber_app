/// Campus clock synchronization helper.
///
/// Compares the campus system's Date header offset with the backend
/// server's clock offset. If they diverge by more than 60s, the
/// scheduler should warn and pause.
library;

import 'package:nkgrabber/core/utils/constants.dart';

/// Clock sync status between campus and backend servers.
class ClockSyncStatus {
  const ClockSyncStatus({
    required this.campusOffsetMs,
    required this.serverOffsetMs,
  });

  /// Offset: campus clock - local clock (ms).
  final int campusOffsetMs;

  /// Offset: backend clock - local clock (ms).
  final int serverOffsetMs;

  /// Drift between campus and backend clocks (ms).
  int get driftMs => (campusOffsetMs - serverOffsetMs).abs();

  /// Whether the drift exceeds the safety threshold (60s).
  bool get isDriftExcessive =>
      driftMs > AppConstants.maxCampusServerDriftSeconds * 1000;

  /// Whether the backend clock offset exceeds the hard limit (10 min).
  bool get isServerOffsetExcessive =>
      serverOffsetMs.abs() >
      AppConstants.maxServerClockOffsetMinutes * 60 * 1000;

  /// Estimated "now" on the campus server.
  DateTime get campusNow =>
      DateTime.now().toUtc().add(Duration(milliseconds: campusOffsetMs));
}
