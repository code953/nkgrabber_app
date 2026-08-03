/// Crash report DTO.
///
/// Contains only sanitized, non-identifying information.
/// Never includes passwords, cookies, tokens, student data, or course data.
library;

class CrashReportDto {
  const CrashReportDto({
    required this.installIdHash,
    required this.appVersion,
    required this.platform,
    required this.arch,
    required this.locale,
    required this.crashType,
    required this.sanitizedStackTrace,
    required this.timestamp,
    this.contextTags = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'installIdHash': installIdHash,
      'appVersion': appVersion,
      'platform': platform,
      'arch': arch,
      'locale': locale,
      'crashType': crashType,
      'stackTrace': sanitizedStackTrace,
      'timestamp': timestamp,
      'contextTags': contextTags,
    };
  }

  /// SHA-256 hash of installId (not the raw value).
  final String installIdHash;
  final String appVersion;
  final String platform;
  final String arch;
  final String locale;
  final String crashType;
  final String sanitizedStackTrace;
  final String timestamp;
  final Map<String, String> contextTags;
}
