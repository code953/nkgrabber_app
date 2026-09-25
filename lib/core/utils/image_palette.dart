/// Theme-colour extraction from a picture.
///
/// The same pipeline `ColorScheme.fromImageProvider` runs — Celebi
/// quantisation, then Material's `Score` ranking — but returning the seed
/// colours themselves. `fromImageProvider` hands back a finished scheme whose
/// `primary` is *not* the seed, and the seed is what gets persisted as the
/// custom theme colour.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Thrown when the bytes are not an image this platform can decode.
class ImageDecodeException implements Exception {
  const ImageDecodeException(this.cause);

  final Object cause;

  @override
  String toString() => 'ImageDecodeException($cause)';
}

/// Candidate theme seeds for an encoded image, best first.
///
/// Empty when the picture has no colour worth building a theme from (a
/// greyscale photo, say) — the caller should then keep the current colour
/// rather than fall back to an arbitrary blue.
///
/// Throws [ImageDecodeException] when [bytes] cannot be decoded, which doubles
/// as validation that a download really was a picture.
Future<List<Color>> seedColorsFromImageBytes(
  Uint8List bytes, {
  int desired = 4,
}) async {
  final ui.Image image;
  try {
    // Quantising every pixel of a 4K wallpaper takes seconds and changes
    // nothing — 112 px wide is what fromImageProvider samples at as well.
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 112);
    image = (await codec.getNextFrame()).image;
  } on Object catch (e) {
    throw ImageDecodeException(e);
  }
  try {
    final data = await image.toByteData();
    if (data == null) throw const ImageDecodeException('no pixel data');
    return seedColorsFromPixels(_rgbaToArgb(data), desired: desired);
  } finally {
    image.dispose();
  }
}

/// Candidate theme seeds for raw ARGB pixels, best first. See
/// [seedColorsFromImageBytes].
Future<List<Color>> seedColorsFromPixels(
  List<int> argbPixels, {
  int desired = 4,
}) async {
  if (argbPixels.isEmpty) return const [];
  final quantized = await QuantizerCelebi().quantize(argbPixels, 128);
  // Quantised colours are always opaque, so a transparent fallback cannot
  // collide with a real result — it only ever means "nothing qualified".
  const none = 0x00000000;
  final ranked = Score.score(
    quantized.colorToCount,
    desired: desired,
    fallbackColorARGB: none,
  );
  return [
    for (final argb in ranked)
      if (argb != none) Color(argb),
  ];
}

List<int> _rgbaToArgb(ByteData rgba) {
  final pixels = <int>[];
  for (var i = 0; i + 3 < rgba.lengthInBytes; i += 4) {
    final a = rgba.getUint8(i + 3);
    // Transparent regions are not part of the picture anyone sees.
    if (a < 255) continue;
    pixels.add(
      (a << 24) |
          (rgba.getUint8(i) << 16) |
          (rgba.getUint8(i + 1) << 8) |
          rgba.getUint8(i + 2),
    );
  }
  return pixels;
}
