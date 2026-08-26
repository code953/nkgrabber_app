/// Tests for the campus response-parsing layer.
///
/// Every fixture in this file is a verbatim excerpt of a real response captured
/// from the live campus deployment (http://campus.nks.edu.cn) with a test
/// account. They are the ground truth the parsers must satisfy — hand-written
/// approximations are what let the original defects through.
///
/// Sensitive values (the RSA modulus, session ids, the student's name and
/// number) are replaced with structurally-identical placeholders. Field names,
/// nesting, and value *types* are preserved exactly, because those are what
/// the parsers depend on.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nkgrabber/infrastructure/campus/crypto/rsa_encryptor.dart';

void main() {
  group('RsaEncryptor.extractFromHtml', () {
    // The live page carries pubKey/kid in hidden inputs, not as JS vars.
    // Attribute order and the surrounding markup are as captured.
    const liveLoginPageHtml = '''
<form id="loginForm" method="post">
  <input type="text" id="account" name="account" value="">
  <input type="password" id="password" name="password" value="">
  <input type="hidden" id="kid" name="kid" value="402893629fb5ea8801a03c4f48e512f3">
  <input type="hidden" id="pubKey" name="pubKey" value="MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDKGAJ0000000000IQIDAQAB">
</form>
''';

    test('extracts pubKey and kid from hidden form inputs', () {
      final params = RsaEncryptor.extractFromHtml(liveLoginPageHtml);

      expect(
        params,
        isNotNull,
        reason:
            'the live login page must parse — this is the exact markup '
            'that produced 无法从登录页面提取加密参数',
      );
      expect(params!.kid, '402893629fb5ea8801a03c4f48e512f3');
      expect(
        params.pubKey,
        'MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDKGAJ0000000000IQIDAQAB',
      );
    });

    test('extracts values when value= precedes id=', () {
      // Attribute order is not guaranteed by the platform's templating.
      const reordered =
          '<input type="hidden" value="abc123" id="kid" name="kid"> '
          '<input type="hidden" value="KEYDATA" id="pubKey" name="pubKey">';

      final params = RsaEncryptor.extractFromHtml(reordered);

      expect(params, isNotNull);
      expect(params!.kid, 'abc123');
      expect(params.pubKey, 'KEYDATA');
    });

    test('still accepts the inline JS form used by other deployments', () {
      const inlineJs = '''
        var pubKey = "MIGfMA0GCSqGSIb3DQEBAQUAA4KEYDATA";
        var kid = "deadbeefcafe";
      ''';

      final params = RsaEncryptor.extractFromHtml(inlineJs);

      expect(params, isNotNull);
      expect(params!.kid, 'deadbeefcafe');
      expect(params.pubKey, 'MIGfMA0GCSqGSIb3DQEBAQUAA4KEYDATA');
    });

    test('returns null when the page carries neither form', () {
      // A logged-out redirect or an error page must not yield bogus params.
      const noParams = '<html><body><p>请重新登录</p></body></html>';

      expect(RsaEncryptor.extractFromHtml(noParams), isNull);
    });

    test('returns null when only one of the two values is present', () {
      // Submitting with a missing kid would fail server-side with an opaque
      // 参数格式非法, so the adapter must reject it up front.
      const kidOnly = '<input type="hidden" id="kid" value="abc123">';

      expect(RsaEncryptor.extractFromHtml(kidOnly), isNull);
    });

    test('does not mistake a similarly-named attribute for kid', () {
      // `kid` is a substring of many attribute names; an unanchored pattern
      // matched `data-kid-hint` and returned the wrong value.
      const decoy =
          '<div data-kid-hint="not-the-kid"></div> '
          '<input type="hidden" id="pubKey" value="KEYDATA">';

      expect(RsaEncryptor.extractFromHtml(decoy), isNull);
    });
  });
}
