/// Selection-mode (`xkms`) handling.
///
/// The value is passed verbatim to the campus system's `saveStudentXkJs`
/// endpoint. The school's own pages never interpret it — they just carry it
/// through — so this client only needs to know which values are *submittable*
/// and how to label the rest.
library;

/// Selection modes this client can submit against.
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

  /// Parse a submittable campus xkms value.
  ///
  /// Returns null for anything else — including the known-but-closed `"0"`.
  /// Use [Xkms.statusOf] when you need to tell "closed" apart from "unknown".
  static XkmsMode? fromCode(String code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    return null;
  }
}

/// What a given `xkms` value means for the user.
enum XkmsStatus {
  /// Submittable: one of 1 / 2 / 3.
  submittable,

  /// The batch's selection window has closed.
  closed,

  /// A value this client has never seen.
  unknown,
}

/// Classification of raw `xkms` values.
///
/// `"0"` is a real, documented state (选课已结束), not a parsing failure.
/// Reporting it as "unrecognised, please upgrade the client" — which is what a
/// bare [XkmsMode.fromCode] null-check does — sends the user chasing a client
/// bug when the batch is simply over.
class Xkms {
  const Xkms._();

  /// The value the campus system reports for a finished batch.
  static const closedCode = '0';

  /// Classify a raw campus `xkms` value.
  static XkmsStatus statusOf(String code) {
    if (XkmsMode.fromCode(code) != null) return XkmsStatus.submittable;
    if (code == closedCode) return XkmsStatus.closed;
    return XkmsStatus.unknown;
  }

  /// A label for any raw value, submittable or not.
  static String labelFor(String code) => switch (statusOf(code)) {
    XkmsStatus.submittable => XkmsMode.fromCode(code)!.label,
    XkmsStatus.closed => '选课已结束',
    XkmsStatus.unknown => '未知模式',
  };

  /// Why a batch cannot be submitted, or null when it can.
  static String? blockedReason(String code) => switch (statusOf(code)) {
    XkmsStatus.submittable => null,
    XkmsStatus.closed => '该批次选课已结束',
    XkmsStatus.unknown => '无法识别的选课模式，请等待客户端升级',
  };
}
