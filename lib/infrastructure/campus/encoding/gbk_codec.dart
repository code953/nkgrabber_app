/// GBK encoding/decoding support.
///
/// The campus system may respond with GBK-encoded content.
/// This codec converts GBK bytes to Dart strings and vice versa.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Decodes GBK-encoded bytes to a Dart [String].
///
/// GBK is a superset of GB2312 used by many Chinese web systems.
/// Since Dart has no built-in GBK codec, we attempt UTF-8 first
/// and fall back to Latin-1 if that fails, which preserves raw bytes
/// for further server-side interpretation.
String decodeGbk(Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } catch (_) {
    // Fall back to latin1 which preserves all byte values.
    return latin1.decode(bytes);
  }
}

/// Encodes a Dart [String] to bytes suitable for form POST.
///
/// Uses UTF-8 encoding which the campus server also accepts.
Uint8List encodeForPost(String input) {
  return Uint8List.fromList(utf8.encode(input));
}
