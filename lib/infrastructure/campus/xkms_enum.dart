/// Selection-mode (`xkms`) handling.
///
/// The value is passed verbatim to the campus system's `saveStudentXkJs`
/// endpoint. The school's own pages never interpret it — they just carry it
/// through — so this client only needs to know which values are *submittable*
/// and how to label the rest.
library;

/// Selection modes this client can submit against.
enum XkmsMode {
  /// The mode the live deployment reports for an ordinary elective batch.
  ///
  /// This was previously classified as "the selection window has closed", on
  /// the reasoning that the only batch visible at the time carried it and was
  /// over. A packet capture of a real submission during an open batch
  /// (2026-03-14) settles it: `xkms=0` was sent verbatim and the server
  /// answered `code:"0" / 提交成功！`. The batch state is carried by `zt` /
  /// `jssj`, not by this field.
  ///
  /// The label is deliberately generic — the capture proves the value is
  /// submittable, not what the school calls it.
  elective('0', '选课'),

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
  /// Returns null only for values never seen on the wire. Use [Xkms.statusOf]
  /// when you want the classification rather than the mode.
  static XkmsMode? fromCode(String code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    return null;
  }
}

/// What a given `xkms` value means for the user.
enum XkmsStatus {
  /// Submittable: one of 0 / 1 / 2 / 3.
  submittable,

  /// A value this client has never seen.
  unknown,
}

/// Classification of raw `xkms` values.
///
/// Every value observed on the wire so far is submittable, `"0"` included —
/// see [XkmsMode.elective] for the capture that settled that. A value outside
/// the set is the one case worth blocking on, because submitting an `xkms` the
/// school never sent us is a guess about a protocol we only know by
/// measurement.
class Xkms {
  const Xkms._();

  /// Classify a raw campus `xkms` value.
  static XkmsStatus statusOf(String code) => XkmsMode.fromCode(code) != null
      ? XkmsStatus.submittable
      : XkmsStatus.unknown;

  /// A label for any raw value, submittable or not.
  static String labelFor(String code) =>
      XkmsMode.fromCode(code)?.label ?? '未知模式';

  /// Why a batch cannot be submitted, or null when it can.
  static String? blockedReason(String code) => switch (statusOf(code)) {
    XkmsStatus.submittable => null,
    XkmsStatus.unknown => '无法识别的选课模式，请等待客户端升级',
  };
}
