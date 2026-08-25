/// Platform-specific secure storage implementation using flutter_secure_storage.
library;

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nkgrabber/core/security/secure_storage.dart';

class SecureStorageImpl implements SecureStorage {
  SecureStorageImpl() : _storage = _createStorage();

  final FlutterSecureStorage _storage;

  static FlutterSecureStorage _createStorage() {
    // Platform-specific options for optimal security
    const androidOptions = AndroidOptions(encryptedSharedPreferences: true);
    const iOSOptions = IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    );
    const macOsOptions = MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
    );

    return const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iOSOptions,
      mOptions: macOsOptions,
    );
  }

  @override
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  @override
  Future<bool> isAvailable() async {
    if (Platform.isLinux) {
      // On Linux, flutter_secure_storage requires Secret Service (libsecret).
      // If unavailable, operations will throw. We attempt a test read.
      try {
        await _storage.read(key: '__availability_check__');
        return true;
      } catch (_) {
        return false;
      }
    }
    // Other platforms always have secure storage available.
    return true;
  }
}
