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
  const StudentProfile({
    required this.studentNo,
    required this.studentName,
  });

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

  /// Selection mode code ("1", "2", "3").
  final String xkms;

  /// Human-readable batch name.
  final String batchName;

  /// Maximum courses per submission request.
  final int zdxk;

  /// Batch start time (ISO 8601).
  final String kssj;

  /// Batch end time (ISO 8601).
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
  });

  /// Course number — the real submission ID.
  final String kmh;

  /// Display course name.
  final String courseName;

  /// Display group ID (may differ from kmh).
  final String? xbkid;

  /// Teacher name for display.
  final String? teacherName;

  /// Total enrollment capacity.
  final int? capacity;

  /// Already selected count.
  final int? selected;

  /// Remaining spots.
  final int? remaining;
}

/// A record of an already-selected course (for idempotency check).
class SelectionRecord {
  const SelectionRecord({
    required this.kmh,
    required this.courseName,
  });

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
  });

  /// Whether the submission succeeded.
  final bool success;

  /// Server message (success or error description).
  final String? message;

  /// Course numbers that failed (partial success scenario).
  final List<String> failedKmhList;
}

/// Result of a withdraw operation.
class WithdrawResult {
  const WithdrawResult({
    required this.success,
    this.message,
  });

  final bool success;
  final String? message;
}
