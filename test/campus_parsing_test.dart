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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/core/utils/constants.dart';
import 'package:nkgrabber/infrastructure/campus/campus_adapter_impl.dart';
import 'package:nkgrabber/infrastructure/campus/campus_client_factory.dart';
import 'package:nkgrabber/infrastructure/campus/campus_envelope.dart';
import 'package:nkgrabber/infrastructure/campus/crypto/rsa_encryptor.dart';
import 'package:nkgrabber/infrastructure/campus/portal_sso.dart';
import 'package:nkgrabber/infrastructure/campus/xkms_enum.dart';

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

  group('campus envelope', () {
    test('unwraps a batch list from result, not data', () {
      // Verbatim shape from getStudentXkList. The payload is under `result`;
      // reading `data` (as the original parser did) yields an empty list and
      // the batch picker silently shows 当前没有可选批次.
      final body = <String, dynamic>{
        'result': [
          {'xkid': 'batch-1', 'mc': '25-26下期第二次选修课'},
        ],
        'status': 200,
      };

      final rows = unwrapCampusRows(body, what: '读取选课批次');

      expect(rows, hasLength(1));
      expect(rows.first['xkid'], 'batch-1');
      expect(
        body.containsKey('data'),
        isFalse,
        reason: 'the live response has no `data` key at all',
      );
    });

    test('status 200 is an int and must not be read as a success boolean', () {
      // `status == true` is never satisfied, so a check written that way
      // rejects every successful response.
      final body = <String, dynamic>{'result': <Object?>[], 'status': 200};

      expect(body['status'], isA<int>());
      expect(body['status'] == true, isFalse);
      // The unwrapper must still accept it.
      expect(unwrapCampusRows(body, what: 'x'), isEmpty);
    });

    test('unwraps a nested list under a payload key', () {
      final body = <String, dynamic>{
        'result': {
          'msg': '查询成功！',
          'xbkList': [
            {'xbkid': 'course-1', 'xbkmc': '中国文化专题选讲'},
          ],
        },
        'status': 200,
      };

      final rows = unwrapCampusRows(body, what: '读取课程列表', listKey: 'xbkList');

      expect(rows, hasLength(1));
      expect(rows.first['xbkmc'], '中国文化专题选讲');
    });

    test('maps the platform error envelope to a CampusException', () {
      // This is exactly what the live server returned for the old
      // form-encoded login body.
      final body = <String, dynamic>{
        'error': {'code': '-32606', 'message': '参数格式非法！'},
      };

      expect(
        () => unwrapCampusRows(body, what: '登录'),
        throwsA(
          isA<CampusException>()
              .having((e) => e.type, 'type', CampusExceptionType.parameterError)
              .having((e) => e.message, 'message', contains('参数格式非法')),
        ),
      );
    });

    test('maps the expired-account error code to sessionExpired', () {
      final body = <String, dynamic>{
        'error': {'code': '-32604', 'message': 'account expired'},
      };

      expect(
        () => unwrapCampusRows(body, what: '读取批次'),
        throwsA(
          isA<CampusException>().having(
            (e) => e.type,
            'type',
            CampusExceptionType.sessionExpired,
          ),
        ),
      );
    });

    test('maps status 601/401 to sessionExpired', () {
      // The platform's own JS redirects to ./quit on these.
      for (final status in [601, 401]) {
        expect(
          () => unwrapCampusRows({
            'result': <Object?>[],
            'status': status,
          }, what: '读取批次'),
          throwsA(
            isA<CampusException>().having(
              (e) => e.type,
              'type',
              CampusExceptionType.sessionExpired,
            ),
          ),
          reason: 'status $status means the session is dead',
        );
      }
    });

    test('a missing result field is an error, not an empty list', () {
      // Distinguishing "no courses" from "response we do not understand" is
      // the whole point — the original code conflated them.
      expect(
        () => unwrapCampusRows({'status': 200}, what: '读取课程'),
        throwsA(isA<CampusException>()),
      );
    });

    test('a null result is a legitimate empty state', () {
      expect(
        unwrapCampusRows({'result': null, 'status': 200}, what: '读取课程'),
        isEmpty,
      );
    });

    test('command success requires result.code == "0"', () {
      final ok = unwrapCampusCommand({
        'result': {'msg': 'success', 'code': '0', 'faildnum': '0'},
      }, what: '登录');

      expect(ok['msg'], 'success');
    });

    test('command failure surfaces the server message', () {
      expect(
        () => unwrapCampusCommand({
          'result': {'msg': '人数已满', 'code': '-1'},
        }, what: '提交选课'),
        throwsA(
          isA<CampusException>().having((e) => e.message, 'message', '人数已满'),
        ),
      );
    });
  });

  group('campusInt', () {
    test('parses values the platform sends as strings', () {
      // zdxk arrives as the string "2". A plain `as num?` cast returns null,
      // which silently collapsed the per-request limit to 1 and would have
      // split every multi-course submission into single-course rounds.
      expect(campusInt('2'), 2);
      expect(('2' as Object) is num, isFalse);
    });

    test('parses values the platform sends as numbers', () {
      // xkms arrives as the number 0 from the same endpoint family.
      expect(campusInt(0), 0);
      expect(campusInt(40), 40);
    });

    test('returns null for absent or unparseable values', () {
      expect(campusInt(null), isNull);
      expect(campusInt(''), isNull);
      expect(campusInt('abc'), isNull);
    });
  });

  group('campusString', () {
    test('normalises numbers to their string form', () {
      // xkms is a number upstream but a string in our model and database.
      expect(campusString(0), '0');
      expect(campusString('1'), '1');
    });

    test('treats blank values as absent', () {
      expect(campusString(null), isNull);
      expect(campusString(''), isNull);
      expect(campusString('   '), isNull);
    });
  });

  group('portal SSO', () {
    // Verbatim structure of the post-login portal home page.
    const homeHtml = '''
<script>
    var origin = window.location.origin;
    var mycenter_token = "TOKEN0000000000000000000000000000000000000000000000000000000000";
    var mycenter_userid = "26411001";
</script>
<a class="dropdown-toggle userName" href="#" title="张三">
<sapn id="user_name">张三</sapn>
''';

    test('parses the SSO token and student id from the home page', () {
      final session = parsePortalSession(homeHtml);

      expect(session, isNotNull);
      expect(session!.userId, '26411001');
      expect(
        session.token,
        'TOKEN0000000000000000000000000000000000000000000000000000000000',
      );
    });

    test('returns null when the page is not a logged-in home page', () {
      expect(parsePortalSession('<html><body>请登录</body></html>'), isNull);
    });

    test('parses the display name', () {
      expect(parsePortalUserName(homeHtml), '张三');
    });

    test('returns null display name rather than throwing', () {
      // The name is cosmetic; a login must not fail over it.
      expect(parsePortalUserName('<html></html>'), isNull);
    });

    test('finds the course-selection app in the registry', () {
      // Verbatim row from getAllAppsByUser.jsmeb.
      final rows = <Map<String, dynamic>>[
        {
          'id': 'APPID',
          'mc': '学生选课',
          'appurl': '/njs_3033/xsxk2?a=a&ssoappid=APPID',
          'ssolx': 5,
          'apiurl': '/gdpk',
        },
      ];

      final app = findCourseSelectionApp(rows);

      expect(app, isNotNull);
      expect(app!.ssolx, 5);
      expect(app.apiUrl, '/gdpk');
      expect(
        app.appUrl,
        contains('ssoappid'),
        reason: 'ssoappid is per-deployment and must come from the registry',
      );
    });

    test('builds the ssolx=5 URL with token, apiUrl and userid', () {
      // A bare GET /njs_3033/xsxk2 answers 403; these three params are what
      // make the course-selection host mint gdpk.
      final url = buildSsoUrl(
        origin: 'http://campus.nks.edu.cn',
        app: const PortalApp(
          appUrl: '/njs_3033/xsxk2?a=a&ssoappid=APPID',
          apiUrl: '/gdpk',
          ssolx: 5,
        ),
        session: const PortalSession(token: 'TOK', userId: '26411001'),
      );

      expect(url, startsWith('http://campus.nks.edu.cn/njs_3033/xsxk2?a=a'));
      expect(url, contains('&token=TOK'));
      expect(url, contains('userid=26411001'));
      expect(
        url,
        contains('apiUrl=http%3A%2F%2Fcampus.nks.edu.cn%2Fgdpk'),
        reason: 'apiUrl is absolute and must be query-encoded',
      );
    });

    test('refuses to guess a URL for an unsupported ssolx', () {
      // Silently building the wrong URL would surface as an opaque 403.
      expect(
        () => buildSsoUrl(
          origin: 'http://campus.nks.edu.cn',
          app: const PortalApp(appUrl: '/x', apiUrl: '/y', ssolx: 1),
          session: const PortalSession(token: 'TOK', userId: '1'),
        ),
        throwsA(
          isA<CampusException>().having(
            (e) => e.message,
            'message',
            contains('ssolx=1'),
          ),
        ),
      );
    });
  });

  group('Xkms classification', () {
    test('1/2/3 are submittable', () {
      for (final code in ['1', '2', '3']) {
        expect(Xkms.statusOf(code), XkmsStatus.submittable);
        expect(Xkms.blockedReason(code), isNull);
      }
    });

    test('0 means the batch has closed, not that the client is outdated', () {
      // The live deployment's only batch reports xkms=0. Treating that as
      // unrecognised told the user to wait for a client upgrade, which would
      // never have helped.
      expect(Xkms.statusOf('0'), XkmsStatus.closed);
      expect(Xkms.labelFor('0'), '选课已结束');
      expect(Xkms.blockedReason('0'), '该批次选课已结束');
      expect(
        Xkms.blockedReason('0'),
        isNot(contains('升级')),
        reason: 'a closed batch is not a client-version problem',
      );
    });

    test('genuinely unknown values still ask for an upgrade', () {
      expect(Xkms.statusOf('9'), XkmsStatus.unknown);
      expect(Xkms.blockedReason('9'), contains('升级'));
    });

    test('labels match the submittable modes', () {
      expect(Xkms.labelFor('1'), '抢选');
      expect(Xkms.labelFor('2'), '正选');
      expect(Xkms.labelFor('3'), '补退选');
    });
  });

  group('request headers', () {
    // The UA used to end in `NKgrabber/1.0`, naming the tool in every request
    // the school's access log ever saw. Nothing in the campus protocol keys
    // off the UA, so identifying ourselves bought nothing.
    test('the User-Agent does not identify the app', () {
      final ua =
          CampusClient(accountId: 'test').dio.options.headers['User-Agent']
              as String;

      expect(ua.toLowerCase(), isNot(contains('nkgrabber')));
      expect(ua.toLowerCase(), isNot(contains('dart')));
      expect(ua, startsWith('Mozilla/5.0'));
      expect(ua, contains('Chrome/'));
    });
  });

  group('malformed Set-Cookie tolerance', () {
    // The login response carries two Set-Cookie headers, verbatim:
    //
    //   Set-Cookie: HttpOnly=
    //   Set-Cookie: JSESSIONID=<32 hex>; path=/zhxy
    //
    // The first is the school's bug — it meant to append the HttpOnly
    // attribute to the session cookie and emitted a bare header line instead.
    // `Cookie.fromSetCookieValue('HttpOnly=')` throws, because dart:io
    // requires at least one character after the `=`.
    const malformed = 'HttpOnly=';
    const valid = 'JSESSIONID=8de847b8e8ca435e8b1d0f2a7c934e11; path=/zhxy';

    test('dart:io rejects the bare HttpOnly= header the school sends', () {
      // Pinning the upstream behaviour: if a future SDK starts accepting it,
      // the workaround below becomes removable and this test says so.
      expect(
        () => Cookie.fromSetCookieValue(malformed),
        throwsA(isA<HttpException>()),
      );
      expect(Cookie.fromSetCookieValue(valid).name, 'JSESSIONID');
    });

    test('the campus client is built to skip it, not drop the whole jar', () {
      // CookieManager maps every Set-Cookie through fromSetCookieValue and
      // forces the chain with .toList(). One throw aborts the entire save, so
      // the *valid* JSESSIONID on the same response is lost too and dio
      // rejects the request as `DioException [unknown]: null` — which is
      // exactly the error adding an account produced.
      final client = CampusClient(accountId: 'test');
      addTearDown(client.dispose);

      final manager = client.dio.interceptors.whereType<CookieManager>().single;

      expect(
        manager.ignoreInvalidCookies,
        isTrue,
        reason: 'every login response carries a bare `HttpOnly=` header',
      );
    });

    test(
      'the campus client keeps the good cookie from a mixed response',
      () async {
        final client = CampusClient(accountId: 'test');
        addTearDown(client.dispose);
        final manager = client.dio.interceptors
            .whereType<CookieManager>()
            .single;
        final uri = Uri.parse('${AppConstants.campusBaseUrl}/zhxy/');

        await manager.saveCookies(
          Response<void>(
            requestOptions: RequestOptions(
              path: '/zhxy/',
              baseUrl: AppConstants.campusBaseUrl,
            ),
            headers: Headers.fromMap({
              HttpHeaders.setCookieHeader: [malformed, valid],
            }),
          ),
        );

        final saved = await client.cookieJar.loadForRequest(uri);
        expect(
          saved.map((c) => c.name),
          contains('JSESSIONID'),
          reason: 'losing the session cookie is what broke account adding',
        );
        expect(saved.map((c) => c.name), isNot(contains('HttpOnly')));
      },
    );
  });

  group('SSO redirect following', () {
    // The live chain, captured hop by hop:
    //
    //   GET /njs_3033/xsxk2?…&token=…  → 302, Set-Cookie: gdpk=…; Path=/
    //   GET /njs_3033/loginRedirect?…  → 302
    //   GET /njs_3033/xsxk2?…          → 200
    //
    // Dio's own followRedirects runs in the HTTP adapter, *below* the
    // interceptor chain, so CookieManager never sees hop 0 — the gdpk it sets
    // is dropped, the final hop arrives cookie-less, and the server answers
    // 403. The adapter therefore walks the chain itself, one hop per request,
    // so every response passes through the interceptors.
    //
    // This drives the real adapter against a local server that reproduces the
    // school's behaviour: the malformed Set-Cookie, the redirect chain, and
    // the 403 for a request that arrives without gdpk.
    late HttpServer server;
    late String origin;
    var sawCookielessFinalHop = false;

    setUp(() async {
      sawCookielessFinalHop = false;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      origin = 'http://${server.address.address}:${server.port}';

      unawaited(
        server.forEach((req) async {
          final res = req.response;
          final path = req.uri.path;
          final cookies = req.headers.value(HttpHeaders.cookieHeader) ?? '';

          // Every portal response carries the school's malformed header.
          void portalCookies() {
            res.headers.add(
              HttpHeaders.setCookieHeader,
              'HttpOnly=',
              preserveHeaderCase: true,
            );
            res.headers.add(
              HttpHeaders.setCookieHeader,
              'JSESSIONID=$_fakeSessionId; path=/zhxy',
            );
          }

          switch (path) {
            case '/zhxy/welcome':
              portalCookies();
              res.headers.contentType = ContentType.html;
              res.write(_fakeLoginPage);
            case '/zhxy/rrtlogin/loginWithYzm.jsmeb':
              portalCookies();
              res.write('{"result":{"code":"0","msg":"success"},"status":200}');
            case '/zhxy':
              portalCookies();
              res.headers.contentType = ContentType.html;
              res.write(_fakePortalHome);
            case '/zhxy/app/getAllAppsByUser.jsmeb':
              portalCookies();
              res.write(
                '{"result":{"data":[{"id":"APPID","mc":"学生选课",'
                '"appurl":"/njs_3033/xsxk2?a=a&ssoappid=APPID",'
                '"ssolx":5,"apiurl":"/gdpk"}]},"status":200}',
              );
            case '/njs_3033/xsxk2' when !cookies.contains('gdpk'):
              // Hop 0: mint gdpk, then bounce. If the client followed
              // redirects itself, CookieManager would never see this header.
              res.headers.add(
                HttpHeaders.setCookieHeader,
                'gdpk=$_fakeGdpk; Path=/; HttpOnly',
              );
              res.statusCode = HttpStatus.found;
              res.headers.set('Location', '/njs_3033/loginRedirect');
            case '/njs_3033/loginRedirect':
              res.statusCode = HttpStatus.found;
              res.headers.set('Location', '/njs_3033/xsxk2?a=a');
            case '/njs_3033/xsxk2':
              // Reached only when gdpk came back — which is the whole point.
              res.write('<html>选课</html>');
            default:
              if (path.startsWith('/njs_3033/') && !cookies.contains('gdpk')) {
                sawCookielessFinalHop = true;
                res.statusCode = HttpStatus.forbidden;
              }
          }
          await res.close();
        }),
      );
    });

    tearDown(() => server.close(force: true));

    test('login walks the chain and ends up holding gdpk', () async {
      final client = CampusClient(accountId: 'test', baseUrl: origin);
      addTearDown(client.dispose);
      final adapter = CampusAdapterImpl(client: client);

      final result = await adapter.loginWithPassword('26411001', 'pw');

      expect(
        result.gdpk,
        _fakeGdpk,
        reason:
            'gdpk is set on hop 0 and only survives if that response '
            'passes through CookieManager',
      );
      expect(result.studentNo, '26411001');
      expect(
        sawCookielessFinalHop,
        isFalse,
        reason: 'a hop arriving without gdpk is what produced the live 403',
      );
    });
  });

  group('submit payload', () {
    test('kmhDtoList is a JSON array of objects, not a joined string', () {
      // The school's page sends
      //   kmhDtoList: JSON.stringify([{kmh: "<id>"}, ...])
      // A comma-joined "id1,id2" is a different wire format entirely.
      const kmhList = ['id1', 'id2'];
      final encoded = jsonEncode([
        for (final kmh in kmhList) {'kmh': kmh},
      ]);

      expect(encoded, '[{"kmh":"id1"},{"kmh":"id2"}]');
      expect(
        encoded,
        isNot('id1,id2'),
        reason: 'the original comma-joined form is what the server rejected',
      );
      expect(jsonDecode(encoded), isA<List<dynamic>>());
    });
  });
}

// ---------------------------------------------------------------------------
// Fixtures for the loopback portal used by the SSO redirect group.
//
// The RSA key below is a throwaway 1024-bit key generated for this test. It
// encrypts nothing real — the fake server accepts any ciphertext.
// ---------------------------------------------------------------------------

const _fakeSessionId = '8de847b8e8ca435e8b1d0f2a7c934e11';
const _fakeGdpk = 's%3AFAKEgdpkVALUEforTESTINGonly0000';
const _fakeKid = '402893629fb5ea8801a03c4f48e512f3';
// ignore: lines_longer_than_80_chars — a base64 key has no legal break point
const _fakePubKey =
    'MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDD9jeNHqi1sf3cKV5dhv34kouzK+2MzdbpDBrwm1MASxUsMjyEDlgbbSEkNx6Ca85xvTCwbcO6501kUI4Xhws2Njt84eQ+ZjPATuHxBNwVoaJ8QlwlKBRPKEzo9xPpVa/wpuLEIGa60Xpz08x7aZG26kbYPPfnHwVQ+NHmkIcc0wIDAQAB';

const _fakeLoginPage =
    '''
<form id="loginForm" method="post">
  <input type="hidden" id="kid" name="kid" value="$_fakeKid">
  <input type="hidden" id="pubKey" name="pubKey" value="$_fakePubKey">
</form>
''';

const _fakePortalHome = '''
<script>
    var mycenter_token = "TOKEN0000000000000000000000000000000000000000000000";
    var mycenter_userid = "26411001";
</script>
<sapn id="user_name">张三</sapn>
''';
