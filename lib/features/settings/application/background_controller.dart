/// Background-image state and actions.
///
/// Importing a background also re-seeds the theme from the picture, so the
/// two are applied in one settings write — see [BackgroundController].
library;

import 'dart:io';

import 'package:flutter/painting.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/core/utils/image_palette.dart';
import 'package:nkgrabber/infrastructure/background/background_image_service.dart';
import 'package:nkgrabber/infrastructure/providers.dart';
import 'package:path_provider/path_provider.dart';

/// The [BackgroundImageService], rooted in the application support directory.
///
/// Overridden in tests: `path_provider` does not resolve there.
final backgroundImageServiceProvider = Provider<BackgroundImageService>((ref) {
  return BackgroundImageService(baseDirectory: getApplicationSupportDirectory);
});

/// The background picture to draw, or null for none.
///
/// Returns before touching the file system when no background is set, so an
/// install that never uses the feature never resolves the directory.
final backgroundImageFileProvider = FutureProvider<File?>((ref) async {
  final name = ref.watch(
    appSettingsProvider.select((s) => s.valueOrNull?.backgroundImageFile),
  );
  if (name == null) return null;
  return ref.watch(backgroundImageServiceProvider).resolve(name);
});

/// Theme seed candidates from the current background, best first.
final backgroundSeedColorsProvider = FutureProvider<List<Color>>((ref) async {
  final file = await ref.watch(backgroundImageFileProvider.future);
  if (file == null) return const [];
  try {
    return await seedColorsFromImageBytes(await file.readAsBytes());
  } on ImageDecodeException {
    return const [];
  }
});

final backgroundControllerProvider = Provider<BackgroundController>(
  BackgroundController.new,
);

class BackgroundController {
  BackgroundController(this._ref);

  final Ref _ref;

  BackgroundImageService get _service =>
      _ref.read(backgroundImageServiceProvider);

  AppSettingsNotifier get _settings => _ref.read(appSettingsProvider.notifier);

  /// Use a local picture as the background.
  Future<ImportedBackground> setFromFile(String path) async {
    final imported = await _service.importFile(path);
    await _apply(imported);
    return imported;
  }

  /// Download [url] from an image host and use it as the background.
  Future<ImportedBackground> setFromUrl(
    String url, {
    ImageHostClient? client,
  }) async {
    final imported = await _service.download(url, client: client);
    await _apply(imported, url: parseImageUrl(url).toString(), client: client);
    return imported;
  }

  /// Fetch the stored image-host URL again — a random-image API returns a new
  /// picture each time.
  Future<ImportedBackground> refresh() async {
    final settings = await _ref.read(appSettingsProvider.future);
    final url = settings.backgroundImageUrl;
    if (url == null) {
      throw const BackgroundImageException(message: '当前背景不是来自图床链接');
    }
    return setFromUrl(
      url,
      client: ImageHostClient.fromString(settings.backgroundImageClient),
    );
  }

  /// Remove the background. The theme colour stays as it is.
  Future<void> clear() async {
    await _settings.clearBackground();
    await _service.prune();
  }

  Future<void> _apply(
    ImportedBackground imported, {
    String? url,
    ImageHostClient? client,
  }) async {
    await _settings.setBackground(
      fileName: imported.fileName,
      url: url,
      client: client?.name,
      // A colourless picture leaves the current theme alone rather than
      // switching to an arbitrary fallback.
      seedColor: imported.seedColors.firstOrNull,
    );
    // Only after the row points at the new file, so a crash in between leaves
    // an orphan rather than a dangling reference.
    await _service.prune(keep: imported.fileName);
  }
}
