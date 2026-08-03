/// App configuration response DTO.
library;

class AppConfigDto {
  const AppConfigDto({
    required this.maintenance,
    required this.minimumSupportedVersion,
    this.maintenanceMessage,
    this.supportUrl,
  });

  factory AppConfigDto.fromJson(Map<String, dynamic> json) {
    return AppConfigDto(
      maintenance: json['maintenance'] as bool? ?? false,
      maintenanceMessage: json['maintenanceMessage'] as String?,
      minimumSupportedVersion:
          json['minimumSupportedVersion'] as String? ?? '0.0.0',
      supportUrl: json['supportUrl'] as String?,
    );
  }

  final bool maintenance;
  final String? maintenanceMessage;
  final String minimumSupportedVersion;
  final String? supportUrl;
}
