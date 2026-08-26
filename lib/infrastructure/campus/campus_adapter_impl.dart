/// Campus adapter implementation.
///
/// Implements all campus system operations using an isolated [CampusClient].
/// Handles GBK decoding, RSA login, cookie management, and response parsing.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/infrastructure/campus/campus_adapter.dart';
import 'package:nkgrabber/infrastructure/campus/campus_client_factory.dart';
import 'package:nkgrabber/infrastructure/campus/campus_envelope.dart';
import 'package:nkgrabber/infrastructure/campus/crypto/rsa_encryptor.dart';
import 'package:nkgrabber/infrastructure/campus/encoding/gbk_codec.dart';
import 'package:nkgrabber/infrastructure/campus/models/campus_models.dart';
import 'package:nkgrabber/infrastructure/campus/portal_sso.dart';

class CampusAdapterImpl implements CampusAdapter {
  CampusAdapterImpl({required CampusClient client}) : _client = client;

  final CampusClient _client;
  final _logger = AppLogger('CampusAdapter');

  /// Per-account serial queue to prevent concurrent campus requests.
  final _queue = _RequestQueue();

  int _campusClockOffsetMs = 0;

  @override
  int get campusClockOffsetMs => _campusClockOffsetMs;

  @override
  Future<LoginResult> loginWithPassword(String account, String password) async {
    return _queue.add(() async {
      // Step 1: Get login page to extract RSA public key and kid.
      final welcomeResponse = await _client.dio.get<List<int>>('/zhxy/welcome');
      final html = _decodeResponse(welcomeResponse);

      final rsaParams = RsaEncryptor.extractFromHtml(html);
      if (rsaParams == null) {
        throw const CampusException(
          message: '无法从登录页面提取加密参数',
          type: CampusExceptionType.loginFailed,
        );
      }

      // Step 2: Encrypt password with RSA PKCS1v1.5.
      final encryptedPassword = RsaEncryptor.encrypt(
        password,
        rsaParams.pubKey,
      );

      // Step 3: POST login. The body is JSON even though the content type is
      // form-encoded — that is what the school's own script sends, and a
      // genuinely form-encoded `params=[...]` is rejected with 参数格式非法.
      final loginResponse = await _client.dio.post<List<int>>(
        '/zhxy/rrtlogin/loginWithYzm.jsmeb',
        data: jsonEncode({
          'params': [account, encryptedPassword, '', rsaParams.kid],
        }),
        options: Options(
          contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
        ),
      );
      _updateClockOffset(loginResponse);
      _checkLoginResult(_decodeAndParseJson(loginResponse));

      // Step 4: Read the portal home page for the SSO token and student id.
      final homeResponse = await _client.dio.get<List<int>>('/zhxy');
      final homeHtml = _decodeResponse(homeResponse);
      final portal = parsePortalSession(homeHtml);
      if (portal == null) {
        throw const CampusException(
          message: '登录成功但未能读取门户会话信息',
          type: CampusExceptionType.loginFailed,
        );
      }

      // Step 5: Exchange the portal session for the gdpk cookie.
      final gdpk = await _acquireGdpk(portal);

      // Step 6: Resolve the display name. The portal page is the only source
      // that works for a student with no batches, so prefer it; fall back to
      // the student number rather than failing a good login over a label.
      final studentName = parsePortalUserName(homeHtml);

      // Log the opaque account id only — never the student's name or number.
      _logger.info('Login successful');

      return LoginResult(
        gdpk: gdpk,
        studentNo: portal.userId,
        studentName: studentName ?? portal.userId,
      );
    });
  }

  /// Validate the login response envelope.
  ///
  /// Success is `result.code == "0"`; there is no top-level boolean `status`.
  /// The distinct codes matter because each needs a different user action.
  void _checkLoginResult(Map<String, dynamic> body) {
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      throw CampusException(
        message: error['message']?.toString() ?? '登录失败',
        type: CampusExceptionType.loginFailed,
      );
    }

    final result = body['result'];
    if (result is! Map<String, dynamic>) {
      throw const CampusException(
        message: '登录响应格式不符合预期',
        type: CampusExceptionType.unknownResponse,
      );
    }

    final code = result['code']?.toString();
    if (code == '0') return;

    final msg = result['msg']?.toString();

    // The portal shows a captcha field once three attempts have failed. This
    // client cannot solve one, so say so instead of retrying into a lockout.
    final failedCount = campusInt(result['faildnum']) ?? 0;
    if (failedCount >= 3 || (msg != null && msg.contains('验证码'))) {
      throw CampusException(
        message: msg == null || !msg.contains('验证码')
            ? '登录失败次数过多，学校已要求验证码，请在浏览器中登录一次后重试'
            : msg,
        type: CampusExceptionType.captchaRequired,
      );
    }

    throw CampusException(
      message: switch (code) {
        '5' => '首次登录需要先在学校门户修改密码',
        '6' => '密码强度不足，需要先在学校门户修改密码',
        _ => msg ?? '登录失败',
      },
      type: CampusExceptionType.loginFailed,
    );
  }

  /// Follow the portal SSO redirect until the course-selection host sets gdpk.
  Future<String> _acquireGdpk(PortalSession portal) async {
    final registry = await _client.dio.post<List<int>>(
      '/zhxy/app/getAllAppsByUser.jsmeb',
      data: jsonEncode({'params': <Object?>[]}),
      options: Options(
        contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
      ),
    );
    final rows = unwrapCampusRows(
      _decodeAndParseJson(registry),
      what: '读取选课入口',
      listKey: 'data',
    );

    final app = findCourseSelectionApp(rows);
    if (app == null) {
      throw const CampusException(
        message: '该账号没有开通选课应用',
        type: CampusExceptionType.loginFailed,
      );
    }

    final origin = _client.dio.options.baseUrl;
    // Throws with an actionable message when the school changes ssolx.
    final ssoUrl = buildSsoUrl(origin: origin, app: app, session: portal);

    await _client.dio.getUri<List<int>>(Uri.parse(ssoUrl));

    final cookies = await _client.cookieJar.loadForRequest(
      Uri.parse('$origin/njs_3033/'),
    );
    final gdpk = cookies
        .where((c) => c.name == 'gdpk')
        .map((c) => c.value)
        .firstOrNull;

    if (gdpk == null || gdpk.isEmpty) {
      throw const CampusException(
        message: '未获取到选课会话',
        type: CampusExceptionType.loginFailed,
      );
    }
    return gdpk;
  }

  @override
  Future<StudentProfile> validateCookie(String gdpk) async {
    return _queue.add(() async {
      // Set the gdpk cookie.
      await _client.setCookie(
        'gdpk',
        gdpk,
        Uri.parse(_client.dio.options.baseUrl).host,
      );

      return _fetchProfile();
    });
  }

  @override
  Future<List<SelectionBatch>> listBatches() async {
    return _queue.add(() async {
      final response = await _postForm('/njs_3033/xsxk/getStudentXkList', '');
      final rows = unwrapCampusRows(
        _decodeAndParseJson(response),
        what: '读取选课批次',
      );

      return rows.map((map) {
        return SelectionBatch(
          xkid: campusString(map['xkid']) ?? '',
          // Sent as a number by this endpoint, so normalise via campusString
          // rather than assuming a JSON string.
          xkms: campusString(map['xkms']) ?? '',
          batchName: campusString(map['mc']) ?? '',
          // Sent as the string "2"; a plain `as num?` cast yields null here and
          // silently collapses the per-request limit to 1.
          zdxk: campusInt(map['zdxk']) ?? 1,
          kssj: campusString(map['kssj']) ?? '',
          jssj: campusString(map['jssj']) ?? '',
        );
      }).toList();
    });
  }

  @override
  Future<List<Course>> listCourses(String xkid) async {
    return _queue.add(() async {
      final response = await _postForm(
        '/njs_3033/xsxk_Xbk/getXbkByXkid',
        'xkid=$xkid',
      );
      final rows = unwrapCampusRows(
        _decodeAndParseJson(response),
        what: '读取课程列表',
        listKey: 'xbkList',
      );

      return rows.map((map) {
        final xbkid = campusString(map['xbkid']);
        return Course(
          // Upstream rows carry no kmh; the school submits xbkid.
          kmh: xbkid ?? '',
          courseName: campusString(map['xbkmc']) ?? '',
          xbkid: xbkid,
          teacherName: campusString(map['jsxm']),
          capacity: campusInt(map['rsyq']),
          selected: campusInt(map['yxrs']),
          remaining: campusInt(map['syme']),
          credit: campusString(map['xbkxf']),
        );
      }).toList();
    });
  }

  @override
  Future<List<SelectionRecord>> listSelections(String xkid) async {
    return _queue.add(() async {
      final response = await _postForm(
        '/njs_3033/xsxk_Xbk/getStudentXkJlList',
        'xkid=$xkid',
      );
      final rows = unwrapCampusRows(
        _decodeAndParseJson(response),
        what: '读取已选课程',
      );

      return rows.map((map) {
        return SelectionRecord(
          kmh: campusString(map['kmh']) ?? '',
          courseName: campusString(map['kmmc']) ?? '',
        );
      }).toList();
    });
  }

  @override
  Future<SubmitResult> submit(SubmitSelection command) async {
    return _queue.add(() async {
      // kmhDtoList is a JSON array of objects, not a comma-joined list of ids:
      //   kmhDtoList=[{"kmh":"<id>"},{"kmh":"<id>"}]
      // matching the school's own
      //   saveStudentXkJs({..., kmhDtoList: JSON.stringify([{kmh: ...}])})
      //
      // UNVERIFIED against the live server: the only batch on this deployment
      // closed 2026-04-18, and submitting would mutate a real student's
      // registration. Derived from the page script, not from a live response.
      final kmhDtoList = jsonEncode([
        for (final kmh in command.kmhList) {'kmh': kmh},
      ]);
      final response = await _postForm(
        '/njs_3033/xsxk_Xbk/saveStudentXkJs',
        'xkid=${command.xkid}'
            '&xkms=${command.xkms}'
            '&sftj=1'
            '&kms=${command.kmhList.length}'
            '&kmhDtoList=${Uri.encodeQueryComponent(kmhDtoList)}',
      );
      final body = _decodeAndParseJson(response);

      // Map the server's message to a typed exception so RetryClassifier can
      // act on it, rather than letting every failure look retryable.
      final Map<String, dynamic> result;
      try {
        result = unwrapCampusCommand(body, what: '提交选课');
      } on CampusException catch (e) {
        if (e.type == CampusExceptionType.unknownResponse) {
          throw _mapSubmitMessage(e.message);
        }
        rethrow;
      }

      return SubmitResult(success: true, message: campusString(result['msg']));
    });
  }

  /// Map a submit failure message to a typed [CampusException].
  CampusException _mapSubmitMessage(String msg) {
    if (msg.contains('人数已满') || msg.contains('选课人数') || msg.contains('课程已满')) {
      return CampusException(
        message: msg,
        type: CampusExceptionType.courseFull,
      );
    }
    if (msg.contains('时间冲突') || msg.contains('课程冲突') || msg.contains('已选该课')) {
      return CampusException(
        message: msg,
        type: CampusExceptionType.courseConflict,
      );
    }
    if (msg.contains('选课批次') &&
        (msg.contains('未开始') || msg.contains('已结束') || msg.contains('不在时间'))) {
      return CampusException(
        message: msg,
        type: CampusExceptionType.batchClosed,
      );
    }
    if (msg.contains('超出') && msg.contains('限制') ||
        msg.contains('学分') && msg.contains('上限')) {
      return CampusException(
        message: msg,
        type: CampusExceptionType.limitReached,
      );
    }
    if (msg.contains('风控') || msg.contains('异常操作') || msg.contains('频繁')) {
      return CampusException(
        message: msg,
        type: CampusExceptionType.riskControl,
      );
    }
    if (msg.contains('参数') && msg.contains('错误') || msg.contains('非法')) {
      return CampusException(
        message: msg,
        type: CampusExceptionType.parameterError,
      );
    }
    if (msg.contains('登录') || msg.contains('会话') || msg.contains('过期')) {
      return CampusException(
        message: msg,
        type: CampusExceptionType.sessionExpired,
      );
    }
    // Unknown failure — treat as retryable.
    return CampusException(
      message: msg,
      type: CampusExceptionType.unknownResponse,
    );
  }

  @override
  Future<WithdrawResult> withdraw(String xkid) async {
    return _queue.add(() async {
      final response = await _postForm(
        '/njs_3033/xsxk_Xbk/xschXbkxkCz',
        'xkid=$xkid',
      );
      final result = unwrapCampusCommand(
        _decodeAndParseJson(response),
        what: '退课',
      );

      return WithdrawResult(
        success: true,
        message: campusString(result['msg']),
      );
    });
  }

  // -- Private helpers -------------------------------------------------------

  /// POST a form-encoded body and refresh the clock offset from the response.
  ///
  /// Every course-selection endpoint shares this shape, so the content type and
  /// the offset bookkeeping live here rather than at each of the six call
  /// sites.
  Future<Response<List<int>>> _postForm(String path, String body) async {
    final response = await _client.dio.post<List<int>>(
      path,
      data: body,
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );
    _updateClockOffset(response);
    return response;
  }

  /// Fetch student identity from the current course-selection session.
  ///
  /// Used by the cookie-only login path, where the portal home page was never
  /// fetched. Batch rows carry `xsid`; a selection record additionally carries
  /// the student's name.
  Future<StudentProfile> _fetchProfile() async {
    final response = await _postForm('/njs_3033/xsxk/getStudentXkList', '');
    // Throws sessionExpired on a rejected cookie, which is what makes this a
    // usable liveness probe for AccountsNotifier.ensureAdapter.
    final rows = unwrapCampusRows(
      _decodeAndParseJson(response),
      what: '校验登录状态',
    );

    final studentNo = rows
        .map((r) => campusString(r['xsid']))
        .firstWhere((v) => v != null, orElse: () => null);

    if (studentNo == null) {
      // A valid session with zero batches has no xsid to report. The cookie is
      // good, but this client cannot name the account — surfacing that is
      // better than inventing a placeholder identity.
      throw const CampusException(
        message: '登录状态有效，但该账号当前没有任何选课批次，无法读取学生信息',
        type: CampusExceptionType.unknownResponse,
      );
    }

    final studentName = await _fetchStudentName(rows: rows);
    return StudentProfile(
      studentNo: studentNo,
      studentName: studentName ?? studentNo,
    );
  }

  /// Best-effort lookup of the student's display name.
  ///
  /// Returns null rather than throwing: the name is display-only, and no login
  /// should fail because a cosmetic field was unavailable.
  Future<String?> _fetchStudentName({List<Map<String, dynamic>>? rows}) async {
    try {
      final batches = rows ?? const <Map<String, dynamic>>[];
      final xkid = batches
          .map((r) => campusString(r['xkid']))
          .firstWhere((v) => v != null, orElse: () => null);
      if (xkid == null) return null;

      final response = await _postForm(
        '/njs_3033/xsxk_Xbk/getStudentXkJlList',
        'xkid=$xkid',
      );
      final records = unwrapCampusRows(
        _decodeAndParseJson(response),
        what: '读取学生信息',
      );
      return records
          .map((r) => campusString(r['xm']))
          .firstWhere((v) => v != null, orElse: () => null);
    } on Exception {
      return null;
    }
  }

  /// Decode a raw byte response to a string, handling GBK.
  String _decodeResponse(Response<List<int>> response) {
    final data = response.data;
    if (data == null) return '';
    return decodeGbk(Uint8List.fromList(data));
  }

  /// Decode raw bytes and parse as JSON.
  Map<String, dynamic> _decodeAndParseJson(Response<List<int>> response) {
    final text = _decodeResponse(response);
    if (text.isEmpty) {
      throw const CampusException(
        message: '服务器返回空响应',
        type: CampusExceptionType.unknownResponse,
      );
    }
    try {
      final parsed = json.decode(text);
      if (parsed is Map<String, dynamic>) return parsed;
      throw const CampusException(
        message: '响应格式错误',
        type: CampusExceptionType.unknownResponse,
      );
    } on FormatException {
      throw const CampusException(
        message: '响应不是有效的JSON',
        type: CampusExceptionType.unknownResponse,
      );
    }
  }

  /// Update campus clock offset from response Date header.
  void _updateClockOffset(Response<dynamic> response) {
    final dateHeader = response.headers.value('date');
    if (dateHeader != null) {
      final serverDate = HttpDate.parse(dateHeader);
      final localDate = DateTime.now().toUtc();
      _campusClockOffsetMs = serverDate.difference(localDate).inMilliseconds;
      _client.lastResponseDate = serverDate;
    }
  }
}

/// HTTP Date parsing helper.
class HttpDate {
  const HttpDate._();

  /// Parse an HTTP Date header value (RFC 7231).
  static DateTime parse(String dateStr) {
    // HTTP dates are typically in the format:
    // "Mon, 21 Jul 2026 05:00:00 GMT"
    try {
      return _parseRfc1123(dateStr);
    } catch (_) {
      // Fallback: try general parsing.
      return DateTime.tryParse(dateStr)?.toUtc() ?? DateTime.now().toUtc();
    }
  }

  static DateTime _parseRfc1123(String s) {
    // "Mon, 21 Jul 2026 05:00:00 GMT"
    final months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final parts = s.replaceAll(',', '').split(RegExp(r'\s+'));
    // parts: [Mon, 21, Jul, 2026, 05:00:00, GMT]
    final day = int.parse(parts[1]);
    final month = months[parts[2]] ?? 1;
    final year = int.parse(parts[3]);
    final timeParts = parts[4].split(':');
    return DateTime.utc(
      year,
      month,
      day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
      int.parse(timeParts[2]),
    );
  }
}

/// Simple per-account serial request queue.
///
/// Ensures that only one campus request runs at a time per account (§7.4).
///
/// Uses a promise chain so concurrent callers all enqueue behind the current
/// tail rather than racing on [_last] after the previous task completes.
class _RequestQueue {
  Future<void> _last = Future.value();

  Future<T> add<T>(Future<T> Function() task) {
    // Chain onto the current tail. Each new caller captures the tail at the
    // moment of enqueue and waits for it before running its own task.
    final next = _last.then<T>((_) => task());
    // Update the tail, swallowing errors so a failed task doesn't break
    // subsequent callers waiting on the new tail.
    _last = next.then<void>((_) {}).catchError((_) {});
    return next;
  }
}
