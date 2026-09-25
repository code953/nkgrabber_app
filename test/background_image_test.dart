import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/core/utils/image_palette.dart';
import 'package:nkgrabber/features/settings/application/background_controller.dart';
import 'package:nkgrabber/infrastructure/background/background_image_service.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/providers.dart';

/// A [width]×[height] PNG filled with [color].
Future<Uint8List> _solidPng(Color color, {int width = 16, int height = 16}) {
  return _png(width, height, (canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = color,
    );
  });
}

Future<Uint8List> _png(int w, int h, void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Hue distance on the colour wheel, 0–180.
double _hueDistance(Color a, Color b) {
  final d = (HSVColor.fromColor(a).hue - HSVColor.fromColor(b).hue).abs();
  return d > 180 ? 360 - d : d;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The binding installs an HttpOverrides that answers every request with 400
  // and never touches the socket. These tests talk to a real loopback server.
  HttpOverrides.global = null;

  late Uint8List redPng;
  late Uint8List bluePng;

  setUpAll(() async {
    redPng = await _solidPng(const Color(0xFFD32F2F));
    bluePng = await _solidPng(const Color(0xFF1565C0), width: 32);
  });

  group('image palette', () {
    test('the dominant colour becomes the first seed', () async {
      const red = 0xFFD32F2F;
      const blue = 0xFF1565C0;
      final pixels = [...List.filled(800, red), ...List.filled(200, blue)];
      final seeds = await seedColorsFromPixels(pixels);
      expect(seeds, isNotEmpty);
      expect(_hueDistance(seeds.first, const Color(red)), lessThan(20));
    });

    test(
      'a colourless picture yields no seed rather than a fallback',
      () async {
        // Score's own fallback is Google blue; persisting that for a black-and-
        // white photo would recolour the app with something not in the picture.
        final greys = [
          for (var v = 0; v < 256; v += 8)
            0xFF000000 | (v << 16) | (v << 8) | v,
        ];
        expect(await seedColorsFromPixels(greys), isEmpty);
      },
    );

    test('decodes an encoded image', () async {
      final seeds = await seedColorsFromImageBytes(bluePng);
      expect(_hueDistance(seeds.first, const Color(0xFF1565C0)), lessThan(20));
    });

    test('rejects bytes that are not an image', () async {
      await expectLater(
        seedColorsFromImageBytes(Uint8List.fromList(utf8.encode('<html>'))),
        throwsA(isA<ImageDecodeException>()),
      );
    });
  });

  group('response parsing', () {
    test('sniffs formats by magic number', () {
      expect(sniffImageExtension(redPng), 'png');
      expect(
        sniffImageExtension(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])),
        'jpg',
      );
      expect(
        sniffImageExtension(
          Uint8List.fromList([
            ...utf8.encode('RIFF'),
            0x24, 0x00, 0x00, 0x00, // chunk size — arbitrary, not checked
            ...utf8.encode('WEBP'),
          ]),
        ),
        'webp',
      );
      // RIFF alone is also WAV and AVI.
      expect(
        sniffImageExtension(
          Uint8List.fromList([
            ...utf8.encode('RIFF'),
            0x24, 0x00, 0x00, 0x00, // chunk size
            ...utf8.encode('WAVE'),
          ]),
        ),
        isNull,
      );
      expect(
        sniffImageExtension(Uint8List.fromList(utf8.encode('<!DOCTYPE'))),
        isNull,
      );
    });

    final base = Uri.parse('https://api.example.com/random');
    Uri? extract(String body) =>
        extractImageUrl(Uint8List.fromList(utf8.encode(body)), base: base);

    test('finds the image URL in a nested JSON reply', () {
      // The homepage link comes first in document order; the `url` key must
      // still win, or the importer would download an HTML page.
      expect(
        extract(
          '{"code":200,"homepage":"https://example.com/",'
          '"data":{"title":"x","url":"https://cdn.example.com/a.jpg"}}',
        ),
        Uri.parse('https://cdn.example.com/a.jpg'),
      );
      expect(
        extract('[{"imgurl":"//cdn.example.com/b.png"}]'),
        Uri.parse('https://cdn.example.com/b.png'),
      );
    });

    test('accepts a bare URL line, refuses HTML', () {
      expect(
        extract('https://cdn.example.com/c.webp\n'),
        Uri.parse('https://cdn.example.com/c.webp'),
      );
      expect(
        extract('<html><img src="https://cdn.example.com/banner.png"></html>'),
        isNull,
      );
    });

    test('parseImageUrl adds a scheme and rejects nonsense', () {
      expect(
        parseImageUrl(' example.com/pic ').toString(),
        'https://example.com/pic',
      );
      expect(
        () => parseImageUrl('ftp://example.com/a.png'),
        throwsA(isA<BackgroundImageException>()),
      );
    });
  });

  group('BackgroundImageService against a loopback image host', () {
    late HttpServer server;
    late Directory tempDir;
    late BackgroundImageService service;
    late String origin;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nkg_bg_');
      service = BackgroundImageService(baseDirectory: () async => tempDir);
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      origin = 'http://${server.address.host}:${server.port}';
      server.listen((req) async {
        final res = req.response;
        final ua = req.headers.value('user-agent') ?? '';
        switch (req.uri.path) {
          // A dual-end random-image API: same URL, orientation by UA, served
          // via redirect as nearly all of them do.
          case '/random':
            final mobile = ua.contains('Mobile');
            res
              ..statusCode = HttpStatus.found
              ..headers.set(
                'location',
                mobile ? '/portrait.png' : '/landscape.png',
              );
          case '/portrait.png':
            // Deliberately not image/*: hosts get this wrong constantly.
            res.headers.contentType = ContentType.binary;
            res.add(redPng);
          case '/landscape.png':
            res.headers.contentType = ContentType('image', 'png');
            res.add(bluePng);
          case '/api':
            res.headers.contentType = ContentType.json;
            res.write(
              jsonEncode({
                'code': 200,
                'homepage': '$origin/page.html',
                'data': {'url': '$origin/portrait.png'},
              }),
            );
          case '/text':
            res.headers.contentType = ContentType.text;
            res.write('$origin/landscape.png');
          case '/page.html':
            res.headers.contentType = ContentType.html;
            res.write('<html><body>403 hotlink</body></html>');
          case '/forbidden':
            res.statusCode = HttpStatus.forbidden;
          default:
            res.statusCode = HttpStatus.notFound;
        }
        await res.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
      await tempDir.delete(recursive: true);
    });

    Future<Uint8List> storedBytes(ImportedBackground imported) async =>
        (await service.resolve(imported.fileName))!.readAsBytes();

    test('asks a dual-end host for the picture matching the client', () async {
      final phone = await service.download(
        '$origin/random',
        client: ImageHostClient.mobile,
      );
      expect(await storedBytes(phone), redPng);
      expect(
        _hueDistance(phone.seedColors.first, const Color(0xFFD32F2F)),
        lessThan(20),
      );

      final desktop = await service.download(
        '$origin/random',
        client: ImageHostClient.desktop,
      );
      expect(await storedBytes(desktop), bluePng);
    });

    test('follows a JSON or plain-text reply to the real image', () async {
      expect(await storedBytes(await service.download('$origin/api')), redPng);
      expect(
        await storedBytes(await service.download('$origin/text')),
        bluePng,
      );
    });

    test('refuses an HTML page and explains a 403', () async {
      await expectLater(
        service.download('$origin/page.html'),
        throwsA(
          isA<BackgroundImageException>().having(
            (e) => e.message,
            'message',
            contains('不是图片'),
          ),
        ),
      );
      await expectLater(
        service.download('$origin/forbidden'),
        throwsA(
          isA<BackgroundImageException>().having(
            (e) => e.message,
            'message',
            contains('防盗链'),
          ),
        ),
      );
      // Nothing half-written was left behind.
      expect((await service.directory()).listSync(), isEmpty);
    });
  });

  group('BackgroundController', () {
    late Directory tempDir;
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nkg_bgc_');
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          backgroundImageServiceProvider.overrideWithValue(
            BackgroundImageService(baseDirectory: () async => tempDir),
          ),
        ],
      );
      await container.read(appSettingsProvider.future);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
      await tempDir.delete(recursive: true);
    });

    Future<String> writeSource(String name, Uint8List bytes) async {
      final file = File('${tempDir.path}/$name');
      await file.writeAsBytes(bytes);
      return file.path;
    }

    test('importing a picture re-seeds the theme from it', () async {
      final controller = container.read(backgroundControllerProvider);
      final imported = await controller.setFromFile(
        await writeSource('red.png', redPng),
      );

      final row = await db.settingsDao.get();
      expect(row.backgroundImageFile, imported.fileName);
      expect(row.backgroundImageUrl, isNull);
      expect(row.theme, 'custom');
      expect(row.customThemeSeed, imported.seedColors.first);
      // The notifier the UI watches saw the same write.
      expect(
        container.read(appSettingsProvider).value?.backgroundImageFile,
        imported.fileName,
      );
    });

    test('a replaced background is pruned; removal keeps the theme', () async {
      final controller = container.read(backgroundControllerProvider);
      final service = container.read(backgroundImageServiceProvider);
      final first = await controller.setFromFile(
        await writeSource('red.png', redPng),
      );
      final second = await controller.setFromFile(
        await writeSource('blue.png', bluePng),
      );

      expect(await service.resolve(first.fileName), isNull);
      expect(await service.resolve(second.fileName), isNotNull);

      final themed = await db.settingsDao.get();
      await controller.clear();
      final row = await db.settingsDao.get();
      expect(row.backgroundImageFile, isNull);
      expect(row.customThemeColor, themed.customThemeColor);
      expect((await service.directory()).listSync(), isEmpty);
    });
  });
}
