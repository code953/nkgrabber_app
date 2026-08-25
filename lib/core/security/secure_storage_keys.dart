/// Constants for secure storage keys.
///
/// Defines all keys used in platform secure storage. Credential keys are
/// scoped by account UUID to ensure strict isolation.
library;

class SecureStorageKeys {
  const SecureStorageKeys._();

  /// Password for a specific account (scoped by account ID).
  static String accountPassword(String accountId) =>
      'account_${accountId}_password';

  /// Serialized cookie jar for a specific account (scoped by account ID).
  static String accountCookies(String accountId) =>
      'account_${accountId}_cookies';
}
