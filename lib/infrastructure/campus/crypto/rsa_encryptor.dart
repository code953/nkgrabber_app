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
  /// Looks for patterns like:
  ///   var pubKey = "MIGfMA0GCS...";
  ///   var kid = "1234567890";
  static RsaLoginParams? extractFromHtml(String html) {
    final pubKeyMatch = RegExp(
      r'''pubKey\s*=\s*["']([^"']+)["']''',
    ).firstMatch(html);
    final kidMatch = RegExp(r'''kid\s*=\s*["']([^"']+)["']''').firstMatch(html);

    if (pubKeyMatch == null || kidMatch == null) return null;

    return RsaLoginParams(
      pubKey: pubKeyMatch.group(1)!,
      kid: kidMatch.group(1)!,
    );
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
