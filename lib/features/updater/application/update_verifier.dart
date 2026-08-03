/// Update verifier.
///
/// Implements the three-step verification for downloaded updates (§11.1):
/// 1. SHA-256 hash verification
/// 2. Ed25519 signature verification using embedded public key
/// 3. Platform native signature (deferred to OS)
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';

class UpdateVerifier {
  const UpdateVerifier._();

  static final _logger = AppLogger('UpdateVerifier');

  /// Verify a downloaded file against its expected SHA-256 hash.
  ///
  /// Returns true if the hash matches.
  static Future<bool> verifySha256(File file, String expectedHex) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    final actualHex = digest.toString();

    if (actualHex != expectedHex.toLowerCase()) {
      _logger.warn(
        'SHA-256 mismatch: expected $expectedHex, got $actualHex',
      );
      return false;
    }

    _logger.info('SHA-256 verification passed');
    return true;
  }

  /// Verify an Ed25519 signature against the file's SHA-256 hash.
  ///
  /// [publicKeyBytes] is the embedded Ed25519 public key (32 bytes).
  /// [signatureBase64] is the Base64-encoded signature from the server.
  /// [fileHash] is the SHA-256 hex digest of the file.
  static Future<bool> verifyEd25519Signature({
    required Uint8List publicKeyBytes,
    required String signatureBase64,
    required String fileHash,
  }) async {
    try {
      final algorithm = Ed25519();
      final publicKey = SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      );

      final signatureBytes = base64.decode(signatureBase64);
      final signature = Signature(
        signatureBytes,
        publicKey: publicKey,
      );

      final messageBytes = utf8.encode(fileHash);
      final isValid = await algorithm.verify(
        messageBytes,
        signature: signature,
      );

      if (!isValid) {
        _logger.warn('Ed25519 signature verification failed');
      } else {
        _logger.info('Ed25519 signature verification passed');
      }

      return isValid;
    } on Exception catch (e) {
      _logger.warn('Ed25519 verification error', e);
      return false;
    }
  }
}
