/// Latest release response DTO.
library;

class LatestReleaseDto {
  const LatestReleaseDto({
    required this.version,
    required this.mandatory,
    required this.publishedAt,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.sha256,
    required this.signature,
  });

  factory LatestReleaseDto.fromJson(Map<String, dynamic> json) {
    return LatestReleaseDto(
      version: json['version'] as String,
      mandatory: json['mandatory'] as bool? ?? false,
      publishedAt: json['publishedAt'] as String,
      releaseNotes: json['releaseNotes'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String,
      sha256: json['sha256'] as String,
      signature: json['signature'] as String,
    );
  }

  final String version;
  final bool mandatory;
  final String publishedAt;
  final String releaseNotes;
  final String downloadUrl;
  final String sha256;
  final String signature;
}
