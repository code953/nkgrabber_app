/// Imports and stores the user's background image.
///
/// Two sources: a local file, or an image-host URL. Either way the picture is
/// copied into the app's own `background/` directory and loaded from there, so
/// a launch never touches the network and a moved or deleted original does
/// not blank the app.
///
/// This is the one HTTP client besides the campus one. It exists because the
/// user asked for it, talks only to the URL the user typed, carries no
/// cookies, and runs only when the user presses a button.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/core/utils/image_palette.dart';
import 'package:path/path.dart' as p;

/// Which kind of device to present as when fetching from an image host.
///
/// Random-wallpaper APIs commonly look at the User-Agent (and the
/// `Sec-CH-UA-Mobile` client hint) and answer a desktop browser with a
/// landscape picture and a phone with a portrait one. A client that sent a
/// generic UA would get a landscape image on a phone — cropped to a sliver.
enum ImageHostClient {
  desktop,
  mobile;

  static ImageHostClient? fromString(String? value) {
    for (final c in values) {
      if (c.name == value) return c;
    }
    return null;
  }

  /// What "follow the device" means on this platform.
  static ImageHostClient get platformDefault =>
      Platform.isAndroid || Platform.isIOS ? mobile : desktop;
}

/// The result of a successful import.
class ImportedBackground {
  const ImportedBackground({required this.fileName, required this.seedColors});

  /// Bare file name inside [BackgroundImageService.directory].
  final String fileName;

  /// Theme seed candidates extracted from the picture, best first. May be
  /// empty for a colourless picture.
  final List<Color> seedColors;
}

class BackgroundImageService {
  BackgroundImageService({
    required Future<Directory> Function() baseDirectory,
    Dio? dio,
  }) : _baseDirectory = baseDirectory,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 30),
               responseType: ResponseType.bytes,
               // Random-image APIs almost always answer with a 302 to the
               // picture on a CDN; following it is the whole request.
               maxRedirects: 8,
             ),
           );

  final Future<Directory> Function() _baseDirectory;
  final Dio _dio;
  final _logger = AppLogger('BackgroundImageService');

  /// Largest picture accepted, from either source.
  static const maxBytes = 30 * 1024 * 1024;

  /// How many times a JSON / plain-text reply may point at another URL.
  static const _maxIndirections = 2;

  static const _desktopUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/131.0.0.0 Safari/537.36';

  // Contains both `Android` and `Mobile`, the two tokens mobile-detection
  // regexes key on.
  static const _androidUa =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/131.0.0.0 Mobile Safari/537.36';

  static const _iosUa =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'Version/17.5 Mobile/15E148 Safari/604.1';

  /// Request headers presenting as [client].
  @visibleForTesting
  static Map<String, String> headersFor(ImageHostClient client) {
    final mobile = client == ImageHostClient.mobile;
    final ios = mobile && !kIsWeb && Platform.isIOS;
    return {
      'User-Agent': mobile ? (ios ? _iosUa : _androidUa) : _desktopUa,
      // No AVIF: Flutter cannot decode it on most platforms, and a host that
      // sees it advertised may well choose it.
      'Accept': 'image/webp,image/png,image/jpeg,image/*;q=0.8,*/*;q=0.5',
      'Accept-Language': 'zh-CN,zh;q=0.9',
      'Sec-CH-UA-Mobile': mobile ? '?1' : '?0',
      'Sec-CH-UA-Platform': mobile
          ? (ios ? '"iOS"' : '"Android"')
          : '"Windows"',
    };
  }

  /// The directory background images live in, created on demand.
  Future<Directory> directory() async {
    final dir = Directory(p.join((await _baseDirectory()).path, _dirName));
    await dir.create(recursive: true);
    return dir;
  }

  /// The stored file for [fileName], or null if it is gone.
  ///
  /// Checks synchronously and creates nothing: this runs on every launch
  /// that has a background, and it is only ever a lookup.
  Future<File?> resolve(String fileName) async {
    final base = await _baseDirectory();
    final file = File(p.join(base.path, _dirName, p.basename(fileName)));
    return file.existsSync() ? file : null;
  }

  static const _dirName = 'background';

  /// Copy a local picture into the background directory.
  Future<ImportedBackground> importFile(String path) async {
    final file = File(path);
    try {
      if (await file.length() > maxBytes) throw _tooLarge();
      return await _store(await file.readAsBytes());
    } on FileSystemException catch (e) {
      throw BackgroundImageException(message: '无法读取所选文件', originalError: e);
    }
  }

  /// Download a picture from an image host.
  Future<ImportedBackground> download(
    String url, {
    ImageHostClient? client,
  }) async {
    final uri = parseImageUrl(url);
    final bytes = await _fetch(
      uri,
      client ?? ImageHostClient.platformDefault,
      indirectionsLeft: _maxIndirections,
    );
    return _store(bytes);
  }

  /// Delete every stored background except [keep].
  ///
  /// Each import gets a fresh file name — reusing one would let the image
  /// cache serve the old picture — so without this they would pile up.
  Future<void> prune({String? keep}) async {
    try {
      await for (final entity in (await directory()).list()) {
        if (entity is File && p.basename(entity.path) != keep) {
          await entity.delete();
        }
      }
    } on FileSystemException catch (e) {
      // Leftover files cost disk space, not correctness.
      _logger.warn('Failed to prune old backgrounds', e);
    }
  }

  Future<ImportedBackground> _store(Uint8List bytes) async {
    if (bytes.length > maxBytes) throw _tooLarge();
    final ext = sniffImageExtension(bytes);
    if (ext == null) {
      throw const BackgroundImageException(
        message: '不是受支持的图片格式（支持 JPG / PNG / WebP / GIF / BMP）',
      );
    }
    final List<Color> seeds;
    try {
      seeds = await seedColorsFromImageBytes(bytes);
    } on ImageDecodeException catch (e) {
      throw BackgroundImageException(message: '图片已损坏或无法解码', originalError: e);
    }
    final dir = await directory();
    final name = 'bg_${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(p.join(dir.path, name)).writeAsBytes(bytes, flush: true);
    return ImportedBackground(fileName: name, seedColors: seeds);
  }

  Future<Uint8List> _fetch(
    Uri uri,
    ImageHostClient client, {
    required int indirectionsLeft,
  }) async {
    final cancel = CancelToken();
    final Response<List<int>> response;
    try {
      response = await _dio.getUri<List<int>>(
        uri,
        options: Options(
          responseType: ResponseType.bytes,
          headers: headersFor(client),
        ),
        cancelToken: cancel,
        onReceiveProgress: (received, _) {
          if (received > maxBytes) cancel.cancel('too large');
        },
      );
    } on DioException catch (e) {
      // Host only: image-host URLs regularly carry API keys in the query.
      _logger.warn('Background download from ${uri.host} failed: ${e.type}');
      throw _mapDioError(e, uri);
    }

    final bytes = Uint8List.fromList(response.data ?? const []);
    if (sniffImageExtension(bytes) != null) return bytes;

    // Not a picture. Many random-image APIs answer with JSON (or a bare line
    // of text) naming the real image instead of redirecting to it.
    if (indirectionsLeft > 0) {
      final next = extractImageUrl(bytes, base: response.realUri);
      if (next != null) {
        return _fetch(next, client, indirectionsLeft: indirectionsLeft - 1);
      }
    }
    final type = response.headers.value(Headers.contentTypeHeader) ?? '未知类型';
    throw BackgroundImageException(
      message: '链接返回的不是图片（$type），请使用图片直链或随机图 API 地址',
    );
  }

  BackgroundImageException _mapDioError(DioException e, Uri uri) {
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => '连接 ${uri.host} 超时',
      DioExceptionType.cancel => '图片超过 ${maxBytes ~/ 1024 ~/ 1024} MB',
      DioExceptionType.badResponse => switch (e.response?.statusCode) {
        403 => '${uri.host} 拒绝访问（403），图床可能开启了防盗链',
        404 => '图片不存在（404）',
        final code => '${uri.host} 返回错误（HTTP $code）',
      },
      DioExceptionType.badCertificate => '${uri.host} 的 HTTPS 证书无效',
      _ => '无法连接到 ${uri.host}',
    };
    return BackgroundImageException(message: message, originalError: e);
  }

  BackgroundImageException _tooLarge() => const BackgroundImageException(
    message: '图片超过 ${maxBytes ~/ 1024 ~/ 1024} MB',
  );
}

/// Parse user input into an http(s) URL, adding `https://` when the scheme is
/// missing. Throws [BackgroundImageException] for anything else.
Uri parseImageUrl(String input) {
  var text = input.trim();
  if (!text.contains('://')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !(uri.scheme == 'http' || uri.scheme == 'https') ||
      uri.host.isEmpty) {
    throw const BackgroundImageException(message: '链接格式不正确');
  }
  return uri;
}

/// The file extension for [bytes] judged by magic number, or null when it is
/// not a format Flutter decodes everywhere.
///
/// Content-Type is not trusted: image hosts routinely serve pictures as
/// `application/octet-stream`, and error pages as `image/jpeg`.
String? sniffImageExtension(Uint8List bytes) {
  bool at(int offset, List<int> magic) {
    if (bytes.length < offset + magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[offset + i] != magic[i]) return false;
    }
    return true;
  }

  if (at(0, const [0xFF, 0xD8, 0xFF])) return 'jpg';
  if (at(0, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return 'png';
  }
  if (at(0, const [0x47, 0x49, 0x46, 0x38])) return 'gif';
  if (at(0, const [0x52, 0x49, 0x46, 0x46]) &&
      at(8, const [0x57, 0x45, 0x42, 0x50])) {
    return 'webp';
  }
  if (at(0, const [0x42, 0x4D])) return 'bmp';
  return null;
}

/// Keys random-image APIs put the picture's address under, most specific
/// first. Checked before falling back to "any URL in the document".
const _preferredUrlKeys = [
  'url',
  'imgurl',
  'img_url',
  'imageurl',
  'image_url',
  'img',
  'image',
  'pic',
  'src',
  'link',
];

/// The image URL a non-image reply points at, or null.
///
/// Handles the two shapes random-image APIs use besides a redirect: a JSON
/// document (`{"code":200,"data":{"url":"…"}}`, `{"imgurl":"…"}`, a list of
/// such objects) and a bare line of text holding the URL. HTML is deliberately
/// not scraped — that is an error page or an anti-hotlinking wall, and
/// guessing an `<img>` out of it would import whatever banner it contains.
@visibleForTesting
Uri? extractImageUrl(Uint8List body, {required Uri base}) {
  final text = utf8.decode(body, allowMalformed: true).trim();
  if (text.isEmpty) return null;

  if (text.startsWith('{') || text.startsWith('[')) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return null;
    }
    final preferred = <Uri>[];
    final other = <Uri>[];
    void walk(Object? node, String? key) {
      if (node is Map) {
        node.forEach((k, v) => walk(v, k.toString().toLowerCase()));
      } else if (node is List) {
        for (final v in node) {
          walk(v, key);
        }
      } else if (node is String) {
        final uri = _asAbsoluteUrl(node, base);
        if (uri == null) return;
        (_preferredUrlKeys.contains(key) ? preferred : other).add(uri);
      }
    }

    walk(json, null);
    return preferred.firstOrNull ?? other.firstOrNull;
  }

  // A single line of text that is itself a URL.
  if (!text.contains('\n') && !text.contains('<')) {
    return _asAbsoluteUrl(text, base);
  }
  return null;
}

/// [value] as an absolute http(s) URL, resolving protocol-relative `//host/…`
/// against [base]. Relative paths are rejected: in a JSON reply they are far
/// more often ids or captions than addresses.
Uri? _asAbsoluteUrl(String value, Uri base) {
  final v = value.trim();
  final Uri? uri;
  if (v.startsWith('//')) {
    uri = Uri.tryParse('${base.scheme}:$v');
  } else if (v.startsWith('http://') || v.startsWith('https://')) {
    uri = Uri.tryParse(v);
  } else {
    return null;
  }
  if (uri == null || uri.host.isEmpty) return null;
  return uri;
}
