/// Campus clock synchronization helper.
///
/// Tracks the offset between the campus system's `Date` header and the local
/// clock so the scheduler can compare against a batch's start time (`kssj`)
/// using the campus server's notion of "now" rather than the device's.
library;

/// Clock offset between the campus system and the local device.
class ClockSyncStatus {
  const ClockSyncStatus({required this.campusOffsetMs});

  /// Offset: campus clock - local clock (ms).
  final int campusOffsetMs;

  /// Estimated "now" on the campus server.
  DateTime get campusNow =>
      DateTime.now().toUtc().add(Duration(milliseconds: campusOffsetMs));
}
