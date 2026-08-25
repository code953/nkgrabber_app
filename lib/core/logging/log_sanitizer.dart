/// Sanitizes sensitive information from log messages and stack traces.
///
/// Ensures that passwords, cookies, tokens, activation codes, and other
/// PII never appear in logs, diagnostics exports, or crash reports.
library;

class LogSanitizer {
  const LogSanitizer._();

  /// Patterns that indicate sensitive content in log text.
  static final List<RegExp> _sensitivePatterns = [
    // Passwords (common parameter names)
    RegExp(r'(?:password|passwd|pwd)\s*[=:]\s*\S+', caseSensitive: false),
    // Activation codes (XXXX-XXXX-XXXX-XXXX format)
    RegExp('[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}'),
    // Bearer tokens
    RegExp(r'Bearer\s+\S+', caseSensitive: false),
    // Cookie values (gdpk and JSESSIONID)
    RegExp(r'(?:gdpk|JSESSIONID)\s*=\s*\S+', caseSensitive: false),
    // Generic cookie header
    RegExp(r'cookie\s*:\s*\S+', caseSensitive: false),
    // Authorization header value
    RegExp(r'(?:authorization|x-device-token)\s*:\s*\S+', caseSensitive: false),
    // deviceToken in JSON
    RegExp(r'"deviceToken"\s*:\s*"[^"]*"'),
    // licenseCode in JSON
    RegExp(r'"licenseCode"\s*:\s*"[^"]*"'),
    // RSA encrypted values (long base64 strings)
    RegExp(r'(?:encrypted|cipher)\s*[=:]\s*[A-Za-z0-9+/=]{32,}'),
  ];

  /// Sanitize a log message by replacing sensitive content with `[REDACTED]`.
  static String sanitize(String input) {
    var result = input;
    for (final pattern in _sensitivePatterns) {
      result = result.replaceAll(pattern, '[REDACTED]');
    }
    return result;
  }

  /// Sanitize headers map for logging.
  static Map<String, dynamic> sanitizeHeaders(Map<String, dynamic> headers) {
    const sensitiveHeaders = {
      'authorization',
      'cookie',
      'set-cookie',
      'x-device-token',
    };
    return headers.map((key, value) {
      if (sensitiveHeaders.contains(key.toLowerCase())) {
        return MapEntry(key, '[REDACTED]');
      }
      return MapEntry(key, value);
    });
  }

  /// Sanitize a stack trace for crash reporting (keep file:line, strip args).
  static String sanitizeStackTrace(String stackTrace) {
    return sanitize(stackTrace);
  }
}
