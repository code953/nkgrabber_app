/// Useful extension methods used throughout the app.
library;

extension StringExtensions on String {
  /// Mask all but the last [visible] characters.
  String maskExcept({int visible = 4}) {
    if (length <= visible) return this;
    return '${'*' * (length - visible)}${substring(length - visible)}';
  }

  /// Get the last N characters.
  String lastN(int n) {
    if (length <= n) return this;
    return substring(length - n);
  }
}

extension DateTimeExtensions on DateTime {
  /// Convert to ISO 8601 UTC string for storage.
  String toIso8601Utc() => toUtc().toIso8601String();

  /// Check if this DateTime is expired (before now).
  bool get isExpired => isBefore(DateTime.now().toUtc());
}

extension DurationExtensions on Duration {
  /// Format as "HH:mm:ss" for display.
  String toHms() {
    final h = inHours.toString().padLeft(2, '0');
    final m = (inMinutes % 60).toString().padLeft(2, '0');
    final s = (inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
