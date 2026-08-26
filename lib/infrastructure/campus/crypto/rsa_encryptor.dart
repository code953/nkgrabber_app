/// RSA encryption for campus login.
///
/// Extracts the RSA public key and key ID from the login page HTML,
/// then encrypts the password using PKCS1v1.5 padding.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Result of extracting RSA parameters from the login page.
class RsaLoginParams {
  const RsaLoginParams({required this.pubKey, required this.kid});

  /// Base64-encoded RSA public key (DER / PKCS#1 format).
  final String pubKey;

  /// Key identifier to send back with the login request.
  final String kid;
}

class RsaEncryptor {
  const RsaEncryptor._();

  /// Extract RSA public key and kid from login page HTML.
  ///
  /// The live login page carries both values in hidden form inputs, which is
  /// what the school's own script reads (`$("#pubKey")[0].value`):
  ///
  ///     <input type="hidden" id="kid"    name="kid"    value="402893...">
  ///     <input type="hidden" id="pubKey" name="pubKey" value="MIGfMA0GCS...">
  ///
  /// A `var pubKey = "..."` assignment is also accepted as a fallback, since
  /// other deployments of the same platform render the values inline.
  static RsaLoginParams? extractFromHtml(String html) {
    final pubKey = _extractField(html, 'pubKey');
    final kid = _extractField(html, 'kid');

    if (pubKey == null || kid == null) return null;

    return RsaLoginParams(pubKey: pubKey, kid: kid);
  }

  /// Find [name] as a hidden input's value, falling back to a JS assignment.
  ///
  /// Anchored on `id="<name>"` rather than a bare `<name>` so that `kid` cannot
  /// be matched inside an unrelated attribute such as `data-kid-hint`.
  static String? _extractField(String html, String name) {
    // <input ... id="pubKey" ... value="...">  — attribute order varies, so
    // value= is allowed to appear on either side of id=.
    final inputAfter = RegExp(
      '''id=["']$name["'][^>]*?value=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(html);
    if (inputAfter != null) return inputAfter.group(1);

    final inputBefore = RegExp(
      '''value=["']([^"']+)["'][^>]*?id=["']$name["']''',
      caseSensitive: false,
    ).firstMatch(html);
    if (inputBefore != null) return inputBefore.group(1);

    // var pubKey = "..." / pubKey: '...'
    final assignment = RegExp(
      '''\\b$name\\s*[=:]\\s*["']([^"']+)["']''',
    ).firstMatch(html);
    return assignment?.group(1);
  }

  /// Encrypt plaintext password using RSA PKCS1v1.5.
  ///
  /// [pubKeyBase64] is the Base64-encoded DER public key from the login page.
  static String encrypt(String plaintext, String pubKeyBase64) {
    final publicKey = _parsePublicKey(pubKeyBase64);

    final pkcs1 = PKCS1Encoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    final inputBytes = Uint8List.fromList(utf8.encode(plaintext));
    final encrypted = pkcs1.process(inputBytes);

    return base64.encode(encrypted);
  }

  /// Parse a Base64-encoded DER public key into [RSAPublicKey].
  ///
  /// Handles SubjectPublicKeyInfo (X.509) format:
  /// SEQUENCE {
  ///   SEQUENCE { algorithm OID, params }
  ///   BIT STRING { SEQUENCE { modulus INTEGER, exponent INTEGER } }
  /// }
  static RSAPublicKey _parsePublicKey(String base64Key) {
    final bytes = base64.decode(base64Key);

    // Simple ASN.1 DER parser for SubjectPublicKeyInfo.
    final reader = _Asn1Reader(Uint8List.fromList(bytes));

    // Outer SEQUENCE
    reader
      ..expectTag(0x30)
      ..readLength(); // outerLen — consumed but not needed

    // Inner SEQUENCE (algorithm identifier) — skip it
    reader.expectTag(0x30);
    final algoLen = reader.readLength();
    reader.skip(algoLen);

    // BIT STRING containing the public key
    reader
      ..expectTag(0x03)
      ..readLength() // bitStringLen — consumed but not needed
      ..skip(1); // skip unused-bits byte

    // Inner SEQUENCE (modulus + exponent)
    reader
      ..expectTag(0x30)
      ..readLength(); // keySeqLen — consumed but not needed

    // Modulus INTEGER
    reader.expectTag(0x02);
    final modBytes = reader.readIntegerBytes();
    final modulus = _bytesToBigInt(modBytes);

    // Exponent INTEGER
    reader.expectTag(0x02);
    final expBytes = reader.readIntegerBytes();
    final exponent = _bytesToBigInt(expBytes);

    return RSAPublicKey(modulus, exponent);
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }
}

/// Minimal ASN.1 DER reader.
class _Asn1Reader {
  _Asn1Reader(this._data);

  final Uint8List _data;
  int _pos = 0;

  void expectTag(int tag) {
    if (_pos >= _data.length || _data[_pos] != tag) {
      throw FormatException(
        'Expected ASN.1 tag 0x${tag.toRadixString(16)} '
        'at position $_pos',
      );
    }
    _pos++;
  }

  int readLength() {
    if (_pos >= _data.length) throw const FormatException('Unexpected end');
    final first = _data[_pos++];
    if (first < 0x80) return first;

    final numBytes = first & 0x7F;
    var length = 0;
    for (var i = 0; i < numBytes; i++) {
      length = (length << 8) | _data[_pos++];
    }
    return length;
  }

  void skip(int count) {
    _pos += count;
  }

  Uint8List readIntegerBytes() {
    final len = readLength();
    final bytes = _data.sublist(_pos, _pos + len);
    _pos += len;
    return bytes;
  }
}
