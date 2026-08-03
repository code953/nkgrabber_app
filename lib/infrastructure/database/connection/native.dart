/// Native database connection factory.
///
/// Creates an SQLite database using `NativeDatabase` in a background isolate
/// for optimal performance on mobile and desktop platforms.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// Creates a [QueryExecutor] for the app's SQLite database.
///
/// The database file is stored in the application support directory
/// and queries run in a background isolate.
QueryExecutor createNativeDatabase() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'nkgrabber.db'));

    // Work around a sqlite3 issue on older Android versions.
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    // Use the system's temp directory for sqlite3 temp files.
    final cacheBase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cacheBase;

    return NativeDatabase.createInBackground(file);
  });
}
