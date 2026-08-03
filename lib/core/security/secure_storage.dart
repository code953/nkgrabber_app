/// Abstract interface for platform-secure credential storage.
///
/// Implementations use platform-specific mechanisms:
/// - Android: EncryptedSharedPreferences (Keystore-backed)
/// - iOS/macOS: Keychain
/// - Windows: DPAPI via Credential Manager
/// - Linux: Secret Service (libsecret)
library;

abstract interface class SecureStorage {
  /// Write a value to secure storage.
  Future<void> write({required String key, required String value});

  /// Read a value from secure storage. Returns null if not found.
  Future<String?> read({required String key});

  /// Delete a value from secure storage.
  Future<void> delete({required String key});

  /// Delete all values from secure storage.
  Future<void> deleteAll();

  /// Check if the secure storage is available on this platform.
  /// On Linux, returns false if no Secret Service provider is running.
  Future<bool> isAvailable();
}
