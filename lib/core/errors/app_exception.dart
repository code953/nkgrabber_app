/// Core error types for the NKgrabber application.
///
/// All exceptions thrown within the app should be mapped to one of these
/// sealed types so that presentation layer can handle them uniformly.
library;

sealed class AppException implements Exception {
  const AppException({required this.message, this.originalError});

  final String message;
  final Object? originalError;

  @override
  String toString() => 'AppException($message)';
}

// -- Network errors ----------------------------------------------------------

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    required this.type,
    super.originalError,
  });

  final NetworkExceptionType type;
}

enum NetworkExceptionType {
  timeout,
  noConnection,
  badRequest,
  conflict,
  rateLimited,
  serverError,
  cancelled,
  unknown,
}

// -- Campus (school system) errors -------------------------------------------

class CampusException extends AppException {
  const CampusException({
    required super.message,
    required this.type,
    super.originalError,
  });

  final CampusExceptionType type;
}

enum CampusExceptionType {
  loginFailed,
  sessionExpired,
  captchaRequired,
  riskControl,
  courseConflict,
  courseFull,
  batchClosed,
  limitReached,
  parameterError,
  networkError,
  unknownResponse,
}

// -- Storage errors ----------------------------------------------------------

class StorageException extends AppException {
  const StorageException({
    required super.message,
    required this.type,
    super.originalError,
  });

  final StorageExceptionType type;
}

enum StorageExceptionType {
  readFailed,
  writeFailed,
  deleteFailed,
  unavailable,
}

// -- Unknown -----------------------------------------------------------------

class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    super.originalError,
  });
}
