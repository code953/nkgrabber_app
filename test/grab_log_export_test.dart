import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
// file_picker 11 exposes its platform test seam only through this library.
// ignore: implementation_imports
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nkgrabber/core/security/secure_storage.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_bus.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_entry.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/providers.dart';
import 'package:nkgrabber/main.dart' show NKGrabberApp;

const _saverChannel = MethodChannel('file_saver');
const _expectedText =
    '21:33:25.429 [测试账号] 测试回复：保留原文\n'
    '    password=export-test-only; JSESSIONID=export-test-cookie\n'
    '    第二行：𠮷\n';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FilePickerPlatform originalPicker;
  late _RecordingFilePicker picker;
  late List<MethodCall> saverCalls;

  setUp(() {
    originalPicker = FilePickerPlatform.instance;
    picker = _RecordingFilePicker();
    FilePickerPlatform.instance = picker;
    saverCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_saverChannel, (call) async {
          saverCalls.add(call);
          // Never load the crashing native plugin in a test. Assert that the
          // real button avoids its channel, not just that a helper can save.
          throw PlatformException(code: 'UNSAFE_WINDOWS_EXPORT');
        });
    grabLogBus
      ..reset()
      ..add(
        GrabLogEntry(
          at: DateTime(2026, 8, 28, 21, 33, 25, 429),
          kind: GrabLogKind.response,
          accountLabel: '测试账号',
          message: '测试回复：保留原文',
          // Synthetic credentials pin the deliberately unsanitized display
          // export; these must never be sent through the file logger.
          detail:
              'password=export-test-only; JSESSIONID=export-test-cookie\n第二行：𠮷',
        ),
      );
  });

  tearDown(() {
    FilePickerPlatform.instance = originalPicker;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_saverChannel, null);
    grabLogBus.reset();
  });

  testWidgets(
    'Windows file export bypasses file_saver and preserves the full UTF-8 log',
    (tester) async {
      await _pumpApp(tester);
      await _chooseExport(tester, '保存为文件');

      expect(saverCalls, isEmpty);
      expect(picker.calls, 1);
      expect(picker.dialogTitle, '保存抢课日志');
      expect(picker.fileName, matches(r'^nkgrabber-log-\d{8}-\d{6}\.txt$'));
      expect(picker.type, FileType.custom);
      expect(picker.allowedExtensions, ['txt']);
      expect(picker.lockParentWindow, isTrue);
      expect(picker.bytes, orderedEquals(utf8.encode(_expectedText)));
      expect(find.text('已保存 1 条日志'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Windows save cancellation is not reported as success',
    (tester) async {
      picker.onSave = () async => null;
      await _pumpApp(tester);
      await _chooseExport(tester, '保存为文件');

      expect(picker.calls, 1);
      expect(saverCalls, isEmpty);
      expect(find.text('已取消导出'), findsOneWidget);
      expect(find.textContaining('已保存'), findsNothing);
      expect(find.textContaining('导出失败'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Windows write failures are shown rather than reported as success',
    (tester) async {
      picker.onSave = () async => throw const FileSystemException('测试写入失败');
      await _pumpApp(tester);
      await _chooseExport(tester, '保存为文件');

      expect(picker.calls, 1);
      expect(saverCalls, isEmpty);
      expect(find.textContaining('导出失败：'), findsOneWidget);
      expect(find.textContaining('测试写入失败'), findsOneWidget);
      expect(find.textContaining('已保存'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Windows export waits for the picker write before claiming success',
    (tester) async {
      final completion = Completer<String?>();
      picker.onSave = () => completion.future;
      await _pumpApp(tester);
      await _chooseExport(tester, '保存为文件');

      expect(picker.calls, 1);
      expect(saverCalls, isEmpty);
      expect(find.textContaining('已保存'), findsNothing);
      completion.complete(r'C:\测试目录\export.txt');
      await tester.pumpAndSettle();
      expect(find.text('已保存 1 条日志'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Windows export may complete after the app is disposed',
    (tester) async {
      final completion = Completer<String?>();
      picker.onSave = () => completion.future;
      await _pumpApp(tester);
      await _chooseExport(tester, '保存为文件');
      expect(picker.calls, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      completion.complete(r'C:\测试目录\export.txt');
      await tester.pumpAndSettle();

      expect(saverCalls, isEmpty);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Windows clipboard export remains unsanitized and uses no file plugin',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _pumpApp(tester);
      await _chooseExport(tester, '复制到剪贴板');

      expect(copied, _expectedText);
      expect(picker.calls, 0);
      expect(saverCalls, isEmpty);
      expect(find.text('已复制 1 条日志'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'non-Windows export retains the existing FileSaver path',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _saverChannel,
        (call) async {
          saverCalls.add(call);
          // FileSaver uses dart:io's host OS, not Flutter's target override.
          return Platform.isWindows
              ? Int64List.fromList(r'C:\test\export.txt'.codeUnits)
              : '/test/export.txt';
        },
      );
      await _pumpApp(tester);
      await _chooseExport(tester, '保存为文件');

      expect(picker.calls, 0);
      expect(saverCalls, hasLength(1));
      expect(saverCalls.single.method, 'saveAs');
      final arguments = saverCalls.single.arguments as Map;
      expect(arguments['name'], matches(r'^nkgrabber-log-\d{8}-\d{6}\.txt$'));
      expect(arguments['fileExtension'], '.txt');
      expect(arguments['bytes'], orderedEquals(utf8.encode(_expectedText)));
      expect(arguments['mimeType'], 'text/plain');
      expect(find.text('已保存 1 条日志'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
    // FileSaver itself has no Linux saveAs implementation. Keep its existing
    // platform behavior; the Windows regression cases above run on Linux too.
    skip: Platform.isLinux,
  );
}

Future<void> _pumpApp(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
      ],
      child: const NKGrabberApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('抢课').first);
  await tester.pumpAndSettle();
}

Future<void> _chooseExport(WidgetTester tester, String label) async {
  await tester.tap(find.byIcon(Icons.ios_share));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

class _RecordingFilePicker extends FilePickerPlatform {
  int calls = 0;
  String? dialogTitle;
  String? fileName;
  FileType? type;
  List<String>? allowedExtensions;
  Uint8List? bytes;
  bool? lockParentWindow;
  Future<String?> Function() onSave = () async => r'C:\测试目录\export.txt';

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) {
    calls++;
    this.dialogTitle = dialogTitle;
    this.fileName = fileName;
    this.type = type;
    this.allowedExtensions = allowedExtensions;
    this.bytes = bytes;
    this.lockParentWindow = lockParentWindow;
    return onSave();
  }
}

class _FakeSecureStorage implements SecureStorage {
  final _values = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async =>
      _values[key] = value;

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> delete({required String key}) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();

  @override
  Future<bool> isAvailable() async => true;
}
