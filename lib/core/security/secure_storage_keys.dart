/// Constants for secure storage keys.
///
/// Defines all keys used in platform secure storage. Credential keys are
/// scoped by account UUID to ensure strict isolation.
library;

class SecureStorageKeys {
  const SecureStorageKeys._();

  /// The persistent install ID (UUID v4), generated on first run.
  static const installId = 'install_id';

  /// The device token obtained after license activation.
  static const deviceToken = 'license_device_token';

  /// Password for a specific account (scoped by account ID).
  static String accountPassword(String accountId) =>
      'account_${accountId}_password';

  /// Serialized cookie jar for a specific account (scoped by account ID).
  static String accountCookies(String accountId) =>
      'account_${accountId}_cookies';
}
