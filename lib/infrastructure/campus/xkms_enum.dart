/// Fixed enum for selection mode (xkms) values.
///
/// These values are passed verbatim to the campus system's
/// `saveStudentXkJs` endpoint. Any unrecognized value causes
/// the target to be marked as failed.
library;

/// Selection mode codes from the campus system.
enum XkmsMode {
  /// 抢选 (rush selection).
  rush('1', '抢选'),

  /// 正选 (regular selection).
  regular('2', '正选'),

  /// 补退选 (add/drop).
  addDrop('3', '补退选');

  const XkmsMode(this.code, this.label);

  /// The raw string value sent to the campus API.
  final String code;

  /// Human-readable label for UI display.
  final String label;

  /// Parse a campus xkms string value.
  /// Returns null for unrecognized values (client should mark target failed).
  static XkmsMode? fromCode(String code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    return null;
  }
}
