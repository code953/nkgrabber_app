/// License activation response DTO.
library;

class LicenseActivationDto {
  const LicenseActivationDto({
    required this.deviceToken,
    required this.license,
  });

  factory LicenseActivationDto.fromJson(Map<String, dynamic> json) {
    return LicenseActivationDto(
      deviceToken: json['deviceToken'] as String,
      license: LicenseInfoDto.fromJson(
        json['license'] as Map<String, dynamic>,
      ),
    );
  }

  final String deviceToken;
  final LicenseInfoDto license;
}

class LicenseInfoDto {
  const LicenseInfoDto({
    required this.status,
    required this.activatedAt,
    required this.expiresAt,
    required this.plan,
  });

  factory LicenseInfoDto.fromJson(Map<String, dynamic> json) {
    return LicenseInfoDto(
      status: json['status'] as String,
      activatedAt: json['activatedAt'] as String,
      expiresAt: json['expiresAt'] as String,
      plan: PlanDto.fromJson(json['plan'] as Map<String, dynamic>),
    );
  }

  final String status;
  final String activatedAt;
  final String expiresAt;
  final PlanDto plan;
}

class PlanDto {
  const PlanDto({
    required this.id,
    required this.name,
    required this.maxAccounts,
    required this.minRequestIntervalMs,
    required this.maxConcurrentAccounts,
    required this.licenseDurationDays,
    required this.maxDevices,
    required this.unbindCooldownHours,
  });

  factory PlanDto.fromJson(Map<String, dynamic> json) {
    return PlanDto(
      id: json['id'] as String,
      name: json['name'] as String,
      maxAccounts: json['maxAccounts'] as int,
      minRequestIntervalMs: json['minRequestIntervalMs'] as int,
      maxConcurrentAccounts: json['maxConcurrentAccounts'] as int,
      licenseDurationDays: json['licenseDurationDays'] as int,
      maxDevices: (json['maxDevices'] as int?) ?? 1,
      unbindCooldownHours: (json['unbindCooldownHours'] as int?) ?? 24,
    );
  }

  final String id;
  final String name;
  final int maxAccounts;
  final int minRequestIntervalMs;
  final int maxConcurrentAccounts;
  final int licenseDurationDays;
  final int maxDevices;
  final int unbindCooldownHours;
}
