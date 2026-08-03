/// License state notifier.
///
/// Manages the license activation, validation, and deactivation lifecycle.
/// Exposes reactive state for the UI layer.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/core/security/secure_storage.dart';
import 'package:nkgrabber/core/security/secure_storage_keys.dart';
import 'package:nkgrabber/infrastructure/backend/backend_repository.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/license_activation_dto.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/daos/license_dao.dart';

/// License state exposed to the UI.
class LicenseState {
  const LicenseState({
    this.snapshot,
    this.isLoading = false,
    this.error,
  });

  final LicenseSnapshotEntry? snapshot;
  final bool isLoading;
  final String? error;

  LicenseState copyWith({
    LicenseSnapshotEntry? snapshot,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSnapshot = false,
  }) {
    return LicenseState(
      snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier managing license state.
class LicenseNotifier extends StateNotifier<LicenseState> {
  LicenseNotifier({
    required BackendRepository backendRepository,
    required SecureStorage secureStorage,
    required LicenseDao licenseDao,
  })  : _backendRepo = backendRepository,
        _storage = secureStorage,
        _licenseDao = licenseDao,
        super(const LicenseState());

  final BackendRepository _backendRepo;
  final SecureStorage _storage;
  final LicenseDao _licenseDao;
  final _logger = AppLogger('LicenseNotifier');

  /// Load cached license snapshot from database.
  Future<void> loadCached() async {
    final snapshot = await _licenseDao.get();
    state = state.copyWith(snapshot: snapshot);
  }

  /// Activate a license code.
  Future<bool> activate({
    required String licenseCode,
    required String installId,
    required String deviceName,
    required String platform,
    required String appVersion,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _backendRepo.activateLicense(
        licenseCode: licenseCode,
        installId: installId,
        deviceName: deviceName,
        platform: platform,
        appVersion: appVersion,
      );

      // Store device token in secure storage.
      await _storage.write(
        key: SecureStorageKeys.deviceToken,
        value: result.deviceToken,
      );

      // Save license snapshot to database.
      await _saveLicenseSnapshot(result.license);

      final snapshot = await _licenseDao.get();
      state = state.copyWith(snapshot: snapshot, isLoading: false);
      _logger.info('License activated successfully');
      return true;
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      _logger.warn('License activation failed', e);
      return false;
    }
  }

  /// Validate the current license online.
  Future<bool> validate({
    required String installId,
    required String appVersion,
  }) async {
    try {
      final result = await _backendRepo.validateLicense(
        installId: installId,
        appVersion: appVersion,
      );

      // Handle rotated token.
      if (result.deviceToken != null) {
        await _storage.write(
          key: SecureStorageKeys.deviceToken,
          value: result.deviceToken!,
        );
      }

      // Update license snapshot.
      await _saveLicenseSnapshot(result.license);
      final snapshot = await _licenseDao.get();
      state = state.copyWith(snapshot: snapshot);
      return true;
    } on Exception catch (e) {
      _logger.warn('License validation failed', e);
      return false;
    }
  }

  /// Deactivate (unbind) the current device.
  Future<bool> deactivate({required String installId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _backendRepo.deactivateLicense(installId: installId);

      // Clear local data.
      await _storage.delete(key: SecureStorageKeys.deviceToken);
      await _licenseDao.clear();

      state = const LicenseState();
      _logger.info('License deactivated (device unbound)');
      return true;
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      _logger.warn('License deactivation failed', e);
      return false;
    }
  }

  Future<void> _saveLicenseSnapshot(LicenseInfoDto info) async {
    await _licenseDao.upsert(
      LicenseSnapshotsCompanion.insert(
        planId: info.plan.id,
        planName: info.plan.name,
        maxAccounts: info.plan.maxAccounts,
        minRequestIntervalMs: info.plan.minRequestIntervalMs,
        maxConcurrentAccounts: info.plan.maxConcurrentAccounts,
        licenseDurationDays: info.plan.licenseDurationDays,
        expiresAt: info.expiresAt,
        validatedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }
}
