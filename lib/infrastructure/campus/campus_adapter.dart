/// Campus system adapter interface.
///
/// Defines all operations against the university campus system.
/// Each method operates within a specific account's isolated session.
library;

import 'package:nkgrabber/infrastructure/campus/models/campus_models.dart';

/// Abstract interface for campus system operations (§7).
abstract class CampusAdapter {
  /// Login with student number and password (RSA encrypted).
  Future<LoginResult> loginWithPassword(String account, String password);

  /// Validate an existing gdpk cookie and fetch student profile.
  Future<StudentProfile> validateCookie(String gdpk);

  /// List available selection batches.
  Future<List<SelectionBatch>> listBatches();

  /// List courses available in a specific batch.
  Future<List<Course>> listCourses(String xkid);

  /// List already-selected records for idempotency check.
  Future<List<SelectionRecord>> listSelections(String xkid);

  /// Submit course selection.
  Future<SubmitResult> submit(SubmitSelection command);

  /// Withdraw from a batch.
  Future<WithdrawResult> withdraw(String xkid);

  /// Get the current campus clock offset in milliseconds.
  int get campusClockOffsetMs;
}
