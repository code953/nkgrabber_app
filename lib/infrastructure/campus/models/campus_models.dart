/// Data models for campus system interactions.
///
/// These models represent the data structures returned by the
/// campus system adapter. They are independent of database entities.
library;

/// Result of a successful login.
class LoginResult {
  const LoginResult({
    required this.gdpk,
    required this.studentNo,
    required this.studentName,
  });

  /// The gdpk session cookie.
  final String gdpk;

  /// Student number extracted from the session.
  final String studentNo;

  /// Student name for display.
  final String studentName;
}

/// Student identity from a validated session.
class StudentProfile {
  const StudentProfile({required this.studentNo, required this.studentName});

  final String studentNo;
  final String studentName;
}

/// A selection batch (选课批次).
class SelectionBatch {
  const SelectionBatch({
    required this.xkid,
    required this.xkms,
    required this.batchName,
    required this.zdxk,
    required this.kssj,
    required this.jssj,
  });

  /// Batch ID.
  final String xkid;

  /// Selection mode code, passed back verbatim on submit.
  ///
  /// Observed values include `"0"` (选课已结束) as well as the submittable
  /// `"1"`/`"2"`/`"3"`. See `XkmsMode`.
  final String xkms;

  /// Human-readable batch name (`mc` upstream).
  final String batchName;

  /// Maximum courses per submission request.
  final int zdxk;

  /// Batch start time, `yyyy-MM-dd HH:mm:ss` in the school's local time.
  ///
  /// Not ISO-8601 — the upstream field is a plain local timestamp with a space
  /// separator, so `DateTime.parse` accepts it but treats it as local.
  final String kssj;

  /// Batch end time, same format as [kssj].
  final String jssj;
}

/// A course available for selection.
class Course {
  const Course({
    required this.kmh,
    required this.courseName,
    this.xbkid,
    this.teacherName,
    this.capacity,
    this.selected,
    this.remaining,
    this.credit,
  });

  /// The id submitted to claim this course.
  ///
  /// Upstream rows carry no `kmh` field: the school's own page submits the
  /// row's `xbkid` (`data-kmh="${item.xbkid}"`), and an already-selected
  /// record's `kmh` matches that `xbkid` exactly. Kept as a separate field
  /// from [xbkid] so that a future upstream split needs no data migration.
  final String kmh;

  /// Display course name (`xbkmc` upstream).
  final String courseName;

  /// Display group ID.
  final String? xbkid;

  /// Teacher name for display (`jsxm` upstream).
  final String? teacherName;

  /// Total enrollment capacity (`rsyq` upstream).
  final int? capacity;

  /// Already selected count (`yxrs` upstream).
  final int? selected;

  /// Remaining spots (`syme` upstream).
  final int? remaining;

  /// Course credit (`xbkxf` upstream), display-only.
  final String? credit;
}

/// A record of an already-selected course (for idempotency check).
class SelectionRecord {
  const SelectionRecord({required this.kmh, required this.courseName});

  /// Course number of the already-selected course.
  final String kmh;

  /// Course name for display.
  final String courseName;
}

/// Command to submit a course selection.
class SubmitSelection {
  const SubmitSelection({
    required this.xkid,
    required this.xkms,
    required this.kmhList,
  });

  /// Batch ID.
  final String xkid;

  /// Selection mode code.
  final String xkms;

  /// List of course numbers to submit.
  final List<String> kmhList;
}

/// Result of a submit operation.
class SubmitResult {
  const SubmitResult({
    required this.success,
    this.message,
    this.failedKmhList = const [],
    this.rawData,
  });

  /// Whether the submission succeeded.
  final bool success;

  /// Server message (success or error description).
  final String? message;

  /// Course numbers that failed (partial success scenario).
  final List<String> failedKmhList;

  /// The reply's `result.data`, carried verbatim for display.
  ///
  /// Deliberately not part of the verdict: an accepted two-course submission
  /// returned `"1"`, so whatever it counts, it is not granted courses — and
  /// one sample is not enough to gate a success on.
  final String? rawData;
}

/// Result of a withdraw operation.
class WithdrawResult {
  const WithdrawResult({required this.success, this.message});

  final bool success;
  final String? message;
}
