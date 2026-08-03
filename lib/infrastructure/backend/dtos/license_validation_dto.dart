/// License validation response DTO.
library;

import 'package:nkgrabber/infrastructure/backend/dtos/license_activation_dto.dart';

class LicenseValidationDto {
  const LicenseValidationDto({
    required this.license,
    this.deviceToken,
  });

  factory LicenseValidationDto.fromJson(Map<String, dynamic> json) {
    return LicenseValidationDto(
      license: LicenseInfoDto.fromJson(
        json['license'] as Map<String, dynamic>,
      ),
      deviceToken: json['deviceToken'] as String?,
    );
  }

  /// Updated license info.
  final LicenseInfoDto license;

  /// Rotated device token (if server issued a new one).
  final String? deviceToken;
}
