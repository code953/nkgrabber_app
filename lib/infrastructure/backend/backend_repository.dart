/// Backend repository interface.
///
/// Defines all operations against the NKgrabber backend API.
library;

import 'package:nkgrabber/infrastructure/backend/dtos/app_config_dto.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/license_activation_dto.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/license_validation_dto.dart';

/// Abstract interface for backend API operations.
abstract class BackendRepository {
  /// Activate a license code on this device.
  Future<LicenseActivationDto> activateLicense({
    required String licenseCode,
    required String installId,
    required String deviceName,
    required String platform,
    required String appVersion,
  });

  /// Validate the current device token.
  Future<LicenseValidationDto> validateLicense({
    required String installId,
    required String appVersion,
  });

  /// Deactivate (unbind) the current device.
  Future<void> deactivateLicense({required String installId});

  /// Fetch app configuration and maintenance status.
  Future<AppConfigDto> fetchConfig({
    required String platform,
    required String appVersion,
  });
}
