/// Diagnostics export helper.
///
/// Generates a sanitized diagnostics package containing recent
/// task logs and request entries for user review and bug reporting.
library;

import 'dart:convert';

import 'package:nkgrabber/core/logging/log_sanitizer.dart';
import 'package:nkgrabber/infrastructure/database/daos/grab_task_dao.dart';

/// Represents a diagnostics export package.
class DiagnosticsPackage {
  const DiagnosticsPackage({
    required this.tasks,
    required this.exportedAt,
  });

  final List<Map<String, dynamic>> tasks;
  final String exportedAt;

  /// Convert to a sanitized JSON string for export.
  String toSanitizedJson() {
    final data = {
      'exportedAt': exportedAt,
      'taskCount': tasks.length,
      'tasks': tasks,
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    return LogSanitizer.sanitize(jsonStr);
  }
}

class DiagnosticsExporter {
  DiagnosticsExporter({required GrabTaskDao grabTaskDao})
      : _grabTaskDao = grabTaskDao;

  final GrabTaskDao _grabTaskDao;

  /// Generate a diagnostics package from the last 3 tasks.
  Future<DiagnosticsPackage> export() async {
    final recentTasks = await _grabTaskDao.getRecent();

    final taskMaps = recentTasks.map((task) {
      return <String, dynamic>{
        'id': task.id,
        'accountId': _maskId(task.accountId),
        'status': task.status.name,
        'effectiveIntervalMs': task.effectiveIntervalMs,
        'startedAt': task.startedAt,
        'stoppedAt': task.stoppedAt,
        // Sanitize lastResultJson.
        'lastResult': task.lastResultJson != null
            ? LogSanitizer.sanitize(task.lastResultJson!)
            : null,
      };
    }).toList();

    return DiagnosticsPackage(
      tasks: taskMaps,
      exportedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Mask the middle of an ID for privacy.
  String _maskId(String id) {
    if (id.length <= 8) return '***';
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }
}
