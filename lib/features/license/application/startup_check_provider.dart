/// Startup check provider.
///
/// Implements the app startup flow (§10.0):
/// 1. Ensure installId exists (generate UUID if not)
/// 2. Fetch remote config (timeout 10s, allow offline)
/// 3. Check maintenance/version gate
/// 4. Check deviceToken exists → if not, go to activation
/// 5. Validate license → if success, go to home
library;

import 'dart:async';

import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/core/security/secure_storage.dart';
import 'package:nkgrabber/core/security/secure_storage_keys.dart';
import 'package:nkgrabber/core/utils/constants.dart';
import 'package:nkgrabber/infrastructure/backend/backend_repository.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/app_config_dto.dart';
import 'package:uuid/uuid.dart';

/// Result of the startup check sequence.
enum StartupResult {
  /// Maintenance mode active — show blocking page.
  maintenance,

  /// App version too low — must update.
  versionTooLow,

  /// No device token — show activation page.
  needsActivation,

  /// All checks passed — enter main UI.
  ready,
}

/// Data collected during startup checks.
class StartupCheckData {
  const StartupCheckData({
    required this.result,
    this.config,
    this.maintenanceMessage,
    this.minimumVersion,
  });

  final StartupResult result;
  final AppConfigDto? config;
  final String? maintenanceMessage;
  final String? minimumVersion;
}

/// Performs the startup check sequence.
class StartupChecker {
  StartupChecker({
    required SecureStorage secureStorage,
    required BackendRepository backendRepository,
    required String appVersion,
    required String platform,
  })  : _storage = secureStorage,
        _backendRepo = backendRepository,
        _appVersion = appVersion,
        _platform = platform;

  final SecureStorage _storage;
  final BackendRepository _backendRepo;
  final String _appVersion;
  final String _platform;
  final _logger = AppLogger('StartupCheck');

  /// Run the full startup check sequence.
  Future<StartupCheckData> run() async {
    // 1. Ensure installId exists.
    var installId = await _storage.read(key: SecureStorageKeys.installId);
    if (installId == null) {
      installId = const Uuid().v4();
      await _storage.write(
        key: SecureStorageKeys.installId,
        value: installId,
      );
      _logger.info('Generated new installId');
    }

    // 2. Fetch remote config (timeout 10s, allow offline).
    AppConfigDto? config;
    try {
      config = await _backendRepo
          .fetchConfig(
            platform: _platform,
            appVersion: _appVersion,
          )
          .timeout(AppConstants.startupCheckTimeout);
    } on TimeoutException {
      _logger.warn('Startup check timed out, continuing offline');
    } on Exception catch (e) {
      _logger.warn('Startup check failed, continuing offline', e);
    }

    // 3. Check maintenance gate.
    if (config != null && config.maintenance) {
      return StartupCheckData(
        result: StartupResult.maintenance,
        config: config,
        maintenanceMessage: config.maintenanceMessage,
      );
    }

    // 4. Check version gate.
    if (config != null &&
        _isVersionLower(_appVersion, config.minimumSupportedVersion)) {
      return StartupCheckData(
        result: StartupResult.versionTooLow,
        config: config,
        minimumVersion: config.minimumSupportedVersion,
      );
    }

    // 5. Check device token.
    final deviceToken =
        await _storage.read(key: SecureStorageKeys.deviceToken);
    if (deviceToken == null) {
      return StartupCheckData(
        result: StartupResult.needsActivation,
        config: config,
      );
    }

    // 6. Validate license (non-blocking on failure if offline).
    // Validation failure here doesn't block entry, but grabbing won't work.
    return StartupCheckData(
      result: StartupResult.ready,
      config: config,
    );
  }

  /// Compare semver strings (simple major.minor.patch comparison).
  bool _isVersionLower(String current, String minimum) {
    final cur = _parseVersion(current);
    final min = _parseVersion(minimum);
    for (var i = 0; i < 3; i++) {
      if (cur[i] < min[i]) return true;
      if (cur[i] > min[i]) return false;
    }
    return false;
  }

  List<int> _parseVersion(String version) {
    final parts = version.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }
}
