/// Plain-text rendering of the live grabber log, for export.
///
/// **This path is deliberately not sanitized, and writes nothing to the log
/// file.** It renders exactly what is already on screen, which by design may
/// carry the student's own name, their course names, and request bodies — the
/// user owns that data and is the one pressing 导出. `LogSanitizer` and
/// `AppLogger` govern the *log file*, and neither is involved here; the rules
/// for that file are unchanged. Do not "fix" this by adding sanitization: an
/// export that redacts the campus system's own reply is useless for the one
/// job it has, which is showing someone else what the school actually said.
library;

import 'package:nkgrabber/features/grabber/domain/grab_log_entry.dart';

/// Render [entries] as plain text, one entry per line plus an indented detail.
String formatGrabLog(List<GrabLogEntry> entries) {
  final buffer = StringBuffer();
  for (final entry in entries) {
    buffer
      ..write(entry.timestamp)
      ..write(' ');
    if (entry.accountLabel != null) {
      buffer
        ..write('[')
        ..write(entry.accountLabel)
        ..write('] ');
    }
    buffer.writeln(entry.message);
    final detail = entry.detail;
    if (detail != null && detail.isNotEmpty) {
      // Indent continuation lines too, so a multi-line body stays visually
      // attached to its entry rather than reading as further entries.
      for (final line in detail.split('\n')) {
        buffer
          ..write('    ')
          ..writeln(line);
      }
    }
  }
  return buffer.toString();
}

/// A filename stamped with [at], e.g. `nkgrabber-log-20260828-213325.txt`.
String grabLogFileName(DateTime at) {
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${at.year}${two(at.month)}${two(at.day)}';
  final time = '${two(at.hour)}${two(at.minute)}${two(at.second)}';
  return 'nkgrabber-log-$date-$time.txt';
}
