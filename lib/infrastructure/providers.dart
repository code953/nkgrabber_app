/// Riverpod providers for database and secure storage.
///
/// These are keepAlive providers since the database and storage
/// instances should persist for the entire app lifecycle.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/core/security/secure_storage.dart';
import 'package:nkgrabber/core/security/secure_storage_impl.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/connection/native.dart';

/// Provides the singleton [AppDatabase] instance.
///
/// keepAlive ensures the database connection persists across the app lifecycle.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(createNativeDatabase());
  ref.onDispose(db.close);
  return db;
});

/// Provides the singleton [SecureStorage] instance.
///
/// keepAlive ensures the storage adapter persists across the app lifecycle.
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorageImpl();
});
