/// Retry classifier for campus submission errors.
///
/// Determines whether a failed submission should be retried or
/// the target should be marked as permanently failed (§9.4).
library;

import 'package:nkgrabber/core/errors/app_exception.dart';

/// Classification of a submission failure.
enum RetryDecision {
  /// Retry after the configured interval.
  retry,

  /// Mark this target as failed, skip to next.
  skipTarget,

  /// Stop the entire task (e.g., session expired).
  stopTask,
}

class RetryClassifier {
  const RetryClassifier._();

  /// Classify a campus exception for retry decisions.
  static RetryDecision classify(Object error) {
    if (error is CampusException) {
      switch (error.type) {
        case CampusExceptionType.sessionExpired:
          return RetryDecision.stopTask;
        case CampusExceptionType.captchaRequired:
          return RetryDecision.stopTask;
        case CampusExceptionType.riskControl:
          return RetryDecision.stopTask;
        case CampusExceptionType.courseConflict:
          return RetryDecision.skipTarget;
        case CampusExceptionType.courseFull:
          // Course full is retryable — spots may open up.
          return RetryDecision.retry;
        case CampusExceptionType.batchClosed:
          return RetryDecision.skipTarget;
        case CampusExceptionType.limitReached:
          return RetryDecision.skipTarget;
        case CampusExceptionType.parameterError:
          return RetryDecision.skipTarget;
        case CampusExceptionType.networkError:
          return RetryDecision.retry;
        case CampusExceptionType.unknownResponse:
          return RetryDecision.retry;
        case CampusExceptionType.loginFailed:
          return RetryDecision.stopTask;
      }
    }

    if (error is NetworkException) {
      switch (error.type) {
        case NetworkExceptionType.timeout:
        case NetworkExceptionType.noConnection:
          return RetryDecision.retry;
        case NetworkExceptionType.badRequest:
        case NetworkExceptionType.conflict:
        case NetworkExceptionType.rateLimited:
        case NetworkExceptionType.serverError:
        case NetworkExceptionType.cancelled:
        case NetworkExceptionType.unknown:
          return RetryDecision.stopTask;
      }
    }

    if (error is AuthException) {
      return RetryDecision.stopTask;
    }

    // Unknown errors — retry once, then skip.
    return RetryDecision.retry;
  }
}
