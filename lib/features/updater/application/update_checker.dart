/// Update checker.
///
/// Checks for updates on app startup (once) and via manual button.
/// Handles mandatory update blocking.
library;

import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/infrastructure/backend/backend_repository.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/latest_release_dto.dart';

class UpdateChecker {
  UpdateChecker({
    required BackendRepository backendRepository,
    required String currentVersion,
    required String platform,
    required String arch,
    required String channel,
  })  : _backendRepo = backendRepository,
        _currentVersion = currentVersion,
        _platform = platform,
        _arch = arch,
        _channel = channel;

  final BackendRepository _backendRepo;
  final String _currentVersion;
  final String _platform;
  final String _arch;
  final String _channel;
  final _logger = AppLogger('UpdateChecker');

  /// Check for available updates.
  ///
  /// Returns null if no update is available or if the check fails.
  Future<LatestReleaseDto?> check() async {
    try {
      final release = await _backendRepo.checkUpdate(
        platform: _platform,
        arch: _arch,
        currentVersion: _currentVersion,
        channel: _channel,
      );

      if (release != null) {
        _logger.info(
          'Update available: v${release.version} '
          '(mandatory: ${release.mandatory})',
        );
      }

      return release;
    } on Exception catch (e) {
      _logger.warn('Update check failed', e);
      return null;
    }
  }
}
